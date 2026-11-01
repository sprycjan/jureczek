/// Typ pinezki (v9): domyślna zielona i 7 kategorii ze specyfikacji
/// `resorces/…/specyfikacja_systemu_ikon_i_pinezek_vanventure_android.md`.
///
/// [key] trafia do bazy – nie zmieniać istniejących wartości.
enum PinCategory {
  standard('standard'),
  gastronomy('gastronomy'),
  places('places'),
  nature('nature'),
  activities('activities'),
  travel('travel'),
  entertainment('entertainment'),
  practical('practical');

  const PinCategory(this.key);

  final String key;

  static const fallback = PinCategory.standard;

  /// Nieznany lub pusty klucz to [fallback], żeby stary albo zepsuty wiersz nie wywracał mapy.
  static PinCategory fromKey(String? key) {
    for (final category in values) {
      if (category.key == key) return category;
    }
    return fallback;
  }

  /// PNG 3x, przycięty tak, że czubek pinezki leży na dolnej krawędzi
  /// (źródła i generator: `assets/markers/src/`).
  String asset({bool selected = false}) =>
      'assets/markers/${key}_${selected ? 'selected' : 'default'}.png';
}

/// Gęstość pikseli, w jakiej wyrenderowano PNG pinezek.
const pinImageScale = 3.0;
