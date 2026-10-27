import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/duplicate_pin.dart';
import 'package:jureczek/features/map/domain/place_suggestion.dart';
import 'package:jureczek/features/share/domain/plus_code.dart';

void main() {
  // Miradouro dos Balcões: Google podaje `!3d32.7415585!4d-16.8902812`
  // i Plus Code `P4R5+JV` (pełny: 8C45P4R5+JV).
  const google = (lat: 32.7415585, lng: -16.8902812);

  Matcher closeTo(LatLng expected, {double meters = 10}) => predicate<LatLng>(
    (p) => distanceMeters(p, expected) <= meters,
    'w odległości $meters m od $expected',
  );

  group('tryParse', () {
    test('rozpoznaje krótkie i pełne kody, bez względu na wielkość liter', () {
      expect(PlusCode.tryParse('P4R5+JV')?.code, 'P4R5+JV');
      expect(PlusCode.tryParse('8c45p4r5+jv')?.isFull, isTrue);
      expect(PlusCode.tryParse('P4R5+JV')?.isFull, isFalse);
    });

    test('odrzuca tekst, który nie jest kodem', () {
      expect(PlusCode.tryParse('Miradouro'), isNull);
      expect(PlusCode.tryParse('P4R+JV'), isNull);
      expect(PlusCode.tryParse('AAAA+JV'), isNull);
      expect(PlusCode.tryParse('C++'), isNull);
    });
  });

  test('pełny kod dekoduje się do punktu Google', () {
    expect(PlusCode.tryParse('8C45P4R5+JV')!.decode(), closeTo(google));
  });

  group('recoverNearest', () {
    final code = PlusCode.tryParse('P4R5+JV')!;

    test('odniesienie w pobliżu daje punkt Google', () {
      // Ulica „Caminho do Ribeiro Frio” z geokodowania, ~12 km dalej.
      expect(
        code.recoverNearest((lat: 32.70346, lng: -17.020455)),
        closeTo(google),
      );
    });

    test('odniesienie po drugiej stronie granicy komórki 1°', () {
      expect(code.recoverNearest((lat: 33.2, lng: -16.5)), closeTo(google));
    });

    test('złe odniesienie daje punkt koło niego, nie miejsce', () {
      final ribeirao = (lat: 41.355923, lng: -8.556117);
      final point = code.recoverNearest(ribeirao);

      expect(point, closeTo((lat: 41.7415625, lng: -8.8903125)));
      expect(distanceMeters(point, ribeirao), lessThan(80000));
    });
  });
}
