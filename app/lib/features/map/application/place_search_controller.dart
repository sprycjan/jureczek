import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/place_search_client.dart';
import '../domain/place_suggestion.dart';

sealed class PlaceSearchState {
  const PlaceSearchState();
}

/// Za krótkie zapytanie – nic nie pokazujemy.
class PlaceSearchIdle extends PlaceSearchState {
  const PlaceSearchIdle();
}

/// [previous] to poprzednie podpowiedzi, pokazywane do czasu nowych, żeby lista nie mrugała.
class PlaceSearchLoading extends PlaceSearchState {
  const PlaceSearchLoading([this.previous = const []]);

  final List<PlaceSuggestion> previous;
}

class PlaceSearchSuggestions extends PlaceSearchState {
  const PlaceSearchSuggestions(this.suggestions);

  final List<PlaceSuggestion> suggestions;
}

class PlaceSearchEmpty extends PlaceSearchState {
  const PlaceSearchEmpty();
}

class PlaceSearchError extends PlaceSearchState {
  const PlaceSearchError();
}

/// Podpowiedzi w trakcie pisania: od [minQueryLength] znaków, po [debounce] przerwy.
class PlaceSearchController extends Notifier<PlaceSearchState> {
  static const minQueryLength = 3;
  static const debounce = Duration(milliseconds: 300);
  static const _uuid = Uuid();

  Timer? _timer;
  String _query = '';
  String _sessionToken = _uuid.v4();

  @visibleForTesting
  String get sessionToken => _sessionToken;

  @override
  PlaceSearchState build() {
    ref.onDispose(() => _timer?.cancel());
    return const PlaceSearchIdle();
  }

  /// [proximity] jest pytane dopiero przy wysyłce, żeby dać aktualny środek mapy.
  void onQueryChanged(String text, {Future<LatLng?> Function()? proximity}) {
    final query = text.trim();
    if (query == _query) return;
    _query = query;
    _timer?.cancel();

    if (query.length < minQueryLength) {
      state = const PlaceSearchIdle();
      return;
    }
    _timer = Timer(debounce, () => _suggest(query, proximity));
  }

  Future<void> _suggest(
    String query,
    Future<LatLng?> Function()? proximity,
  ) async {
    state = PlaceSearchLoading(switch (state) {
      PlaceSearchSuggestions(:final suggestions) => suggestions,
      PlaceSearchLoading(:final previous) => previous,
      _ => const [],
    });
    try {
      final suggestions = await ref
          .read(placeSearchClientProvider)
          .suggest(
            query,
            sessionToken: _sessionToken,
            proximity: await proximity?.call(),
          );
      // Odpowiedź na zapytanie, które użytkownik już zmienił, wyrzucamy.
      if (query != _query) return;
      state = suggestions.isEmpty
          ? const PlaceSearchEmpty()
          : PlaceSearchSuggestions(suggestions);
    } catch (e) {
      debugPrint('Wyszukiwanie miejsc nie powiodło się: $e');
      if (query == _query) state = const PlaceSearchError();
    }
  }

  /// Pobiera współrzędne wybranej podpowiedzi i zamyka sesję. Przy błędzie `null`.
  Future<PlaceResult?> select(PlaceSuggestion suggestion) async {
    _timer?.cancel();
    try {
      final result = await ref
          .read(placeSearchClientProvider)
          .retrieve(suggestion, sessionToken: _sessionToken);
      reset();
      return result;
    } catch (e) {
      debugPrint('Pobranie miejsca nie powiodło się: $e');
      state = const PlaceSearchError();
      return null;
    }
  }

  /// Czyści zapytanie i zaczyna nową sesję Mapbox.
  void reset() {
    _timer?.cancel();
    _query = '';
    _sessionToken = _uuid.v4();
    state = const PlaceSearchIdle();
  }
}

final placeSearchControllerProvider =
    NotifierProvider<PlaceSearchController, PlaceSearchState>(
      PlaceSearchController.new,
    );
