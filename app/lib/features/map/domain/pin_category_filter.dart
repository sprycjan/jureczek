import 'package:flutter/foundation.dart';

import '../../places/domain/place_category.dart';
import 'place_pin.dart';

/// Filtr kategorii pinezek na mapie (v18).
///
/// Pozycja filtra to [PlaceCategory] albo `null` – zielona „Pinezka” bez typu.
/// Pusty wybór oznacza „wszystkie”: każda pozycja jest wtedy zaznaczona, więc
/// pierwszy [toggle] zostawia tylko wskazaną, a kolejne dodają następne.
@immutable
class PinCategoryFilter {
  const PinCategoryFilter._(this._selected);

  static const all = PinCategoryFilter._({});

  /// Kategorie i zielona „Pinezka”.
  static final _optionCount = PlaceCategory.values.length + 1;

  final Set<PlaceCategory?> _selected;

  /// Czy część pinezek jest ukryta.
  bool get isActive => _selected.isNotEmpty;

  /// Czy pozycja jest zaznaczona, czyli jej pinezki są widoczne.
  bool shows(PlaceCategory? category) =>
      !isActive || _selected.contains(category);

  bool matches(PlacePin pin) => shows(pin.kind.type?.category);

  List<PlacePin> apply(List<PlacePin> pins) =>
      isActive ? pins.where(matches).toList() : pins;

  /// Tap w pozycję. Odznaczenie ostatniej i zaznaczenie wszystkich to „wszystkie”.
  PinCategoryFilter toggle(PlaceCategory? category) {
    if (!isActive) return PinCategoryFilter._({category});
    final selected = {..._selected};
    if (!selected.remove(category)) selected.add(category);
    if (selected.isEmpty || selected.length == _optionCount) return all;
    return PinCategoryFilter._(selected);
  }

  /// Filtr, który pokazuje też tę pozycję – dla pinezki, która ma zostać widoczna.
  PinCategoryFilter including(PlaceCategory? category) =>
      shows(category) ? this : toggle(category);
}
