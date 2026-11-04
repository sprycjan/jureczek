import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/pin_category_filter.dart';
import 'package:jureczek/features/map/domain/pin_kind.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';
import 'package:jureczek/features/places/domain/place_category.dart';
import 'package:jureczek/features/places/domain/place_type.dart';

PlacePin _pin(String id, PinKind kind) => PlacePin(
  id: id,
  lat: 50,
  lng: 20,
  createdAt: DateTime(2026),
  folderId: 'f',
  kind: kind,
);

void main() {
  const nature = PlaceCategory.nature;
  const gastronomy = PlaceCategory.gastronomy;

  test('domyślnie pokazuje wszystko i nie jest aktywny', () {
    const filter = PinCategoryFilter.all;
    expect(filter.isActive, isFalse);
    expect(filter.shows(null), isTrue);
    for (final category in PlaceCategory.values) {
      expect(filter.shows(category), isTrue);
    }
  });

  test('pierwszy wybór odznacza pozostałe', () {
    final filter = PinCategoryFilter.all.toggle(nature);
    expect(filter.isActive, isTrue);
    expect(filter.shows(nature), isTrue);
    expect(filter.shows(gastronomy), isFalse);
    expect(filter.shows(null), isFalse);
  });

  test('kolejny wybór zostawia poprzedni', () {
    final filter = PinCategoryFilter.all.toggle(nature).toggle(gastronomy);
    expect(filter.shows(nature), isTrue);
    expect(filter.shows(gastronomy), isTrue);
    expect(filter.shows(PlaceCategory.travel), isFalse);
  });

  test('tap w zaznaczoną odznacza, a ostatnia przywraca wszystkie', () {
    final two = PinCategoryFilter.all.toggle(nature).toggle(gastronomy);
    final one = two.toggle(nature);
    expect(one.shows(nature), isFalse);
    expect(one.shows(gastronomy), isTrue);
    expect(one.toggle(gastronomy).isActive, isFalse);
  });

  test('ręczne zaznaczenie wszystkich pozycji to stan domyślny', () {
    var filter = PinCategoryFilter.all.toggle(null);
    for (final category in PlaceCategory.values) {
      expect(filter.isActive, isTrue);
      filter = filter.toggle(category);
    }
    expect(filter.isActive, isFalse);
  });

  test('zielona pinezka jest osobną pozycją', () {
    final filter = PinCategoryFilter.all.toggle(null);
    expect(filter.matches(_pin('a', PinKind.standard)), isTrue);
    expect(filter.matches(_pin('b', const PinKind(PlaceType.cafe))), isFalse);
  });

  test('apply zostawia pinezki wybranych kategorii, też z typem „inne”', () {
    final pins = [
      _pin('green', PinKind.standard),
      _pin('cafe', const PinKind(PlaceType.cafe)),
      _pin('otherNature', const PinKind(PlaceType.natureOther)),
    ];
    final ids = PinCategoryFilter.all
        .toggle(nature)
        .apply(pins)
        .map((pin) => pin.id);
    expect(ids, ['otherNature']);
    expect(PinCategoryFilter.all.apply(pins), same(pins));
  });

  group('including', () {
    test('dodaje ukrytą pozycję do wyboru', () {
      final filter = PinCategoryFilter.all.toggle(nature).including(gastronomy);
      expect(filter.shows(nature), isTrue);
      expect(filter.shows(gastronomy), isTrue);
      expect(filter.shows(null), isFalse);
    });

    test('nie zmienia filtra, gdy pozycja jest widoczna', () {
      final filter = PinCategoryFilter.all.toggle(nature);
      expect(filter.including(nature), same(filter));
      expect(
        PinCategoryFilter.all.including(gastronomy),
        same(PinCategoryFilter.all),
      );
    });
  });
}
