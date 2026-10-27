import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/place_suggestion.dart';

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);

  final String message;

  @override
  String toString() => 'PlaceSearchException: $message';
}

/// Mapbox Search Box API: `/suggest` podpowiada, `/retrieve` daje współrzędne.
/// Oba wywołania z jednym `sessionToken` to jedna rozliczana sesja.
class PlaceSearchClient {
  PlaceSearchClient(this._http, this._accessToken);

  final http.Client _http;
  final String _accessToken;

  static const _host = 'api.mapbox.com';
  static const _path = '/search/searchbox/v1';
  static const suggestionLimit = 6;

  /// [country] (kod ISO, np. `pt`) zawęża wyniki do jednego kraju.
  Future<List<PlaceSuggestion>> suggest(
    String query, {
    required String sessionToken,
    LatLng? proximity,
    String? country,
  }) async {
    final json = await _get('$_path/suggest', {
      'q': query,
      'session_token': sessionToken,
      'language': 'pl',
      'limit': '$suggestionLimit',
      if (proximity != null) 'proximity': '${proximity.lng},${proximity.lat}',
      'country': ?country,
    });
    final suggestions = (json['suggestions'] as List?) ?? const [];
    return [
      for (final s in suggestions.cast<Map<String, dynamic>>())
        PlaceSuggestion(
          mapboxId: s['mapbox_id'] as String,
          name: s['name'] as String,
          address: _address(s),
          featureType: s['feature_type'] as String?,
        ),
    ];
  }

  Future<PlaceResult> retrieve(
    PlaceSuggestion suggestion, {
    required String sessionToken,
  }) async {
    final json = await _get('$_path/retrieve/${suggestion.mapboxId}', {
      'session_token': sessionToken,
    });
    final features = (json['features'] as List?) ?? const [];
    if (features.isEmpty) {
      throw const PlaceSearchException('Brak współrzędnych w odpowiedzi');
    }
    final feature = features.first as Map<String, dynamic>;
    final coordinates = (feature['geometry'] as Map)['coordinates'] as List;
    return PlaceResult(
      name: suggestion.name,
      address: suggestion.address,
      lng: (coordinates[0] as num).toDouble(),
      lat: (coordinates[1] as num).toDouble(),
    );
  }

  static String? _address(Map<String, dynamic> suggestion) {
    final address =
        suggestion['full_address'] as String? ??
        suggestion['place_formatted'] as String?;
    return (address == null || address.isEmpty) ? null : address;
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    final uri = Uri.https(_host, path, {
      ...params,
      'access_token': _accessToken,
    });
    final http.Response response;
    try {
      response = await _http.get(uri);
    } on http.ClientException catch (e) {
      // Bez `e.uri` – w adresie jest token.
      throw PlaceSearchException('Błąd sieci: ${e.message}');
    }
    if (response.statusCode != 200) {
      throw PlaceSearchException('HTTP ${response.statusCode}');
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw PlaceSearchException('Niepoprawna odpowiedź: $e');
    }
  }
}

final placeSearchClientProvider = Provider<PlaceSearchClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return PlaceSearchClient(client, mapboxAccessToken);
});
