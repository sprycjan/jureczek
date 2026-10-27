import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../map/domain/place_suggestion.dart';

class GeocodingException implements Exception {
  const GeocodingException(this.message);

  final String message;

  @override
  String toString() => 'GeocodingException: $message';
}

/// Prostokąt obszaru: lng/lat jego południowo-zachodniego i północno-wschodniego rogu.
typedef BoundingBox = ({
  double minLng,
  double minLat,
  double maxLng,
  double maxLat,
});

extension BoundingBoxContains on BoundingBox {
  bool contains(LatLng point) =>
      point.lng >= minLng &&
      point.lng <= maxLng &&
      point.lat >= minLat &&
      point.lat <= maxLat;
}

/// Wynik geokodowania; [featureType] to np. `address`, `street`, `place`, `country`.
@immutable
class GeocodedPlace {
  const GeocodedPlace({
    required this.point,
    required this.featureType,
    this.name,
    this.fullAddress,
    this.countryCode,
    this.bbox,
  });

  final LatLng point;
  final String featureType;
  final String? name;
  final String? fullAddress;

  /// Kod ISO kraju małymi literami (`pt`), jak w parametrze `country` Search Box.
  final String? countryCode;

  /// Zasięg obszaru; Mapbox podaje go m.in. dla krajów i regionów.
  final BoundingBox? bbox;
}

/// Mapbox Geocoding API v6 (adresy i miejscowości, bez POI). Darmowe 100 tys.
/// zapytań miesięcznie; wyniki są „tymczasowe” (`permanent=false`).
class GeocodingClient {
  GeocodingClient(this._http, this._accessToken);

  final http.Client _http;
  final String _accessToken;

  static const _host = 'api.mapbox.com';
  static const _path = '/search/geocode/v6';

  /// Najlepsze trafienie dla tekstu albo `null`.
  Future<GeocodedPlace?> forward(String query) async {
    final json = await _get('$_path/forward', {
      'q': query,
      'language': 'pl',
      'limit': '1',
    });
    return _first(json);
  }

  /// Adres w danym punkcie albo `null`.
  Future<GeocodedPlace?> reverse(LatLng point) async {
    final json = await _get('$_path/reverse', {
      'longitude': '${point.lng}',
      'latitude': '${point.lat}',
      'language': 'pl',
      'types': 'address',
    });
    return _first(json);
  }

  static GeocodedPlace? _first(Map<String, dynamic> json) {
    final features = (json['features'] as List?) ?? const [];
    if (features.isEmpty) return null;
    final feature = features.first as Map<String, dynamic>;
    final coordinates = (feature['geometry'] as Map)['coordinates'] as List;
    final properties = feature['properties'] as Map<String, dynamic>;
    final country = (properties['context'] as Map?)?['country'] as Map?;
    final bbox = properties['bbox'] as List?;
    return GeocodedPlace(
      point: (
        lat: (coordinates[1] as num).toDouble(),
        lng: (coordinates[0] as num).toDouble(),
      ),
      featureType: properties['feature_type'] as String? ?? '',
      name: properties['name'] as String?,
      fullAddress: properties['full_address'] as String?,
      countryCode: (country?['country_code'] as String?)?.toLowerCase(),
      bbox: bbox == null || bbox.length != 4
          ? null
          : (
              minLng: (bbox[0] as num).toDouble(),
              minLat: (bbox[1] as num).toDouble(),
              maxLng: (bbox[2] as num).toDouble(),
              maxLat: (bbox[3] as num).toDouble(),
            ),
    );
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
      throw GeocodingException('Błąd sieci: ${e.message}');
    }
    if (response.statusCode != 200) {
      throw GeocodingException('HTTP ${response.statusCode}');
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw GeocodingException('Niepoprawna odpowiedź: $e');
    }
  }
}

final geocodingClientProvider = Provider<GeocodingClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GeocodingClient(client, mapboxAccessToken);
});
