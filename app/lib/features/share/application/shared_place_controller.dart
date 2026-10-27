import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../map/data/place_search_client.dart';
import '../../map/domain/duplicate_pin.dart';
import '../../map/domain/place_suggestion.dart';
import '../data/geocoding_client.dart';
import '../data/google_link_resolver.dart';
import '../data/share_channel.dart';
import '../domain/shared_place.dart';

sealed class SharedPlaceState {
  const SharedPlaceState();
}

class SharedPlaceIdle extends SharedPlaceState {
  const SharedPlaceIdle();
}

/// Rozwijamy link i szukamy współrzędnych.
class SharedPlaceLoading extends SharedPlaceState {
  const SharedPlaceLoading();
}

class SharedPlaceReady extends SharedPlaceState {
  const SharedPlaceReady(this.place);

  final PlaceResult place;
}

/// Udostępniony tekst nie zawiera miejsca (np. zwykły link ze strony).
class SharedPlaceNotAPlace extends SharedPlaceState {
  const SharedPlaceNotAPlace();
}

/// Brak sieci, przekroczony czas albo nie udało się ustalić położenia.
class SharedPlaceFailed extends SharedPlaceState {
  const SharedPlaceFailed();
}

/// Położenia nie da się ustalić bez zgadywania – miejsce trzeba wybrać
/// w wyszukiwarce po nazwie.
class SharedPlaceNeedsSearch extends SharedPlaceState {
  const SharedPlaceNeedsSearch(this.name);

  final String name;
}

class _NotAPlace implements Exception {
  const _NotAPlace();
}

class _NeedsSearch implements Exception {
  const _NeedsSearch(this.name);

  final String name;
}

/// Zamienia udostępnienie (np. z Google Maps) na [PlaceResult]. Współrzędne
/// bierze z linku, a gdy ich tam nie ma (POI udostępnione z aplikacji Google Maps),
/// wyznacza je przybliżenie przez Mapbox: adres → POI po nazwie w okolicy → miejscowość.
/// Środka kraju czy regionu nie podajemy jako położenia – wtedy [SharedPlaceNeedsSearch].
class SharedPlaceController extends Notifier<SharedPlaceState> {
  static const timeout = Duration(seconds: 10);

  /// POI znalezione po nazwie dalej niż tyle od miejscowości z adresu to inne miejsce.
  static const maxPoiDistanceMeters = 30000.0;

  /// Punkt z krótkiego Plus Code tak blisko POI o tej samej nazwie potwierdza
  /// odniesienie – przypadkiem (złe odniesienie) zdarza się to w ~0,1% przypadków.
  static const maxPlusCodePoiDistanceMeters = 1000.0;

  /// Typy z Geocoding v6 zbyt ogólne, by ich środek był położeniem miejsca
  /// (np. „Miradouro dos Balcões, Portugalia” – środek kraju jest 900 km od Madery).
  static const coarseFeatureTypes = {'country', 'region', 'district'};

  /// Obszary, których środek też nie jest położeniem: zamiast niego wyszukiwarka
  /// (np. „Park Jaśkowej Doliny, Gdańsk” – środek miasta to ul. Piwna).
  static const noFallbackFeatureTypes = {...coarseFeatureTypes, 'place'};

  static const _uuid = Uuid();

  /// Numer bieżącego udostępnienia; spóźnione wyniki starszych są odrzucane.
  int _request = 0;

  @override
  SharedPlaceState build() {
    final channel = ref.watch(shareChannelProvider);
    final subscription = channel.shares.listen(handle);
    ref.onDispose(subscription.cancel);
    unawaited(_handleInitial(channel));
    return const SharedPlaceIdle();
  }

  Future<void> _handleInitial(ShareChannel channel) async {
    try {
      final share = await channel.initialShare();
      if (share != null) await handle(share);
    } catch (e) {
      debugPrint('Odczyt udostępnienia nie powiódł się: $e');
    }
  }

  Future<void> handle(SharedText share) async {
    final request = ++_request;
    state = const SharedPlaceLoading();

    SharedPlaceState next;
    try {
      next = SharedPlaceReady(await _locate(share).timeout(timeout));
    } on _NotAPlace {
      next = const SharedPlaceNotAPlace();
    } on _NeedsSearch catch (e) {
      next = SharedPlaceNeedsSearch(e.name);
    } catch (e) {
      // Same komunikaty wyjątków – bez adresów z tokenem.
      debugPrint('Odczyt udostępnionego miejsca nie powiódł się: $e');
      next = const SharedPlaceFailed();
    }
    if (request == _request) state = next;
  }

  /// Przerywa bieżące udostępnienie; jego wynik zostanie pominięty.
  void cancel() {
    _request++;
    state = const SharedPlaceIdle();
  }

