import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Wynik prośby o położenie użytkownika (v14).
sealed class UserLocationResult {
  const UserLocationResult();
}

class UserLocationFound extends UserLocationResult {
  const UserLocationFound({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

/// Lokalizacja wyłączona w telefonie.
class UserLocationServiceOff extends UserLocationResult {
  const UserLocationServiceOff();
}

/// Odmowa – przy następnym tapnięciu system znowu zapyta.
class UserLocationDenied extends UserLocationResult {
  const UserLocationDenied();
}

/// Odmowa na stałe („Nie pytaj ponownie”) – zgodę da się włączyć tylko w ustawieniach.
class UserLocationDeniedForever extends UserLocationResult {
  const UserLocationDeniedForever();
}

/// Zgoda jest, ale telefon nie podał pozycji (np. brak sygnału, przekroczony czas).
class UserLocationUnavailable extends UserLocationResult {
  const UserLocationUnavailable();
}

/// Cienka warstwa nad `geolocator`, podmieniana w testach.
class UserLocationService {
  const UserLocationService({DateTime Function() now = DateTime.now})
    : _now = now;

  final DateTime Function() _now;

  /// Czy aplikacja ma już zgodę – bez pytania użytkownika.
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Sprawdza usługę i zgodę (pyta, gdy trzeba), potem podaje pozycję.
  /// Świeża ostatnia znana pozycja od razu, inaczej bieżąca (do 15 s).
  Future<UserLocationResult> locate() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const UserLocationServiceOff();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        return const UserLocationDenied();
      case LocationPermission.deniedForever:
        return const UserLocationDeniedForever();
      case LocationPermission.whileInUse ||
          LocationPermission.always ||
          LocationPermission.unableToDetermine:
    }
    final last = await _lastKnown();
    if (last != null && _now().difference(last.timestamp) <= freshFor) {
      return _found(last);
    }
    try {
      return _found(
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 15),
          ),
        ),
      );
    } catch (e) {
      // Np. TimeoutException (brak sygnału) – lepsza stara pozycja niż żadna.
      return last == null ? const UserLocationUnavailable() : _found(last);
    }
  }

  /// Ostatnia znana pozycja młodsza niż to wystarcza – bez czekania na GPS.
  static const freshFor = Duration(minutes: 2);

  Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  static UserLocationFound _found(Position p) =>
      UserLocationFound(lat: p.latitude, lng: p.longitude);

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

final userLocationServiceProvider = Provider<UserLocationService>(
  (ref) => const UserLocationService(),
);
