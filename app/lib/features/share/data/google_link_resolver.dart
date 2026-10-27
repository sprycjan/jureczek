import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class GoogleLinkException implements Exception {
  const GoogleLinkException(this.message);

  final String message;

  @override
  String toString() => 'GoogleLinkException: $message';
}

/// Rozwija krótki link `maps.app.goo.gl` do pełnego adresu Google Maps.
/// Czyta tylko nagłówek `Location` pierwszego przekierowania – bez API i bez klucza,
/// a dalej nie idziemy, bo w UE kolejny skok to strona zgody.
class GoogleLinkResolver {
  GoogleLinkResolver(this._http);

  final http.Client _http;

  Future<String> resolve(String shortUrl) async {
    final request = http.Request('GET', Uri.parse(shortUrl))
      ..followRedirects = false;
    final http.StreamedResponse response;
    try {
      response = await _http.send(request);
    } on http.ClientException catch (e) {
      throw GoogleLinkException('Błąd sieci: ${e.message}');
    }
    // Treść nie jest potrzebna; odczyt zwalnia połączenie.
    await response.stream.drain<void>();
    final location = response.headers['location'];
    if (response.statusCode < 300 ||
        response.statusCode >= 400 ||
        location == null) {
      throw GoogleLinkException(
        'Brak przekierowania (HTTP ${response.statusCode})',
      );
    }
    return location;
  }
}

final googleLinkResolverProvider = Provider<GoogleLinkResolver>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GoogleLinkResolver(client);
});
