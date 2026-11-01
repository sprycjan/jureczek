import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/home/domain/landscape.dart';

void main() {
  Landscape at(int hour, [int minute = 0]) =>
      Landscape.at(DateTime(2026, 11, 1, hour, minute));

  test('pora dnia wg godziny: świt 5–8, dzień 8–18, zachód 18–21, noc', () {
    expect(at(4, 59), Landscape.night);
    expect(at(5), Landscape.dawn);
    expect(at(7, 59), Landscape.dawn);
    expect(at(8), Landscape.day);
    expect(at(17, 59), Landscape.day);
    expect(at(18), Landscape.sunset);
    expect(at(20, 59), Landscape.sunset);
    expect(at(21), Landscape.night);
    expect(at(0), Landscape.night);
  });
}
