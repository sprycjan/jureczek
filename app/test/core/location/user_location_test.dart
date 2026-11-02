import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:jureczek/core/location/user_location.dart';

/// Udawany telefon: usługa, zgoda przed i po pytaniu, pozycje.
class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.afterRequest = LocationPermission.whileInUse,
    this.lastKnown,
    this.current,
  });

  bool serviceEnabled;
  LocationPermission permission;
  LocationPermission afterRequest;
  Position? lastKnown;
  Position? current;
  int requests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return permission = afterRequest;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => lastKnown;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    final position = current;
    if (position == null) throw TimeoutException('brak sygnału');
    return position;
  }
}

Position _at(double lat, double lng, {DateTime? at}) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: at ?? DateTime(2026, 11, 2),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _FakeGeolocator fake;
  // „Teraz” w testach: tuż po pozycjach z [_at].
  final service = UserLocationService(now: () => DateTime(2026, 11, 2, 0, 1));

  void install(_FakeGeolocator f) => GeolocatorPlatform.instance = fake = f;

  test('wyłączona lokalizacja – nie pyta o zgodę', () async {
    install(_FakeGeolocator(serviceEnabled: false));

    expect(await service.locate(), isA<UserLocationServiceOff>());
    expect(fake.requests, 0);
  });

  test('bez zgody pyta; odmowa i odmowa na stałe', () async {
    install(
      _FakeGeolocator(
        permission: LocationPermission.denied,
        afterRequest: LocationPermission.denied,
      ),
    );
    expect(await service.locate(), isA<UserLocationDenied>());
    expect(fake.requests, 1);

    install(
      _FakeGeolocator(
        permission: LocationPermission.denied,
        afterRequest: LocationPermission.deniedForever,
      ),
    );
    expect(await service.locate(), isA<UserLocationDeniedForever>());
  });

  test('odmowa na stałe – nie pyta ponownie', () async {
    install(_FakeGeolocator(permission: LocationPermission.deniedForever));

    expect(await service.locate(), isA<UserLocationDeniedForever>());
    expect(fake.requests, 0);
  });

  test('zgoda po pytaniu – świeża ostatnia znana pozycja', () async {
    install(
      _FakeGeolocator(
        permission: LocationPermission.denied,
        lastKnown: _at(50.06, 19.94),
        current: _at(0, 0),
      ),
    );

    final result = await service.locate();

    expect(result, isA<UserLocationFound>());
    result as UserLocationFound;
    expect((result.lat, result.lng), (50.06, 19.94));
  });

  test('bez ostatniej znanej – bieżąca; bez sygnału – niedostępna', () async {
    install(_FakeGeolocator(current: _at(52.23, 21.01)));
    final found = await service.locate() as UserLocationFound;
    expect((found.lat, found.lng), (52.23, 21.01));

    install(_FakeGeolocator());
    expect(await service.locate(), isA<UserLocationUnavailable>());
  });

  test('hasPermission nie pyta użytkownika', () async {
    install(_FakeGeolocator(permission: LocationPermission.denied));
    expect(await service.hasPermission(), isFalse);
    expect(fake.requests, 0);

    install(_FakeGeolocator(permission: LocationPermission.always));
    expect(await service.hasPermission(), isTrue);
  });

  test('stara ostatnia znana – bieżąca, a bez sygnału jednak stara', () async {
    final old = _at(54.35, 18.65, at: DateTime(2026, 11, 1));
    install(_FakeGeolocator(lastKnown: old, current: _at(50.06, 19.94)));
    final current = await service.locate() as UserLocationFound;
    expect((current.lat, current.lng), (50.06, 19.94));

    install(_FakeGeolocator(lastKnown: old));
    final stale = await service.locate() as UserLocationFound;
    expect((stale.lat, stale.lng), (54.35, 18.65));
  });
}