  Future<PlaceResult> _locate(SharedText share) async {
    final link = findGoogleMapsLink(share.text);
    final SharedPlaceInfo info;
    if (link != null) {
      final url = isShortGoogleLink(link)
          ? await ref.read(googleLinkResolverProvider).resolve(link)
          : link;
      // Do sprawdzania, jakie linki przysyła Google; w URL-u Google nie ma tokenu.
      debugPrint('Udostępniony link Google: $url');
      info = parseGoogleMapsUrl(url, subject: share.subject);
    } else {
      final parsed = parseCoordinatesText(share.text);
      if (parsed == null) throw const _NotAPlace();
      info = SharedPlaceInfo(
        point: parsed.point,
        name: parsed.name ?? _nonEmpty(share.subject),
      );
    }

    final linkPoint = info.point;
    if (linkPoint != null) return _exact(linkPoint, info, link);

    final located = await _locateWithoutPoint(info);
    if (located.exact) return _exact(located.point, info, link);
    return PlaceResult(
      name: info.name,
      address: info.address,
      lat: located.point.lat,
      lng: located.point.lng,
      sourceUrl: link,
      approximate: true,
    );
  }

  /// Brakujący adres (i nazwę) uzupełnia reverse geocoding; jego błąd nie blokuje wyniku.
  Future<PlaceResult> _exact(
    LatLng point,
    SharedPlaceInfo info,
    String? link,
  ) async {
    var name = info.name;
    var address = info.address;
    if (address == null) {
      try {
        final found = await ref.read(geocodingClientProvider).reverse(point);
        address = found?.fullAddress;
        name ??= found?.name;
      } on GeocodingException catch (e) {
        debugPrint('Reverse geocoding nie powiódł się: ${e.message}');
      }
    }
    return PlaceResult(
      name: name,
      address: address,
      lat: point.lat,
      lng: point.lng,
      sourceUrl: link,
    );
  }

  /// Położenie, gdy link nie ma współrzędnych: z krótkiego Plus Code (dokładne,
  /// jeśli potwierdza je POI o tej nazwie), a bez niego przybliżone z adresu i POI.
  /// Rzuca [_NeedsSearch], gdy jedyne, co mamy, to nazwa albo obszar zbyt ogólny.
  Future<({LatLng point, bool exact})> _locateWithoutPoint(
    SharedPlaceInfo info,
  ) async {
    final address = info.address;
    final name = info.name;
    final plusCode = info.plusCode;

    final area = address == null
        ? null
        : await ref.read(geocodingClientProvider).forward(address);
    final isAddress = area?.featureType == 'address';
    final fineArea =
        area != null && !coarseFeatureTypes.contains(area.featureType)
        ? area
        : null;

    // Adres z numerem wystarcza, chyba że Plus Code może dać dokładny punkt.
    // Ogólny obszar (albo brak adresu): szukamy w całym kraju, bez `proximity`,
    // bo jego środek może być daleko od miejsca.
    final poi = name == null || (isAddress && plusCode == null)
        ? null
        : await _findPoi(
            name,
            near: fineArea?.point,
            country: fineArea == null ? area?.countryCode : null,
          );

    if (plusCode != null) {
      if (poi != null) {
        final point = plusCode.recoverNearest(poi);
        if (distanceMeters(point, poi) <= maxPlusCodePoiDistanceMeters) {
          return (point: point, exact: true);
        }
      }
      if (fineArea != null) {
        final point = plusCode.recoverNearest(fineArea.point);
        if (distanceMeters(point, fineArea.point) <= maxPoiDistanceMeters) {
          return (point: point, exact: false);
        }
      }
    }

    if (fineArea != null) {
      if (isAddress) return (point: fineArea.point, exact: false);
      final nearby =
          poi != null &&
          distanceMeters(poi, fineArea.point) <= maxPoiDistanceMeters;
      if (nearby) return (point: poi, exact: false);
      if (!noFallbackFeatureTypes.contains(fineArea.featureType)) {
        return (point: fineArea.point, exact: false);
      }
      if (name == null) throw StateError('Nie udało się ustalić położenia');
      throw _NeedsSearch(name);
    }

    if (name == null) throw StateError('Nie udało się ustalić położenia');
    final bbox = area?.bbox;
    if (poi == null || (bbox != null && !bbox.contains(poi))) {
      throw _NeedsSearch(name);
    }
    return (point: poi, exact: false);
  }

  /// Pierwsze POI o tej nazwie (w okolicy [near] albo w kraju [country]):
  /// jedna sesja Search Box (`/suggest` + `/retrieve`).
  Future<LatLng?> _findPoi(String name, {LatLng? near, String? country}) async {
    final search = ref.read(placeSearchClientProvider);
    final sessionToken = _uuid.v4();
    final suggestions = await search.suggest(
      name,
      sessionToken: sessionToken,
      proximity: near,
      country: country,
    );
    final poi = suggestions.where((s) => s.featureType == 'poi').firstOrNull;
    if (poi == null) return null;

    final result = await search.retrieve(poi, sessionToken: sessionToken);
    return (lat: result.lat, lng: result.lng);
  }

  static String? _nonEmpty(String? text) {
    final trimmed = text?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

final sharedPlaceControllerProvider =
    NotifierProvider<SharedPlaceController, SharedPlaceState>(
      SharedPlaceController.new,
    );
