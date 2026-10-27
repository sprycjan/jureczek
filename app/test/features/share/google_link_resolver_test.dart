import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jureczek/features/share/data/google_link_resolver.dart';

void main() {
  test('zwraca Location z przekierowania, bez podążania za nim', () async {
    late http.BaseRequest sent;
    final resolver = GoogleLinkResolver(
      MockClient((request) async {
        sent = request;
        return http.Response(
          '',
          302,
          headers: {'location': 'https://www.google.com/maps/place/X'},
        );
      }),
    );

    expect(
      await resolver.resolve('https://maps.app.goo.gl/abc'),
      'https://www.google.com/maps/place/X',
    );
    expect(sent.followRedirects, isFalse);
  });

  test('bez przekierowania rzuca GoogleLinkException', () {
    final resolver = GoogleLinkResolver(
      MockClient((_) async => http.Response('not found', 404)),
    );

    expect(
      resolver.resolve('https://maps.app.goo.gl/abc'),
      throwsA(isA<GoogleLinkException>()),
    );
  });

  test('błąd sieci zamienia na GoogleLinkException', () {
    final resolver = GoogleLinkResolver(
      MockClient((_) async => throw http.ClientException('offline')),
    );

    expect(
      resolver.resolve('https://maps.app.goo.gl/abc'),
      throwsA(
        isA<GoogleLinkException>().having(
          (e) => e.message,
          'message',
          'Błąd sieci: offline',
        ),
      ),
    );
  });
}
