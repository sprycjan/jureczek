import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/pin_sort_key.dart';

void main() {
  double key(double lat, {bool selected = false, bool starred = false}) =>
      pinSortKey(lat: lat, selected: selected, starred: starred);

  test('od góry: zaznaczona, z gwiazdką, pozostałe – na każdej szerokości', () {
    // Najgorszy przypadek: wyższa grupa na dalekiej północy, niższa na południu.
    expect(key(90, selected: true), greaterThan(key(-90, starred: true)));
    expect(key(90, starred: true), greaterThan(key(-90)));
  });

  test('zaznaczona z gwiazdką jest nad zaznaczoną bez niej', () {
    expect(
      key(90, selected: true, starred: true),
      greaterThan(key(-90, selected: true)),
    );
  });

  test('w tej samej grupie południowa przykrywa północną', () {
    expect(key(50), greaterThan(key(51)));
    expect(key(50, starred: true), greaterThan(key(51, starred: true)));
  });
}
