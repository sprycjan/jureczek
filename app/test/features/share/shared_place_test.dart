import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/share/domain/shared_place.dart';

void main() {
  // Prawdziwe przekierowania krótkich linków z 2026-10-26 (skrócone parametry).
  const sharedPark =
      'https://www.google.com/maps/place/Park+Ja%C5%9Bkowej+Doliny,+Gda%C5%84sk/data=!4m2!3m1!1s0x46fd74ed87dd0b95:0xffed4c1b453641f7!18m1!1e1?utm_source=mstt_1&entry=gps';
  const sharedMall =
      'https://www.google.com/maps/place/Galeria+Metropolia,+Jana+Kili%C5%84skiego+4,+80-452+Gda%C5%84sk/data=!4m2!3m1!1s0x46fd74c07f48563b:0x41bdd278ada4490b!18m1!1e1?utm_source=mstt_1&entry=gps';
  const sharedDroppedPin =
      'https://www.google.com/maps/place/Klonowa+01,+80-264+Gda%C5%84sk/data=!4m6!3m5!1s0x46fd74ead27c1615:0x1f0110bd5645bfe2!7e2!8m2!3d54.3799662!4d18.6029747!18m1!1e1?utm_source=mstt_1&entry=gps';
  const copiedPark =
      'https://www.google.com/maps/place/Park+Ja%C5%9Bkowej+Doliny/@54.3741394,18.5814959,5604m/data=!3m1!1e3!4m6!3m5!1s0x46fd74ed87dd0b95:0xffed4c1b453641f7!8m2!3d54.3724635!4d18.5926056!16s%2Fg%2F11b6j702n_?entry=tts';
  const copiedDroppedPin =
      'https://www.google.com/maps/search/54.368639,+18.571369?entry=tts';
  // Prawdziwe przekierowanie udostępnienia z aplikacji z 2026-10-27 – POI bez adresu
  // dostaje Plus Code przed nazwą (skrócone parametry).
  const sharedBalcoes =
      'https://www.google.com/maps/place/P4R5%2BJV+Miradouro+dos+Balc%C3%B5es,+Ribeiro+Frio,+Portugalia/data=!4m2!3m1!1s0xc6067be7149a0a1:0xe1a2be98d1fa9c7d!18m1!1e1?utm_source=mstt_1&entry=gps';
  // Prawdziwe przekierowanie linku z „Udostępnij → Kopiuj” z 2026-10-27 (skrócone parametry).
  const copiedBalcoes =
      'https://www.google.com/maps/place/Miradouro+dos+Balc%C3%B5es/@32.7415585,-16.8928561,1011m/data=!3m2!1e3!4b1!4m6!3m5!1s0xc6067be7149a0a1:0xe1a2be98d1fa9c7d!8m2!3d32.7415585!4d-16.8902812!16s%2Fg%2F11jz6j_mkr?entry=tts';

  group('findGoogleMapsLink', () {
    test('znajduje krótki link w tekście', () {
      expect(
        findGoogleMapsLink(
          'Zobacz: https://maps.app.goo.gl/6cBNDs1EJi5shFTM9 !',
        ),
        'https://maps.app.goo.gl/6cBNDs1EJi5shFTM9',
      );
    });

    test('znajduje pełny link, a zwykły link pomija', () {
      expect(findGoogleMapsLink(copiedDroppedPin), copiedDroppedPin);
      expect(findGoogleMapsLink('https://example.com/maps/x'), isNull);
    });

    test('rozpoznaje krótkie linki', () {
      expect(isShortGoogleLink('https://maps.app.goo.gl/abc'), isTrue);
      expect(isShortGoogleLink(copiedPark), isFalse);
    });
  });

  group('parseGoogleMapsUrl', () {
    test('POI udostępnione z aplikacji: nazwa i adres, bez współrzędnych', () {
      final mall = parseGoogleMapsUrl(
        sharedMall,
        subject: 'Galeria Metropolia',
      );

      expect(mall.point, isNull);
      expect(mall.name, 'Galeria Metropolia');
      expect(mall.address, 'Jana Kilińskiego 4, 80-452 Gdańsk');

      final park = parseGoogleMapsUrl(
        sharedPark,
        subject: 'Park Jaśkowej Doliny',
      );
      expect(park.point, isNull);
      expect(park.address, 'Gdańsk');
    });

    test('POI z Plus Code: kod osobno, nazwa i adres bez niego', () {
      final place = parseGoogleMapsUrl(sharedBalcoes);

      expect(place.point, isNull);
      expect(place.plusCode?.code, 'P4R5+JV');
      expect(place.name, 'Miradouro dos Balcões');
      expect(place.address, 'Ribeiro Frio, Portugalia');

      final withSubject = parseGoogleMapsUrl(
        sharedBalcoes,
        subject: 'Miradouro dos Balcões',
      );
      expect(withSubject.address, 'Ribeiro Frio, Portugalia');
    });

    test('pełny Plus Code to od razu punkt', () {
      final place = parseGoogleMapsUrl(
        'https://www.google.com/maps/place/8C45P4R5%2BJV+Ribeiro+Frio/data=!4m2!3m1!1s0x1:0x2',
      );

      expect(place.point?.lat, closeTo(32.74156, 0.0001));
      expect(place.point?.lng, closeTo(-16.89031, 0.0001));
      expect(place.plusCode, isNull);
    });

    test('skopiowany link z Madery: dokładny punkt z !3d!4d', () {
      final place = parseGoogleMapsUrl(copiedBalcoes);

      expect(place.point, (lat: 32.7415585, lng: -16.8902812));
      expect(place.name, 'Miradouro dos Balcões');
    });

    test('upuszczona pinezka: współrzędne z !3d!4d, cały tekst jako adres', () {
      final pin = parseGoogleMapsUrl(sharedDroppedPin, subject: 'Klonowa 01');

      expect(pin.point, (lat: 54.3799662, lng: 18.6029747));
      expect(pin.name, 'Klonowa 01');
      expect(pin.address, 'Klonowa 01, 80-264 Gdańsk');
    });

    test('skopiowany link POI: !3d!4d zamiast pozycji kamery z @', () {
      final park = parseGoogleMapsUrl(copiedPark);

      expect(park.point, (lat: 54.3724635, lng: 18.5926056));
      expect(park.name, 'Park Jaśkowej Doliny');
      expect(park.address, isNull);
    });

    test('skopiowana pinezka: współrzędne z /search/', () {
      final pin = parseGoogleMapsUrl(copiedDroppedPin);

      expect(pin.point, (lat: 54.368639, lng: 18.571369));
      expect(pin.name, isNull);
    });

    test('współrzędne z parametru q', () {
      final pin = parseGoogleMapsUrl('https://maps.google.com/?q=50.06,19.94');

      expect(pin.point, (lat: 50.06, lng: 19.94));
    });

    test(
      'nazwa z subject różna od tekstu w linku: adresem jest cały tekst',
      () {
        final place = parseGoogleMapsUrl(sharedMall, subject: 'Metropolia');

        expect(place.name, 'Metropolia');
        expect(
          place.address,
          'Galeria Metropolia, Jana Kilińskiego 4, 80-452 Gdańsk',
        );
      },
    );
  });

  group('parseCoordinatesText', () {
    test('geo: z zapytaniem', () {
      final place = parseCoordinatesText(
        'geo:50.054,19.935?q=50.054,19.935(Wawel)',
      );

      expect(place?.point, (lat: 50.054, lng: 19.935));
      expect(place?.name, 'Wawel');
    });

    test('geo:0,0 to brak pozycji', () {
      expect(parseCoordinatesText('geo:0,0?q=Wawel')?.point, isNull);
    });

    test('surowe „lat, lng”', () {
      expect(parseCoordinatesText(' 54.35, 18.65 ')?.point, (
        lat: 54.35,
        lng: 18.65,
      ));
    });

    test('zwykły tekst i współrzędne spoza zakresu to nie miejsce', () {
      expect(parseCoordinatesText('Zobacz ten artykuł'), isNull);
      expect(parseCoordinatesText('95.0, 18.0'), isNull);
    });
  });
}
