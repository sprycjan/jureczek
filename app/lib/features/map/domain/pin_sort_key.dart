/// Kolejność rysowania pinezki na mapie (`symbolSortKey`, v22): wyższy klucz jest
/// na wierzchu. Od góry: zaznaczona, z gwiazdką, pozostałe. Klucz wyłącza układanie
/// według pozycji na ekranie, więc w grupie południowe przykrywają północne,
/// tak jak na mapie skierowanej na północ.
double pinSortKey({
  required double lat,
  required bool selected,
  required bool starred,
}) => (selected ? _selectedStep : 0) + (starred ? _starredStep : 0) - lat;

/// Progi większe niż cały zakres szerokości geograficznej (180°).
const _starredStep = 1000.0;
const _selectedStep = 2000.0;
