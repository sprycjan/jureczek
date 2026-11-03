"""Biblioteka ikon typów miejsc (v15) – jedyne źródło rysunków symboli.

Dla każdego typu zapisuje trzy SVG w `assets/place_icons/<kategoria>/`:
  <typ>_icon.svg      – samodzielna ikona 24×24 dp w kolorze kategorii, przezroczyste tło,
  <typ>_default.svg   – pinezka 36×44 dp (viewBox 48×56 z marginesem na cień),
  <typ>_selected.svg  – pinezka zaznaczona 42×52 dp z białym pierścieniem (viewBox 54×64).

Symbole są rysowane obrysem 1.75 na siatce 24×24 (pole rysunku 20×20, margines 2),
`stroke-linecap/linejoin: round`. W pinezce symbol jest biały, ma pole 22 dp
(25.7 dp w zaznaczonej) i obrys przeliczony na 1.8 dp jak w referencji Stitch.

Cień pinezki to `feDropShadow` – `flutter_svg` go pomija, więc aplikacja maluje
ten sam cień sama (`PlacePin`, parametry w `place_pin.dart`, test pilnuje zgodności).

Kolory muszą być równe tokenom w `lib/features/places/domain/place_category.dart`
(test `place_icons_test.dart`). Nie edytować SVG ręcznie – zmieniać ten plik.

Użycie (z katalogu app/):
  python3 -I tool/place_icons.py assets/place_icons [arkusz_podgladu.html]
"""
import math, pathlib, sys

PRIMARY = {
    'gastronomy': '#E65100',
    'places': '#1565C0',
    'nature': '#2E7D32',
    'activities': '#7B1FA2',
    'travel': '#455A64',
    'entertainment': '#C2185B',
    'practical': '#00838F',
}

ICON_STROKE = 1.75
PIN_STROKE = 1.8  # widoczna grubość symbolu w pinezce (dp)

# Pinezki – te same kontury co w `assets/markers/src` (v9).
PIN = {
    'default': dict(
        view=(48, 56), size=(36, 44), ring=None, symbol=22.0,
        shadow=(3, 2.5, 0.3),
        d='M18 0 C8.06 0 0 8.06 0 18 C0 29.5 15.2 42.4 17.1 43.6 C17.65 44.05 18.35 44.05 18.9 43.6 '
          'C20.8 42.4 36 29.5 36 18 C36 8.06 27.94 0 18 0 Z'),
    'selected': dict(
        view=(54, 64), size=(42, 52), ring=3.0, symbol=22.0 * 42 / 36,
        shadow=(5, 4, 0.45),
        d='M21 0 C9.4 0 0 9.4 0 21 C0 34.5 17.8 49.8 19.9 51.5 C20.55 52.05 21.45 52.05 22.1 51.5 '
          'C24.2 49.8 42 34.5 42 21 C42 9.4 32.6 0 21 0 Z'),
}
PIN_OFFSET = (6, 4)

# Fale używane w kilku symbolach (woda pod spodem).
def waves(y, x0=2, x1=22, amp=1):
    seg, x, d = 4, x0, f'M{x0} {y}'
    up = True
    while x < x1 - 0.01:
        step = min(seg, x1 - x)
        dy = -amp if up else amp
        d += f'c{step * 0.4:.2f} 0 {step * 0.6:.2f} {dy} {step} {dy}'
        x += step
        up = not up
    return f'<path d="{d}"/>'


def gear(cx, cy, r_out, r_in, teeth, hole):
    pts = []
    for i in range(teeth * 4):
        a = 2 * math.pi * i / (teeth * 4) - math.pi / 2
        r = r_out if i % 4 in (1, 2) else r_in
        pts.append(f'{cx + r * math.cos(a):.2f} {cy + r * math.sin(a):.2f}')
    return f'<path d="M{" L".join(pts)} Z"/><circle cx="{cx}" cy="{cy}" r="{hole}"/>'


def wrench(x1, y1, x2, y2, r):
    """Klucz płaski: rączka od (x1, y1) do głowy w (x2, y2), szczęki otwarte na zewnątrz."""
    ux, uy = x2 - x1, y2 - y1
    n = math.hypot(ux, uy); ux, uy = ux / n, uy / n
    def rot(a):
        c, s_ = math.cos(a), math.sin(a)
        return x2 + r * (ux * c - uy * s_), y2 + r * (ux * s_ + uy * c)
    (ax, ay), (bx, by) = rot(math.radians(50)), rot(math.radians(-50))
    hx, hy = x2 - r * ux, y2 - r * uy
    return (f'<path d="M{x1:.2f} {y1:.2f}L{hx:.2f} {hy:.2f}"/>'
            f'<path d="M{ax:.2f} {ay:.2f}A{r} {r} 0 1 1 {bx:.2f} {by:.2f}"/>')


F = 'fill="$c" stroke="none"'  # element wypełniony kolorem symbolu

# typ → (kategoria, elementy SVG na siatce 24×24). Kolejność = kolejność w aplikacji.
SYMBOLS = {
    # ── Gastronomia ──────────────────────────────────────────────────────────
    'restaurant': ('gastronomy', '''
        <path d="M6 3v6a2.5 2.5 0 0 0 5 0V3"/><path d="M8.5 3v18"/>
        <path d="M17.5 21V3c-2.2 1.4-3.5 4.2-3.5 7.5 0 1.6 1.2 2.5 3.5 2.5"/>'''),
    'cafe': ('gastronomy', '''
        <path d="M4 9h12v4a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5V9z"/>
        <path d="M16 10.5h1.5a2.5 2.5 0 0 1 0 5H16"/><path d="M3 21h15"/>
        <path d="M8 3c-.8.8-.8 1.7 0 2.5M12 3c-.8.8-.8 1.7 0 2.5"/>'''),
    'bar': ('gastronomy', '''
        <path d="M3.5 5h14L10.5 13z"/><path d="M10.5 13v7.5"/><path d="M6.5 21h8"/>
        <circle cx="17.5" cy="5" r="3"/><path d="M15.5 2.5L19.5 7.5"/>'''),
    'pub': ('gastronomy', '''
        <path d="M5 9h10v10.5a1.5 1.5 0 0 1-1.5 1.5h-7A1.5 1.5 0 0 1 5 19.5z"/>
        <path d="M15 11h2.5a1.5 1.5 0 0 1 1.5 1.5v3a1.5 1.5 0 0 1-1.5 1.5H15"/>
        <path d="M5 9a2.5 2.5 0 0 1 1.5-4.5 3 3 0 0 1 5.5-.8A2.6 2.6 0 0 1 15 9"/>
        <path d="M8.5 12.5v5M11.5 12.5v5"/>'''),
    'bakery': ('gastronomy', '''
        <path d="M3 15.5a9 6.5 0 0 1 18 0v2.5a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
        <path d="M7.5 10.5l1.8 3M11.5 9.3l1.8 3.2M15.5 10.5l1.8 3"/>'''),
    'pastry_shop': ('gastronomy', '''
        <path d="M6 13.5l1.6 7.5h8.8l1.6-7.5"/>
        <path d="M5 13.5a2.8 2.8 0 0 1 1.2-5A5.8 5.8 0 0 1 17.8 8.5a2.8 2.8 0 0 1 1.2 5z"/>
        <circle cx="12" cy="3.8" r="1.6"/><path d="M10.5 14.5l.4 6M13.5 14.5l-.4 6"/>'''),
    'ice_cream_shop': ('gastronomy', '''
        <path d="M7.5 11.5L12 21.5l4.5-10"/><path d="M6.5 11.5h11"/>
        <path d="M7 11.5a5 5 0 0 1 4-6.4 3.2 3.2 0 0 1 6 2.2 3.4 3.4 0 0 1-.3 4.2"/>'''),
    'food_truck': ('gastronomy', '''
        <path d="M2.5 17V8h11.5v9"/><path d="M14 11h3.8l3.2 3.5V17"/>
        <path d="M2.5 17h1.5M8.5 17h6M19.5 17h1.5"/>
        <circle cx="6.2" cy="17.5" r="2"/><circle cx="17.2" cy="17.5" r="2"/>
        <path d="M2 8l1.5-3.5h9L14 8"/><path d="M5 10.5h6.5v3H5z"/>'''),
    'winery': ('gastronomy', '''
        <path d="M7 2.5h3M7.5 2.5v4L5.5 9v11a1 1 0 0 0 1 1h4a1 1 0 0 0 1-1V9l-2-2.5v-4"/>
        <path d="M5.5 12.5h6"/>
        <path d="M14.5 8.5h5.5v2a2.75 2.75 0 0 1-5.5 0z"/><path d="M17.25 13.25V20.5"/><path d="M15 21h4.5"/>'''),
    'brewery': ('gastronomy', '''
        <path d="M12 21.5V7"/>
        <path d="M12 7c-1.2-1.2-1.2-3.3 0-4.5 1.2 1.2 1.2 3.3 0 4.5z"/>
        <path d="M12 11c-2.6 0-4-1.6-4-4 2.6 0 4 1.6 4 4zM12 11c2.6 0 4-1.6 4-4-2.6 0-4 1.6-4 4z"/>
        <path d="M12 15.5c-2.6 0-4-1.6-4-4 2.6 0 4 1.6 4 4zM12 15.5c2.6 0 4-1.6 4-4-2.6 0-4 1.6-4 4z"/>
        <path d="M12 20c-2.6 0-4-1.6-4-4 2.6 0 4 1.6 4 4zM12 20c2.6 0 4-1.6 4-4-2.6 0-4 1.6-4 4z"/>'''),

    # ── Miejsca i atrakcje ───────────────────────────────────────────────────
    'city': ('places', '''
        <path d="M2.5 21h19"/><path d="M4 21V10h5"/><path d="M9 21V3.5h6V21"/><path d="M15 21v-8h5v8"/>
        <path d="M11.5 7h1M11.5 10.5h1M11.5 14h1M6 13.5h1M6 17h1M17 16h1"/>'''),
    'small_town': ('places', '''
        <path d="M2 21h20"/>
        <path d="M2.5 13L7 9l4.5 4"/><path d="M3.5 12v9M10.5 12v9"/><path d="M6 21v-3h2v3"/>
        <path d="M10 10l5.5-5 5.5 5"/><path d="M11.5 9v12M19.5 9v12"/><path d="M14.5 21v-4h2v4"/>
        <path d="M14.5 10.5h2v2h-2z"/>'''),
    'village': ('places', '''
        <path d="M2 21h20"/>
        <path d="M2.5 12.5L8 8l5.5 4.5"/><path d="M4 11.5V21M12 11.5V21"/><path d="M7 21v-4h2v4"/>
        <path d="M18 21v-5"/><circle cx="18" cy="11.5" r="3.5"/>
        <path d="M14.5 18.5h7"/>'''),
    'historical_monument': ('places', '''
        <path d="M10 15.5l1-11L12 2.5l1 2 1 11z"/>
        <path d="M8 15.5h8v3H8z"/><path d="M5 21.5h14"/><path d="M6.5 18.5v3M17.5 18.5v3"/>'''),
    'museum': ('places', '''
        <path d="M3 9l9-5.5L21 9z"/><path d="M4 19h16"/><path d="M2.5 21.5h19"/>
        <path d="M6 11.5V17M10 11.5V17M14 11.5V17M18 11.5V17"/>'''),
    'castle': ('places', '''
        <path d="M3.5 21V8h3v2.5h2.5V8h6v2.5h2.5V8h3v13z"/>
        <path d="M10 21v-4a2 2 0 0 1 4 0v4"/>
        <path d="M12 8V3l3 1.2L12 5.4"/><path d="M6.5 14h1M16.5 14h1"/>'''),
    'palace': ('places', '''
        <path d="M2.5 21h19"/><path d="M3.5 21v-8.5h17V21"/>
        <path d="M7.5 12.5a4.5 4.5 0 0 1 9 0"/><path d="M12 8V4.5"/><circle cx="12" cy="3.3" r=".9" ''' + F + '''/>
        <path d="M6.5 15.5v2.5M17.5 15.5v2.5"/><path d="M10.5 21v-3.5a1.5 1.5 0 0 1 3 0V21"/>'''),
    'church': ('places', '''
        <path d="M12 2v4M10.5 3.5h3"/><path d="M8 11.5l4-5.5 4 5.5"/>
        <path d="M8 11v10M16 11v10"/><path d="M8 13.5L4 16v5M16 13.5l4 2.5v5"/>
        <path d="M10.5 21v-3a1.5 1.5 0 0 1 3 0v3"/><path d="M3 21h18"/>'''),
    'monastery': ('places', '''
        <path d="M2.5 21h19"/><path d="M3 12.5h11.5"/><path d="M3.5 12.5V21M14 12.5V21"/>
        <path d="M5.5 21v-3a1.75 1.75 0 0 1 3.5 0v3"/><path d="M10.5 21v-3a1.75 1.75 0 0 1 3.5 0"/>
        <path d="M14.5 21V7l3-3.5 3 3.5v14"/><path d="M16.5 11V9.5a1 1 0 0 1 2 0V11z"/>'''),
    'ruins': ('places', '''
        <path d="M3 21.5h18"/><path d="M4.5 21.5V19h15v2.5"/>
        <path d="M6.5 19V7.5l1.5 1.3 1.5-1.8 1.5 1.6V19"/><path d="M9 11v5"/>
        <path d="M14 19v-6l1.5 1 1.5-1.4 1.5 1.1V19"/>'''),
    'monument_statue': ('places', '''
        <circle cx="12" cy="4" r="1.7"/><path d="M12 6.5v5.5"/><path d="M12 8l3.5-2.5M12 8.5l-2.5 2.2"/>
        <path d="M10.5 15l1.5-3 1.5 3"/><path d="M8 15h8v4.5H8z"/><path d="M5.5 21.5h13"/>'''),
    'historical_site': ('places', '''
        <path d="M2.5 21h19"/><path d="M4.5 21V8.5a5 5 0 0 1 10 0V21"/><path d="M7.5 10h4M7.5 13h4"/>
        <path d="M17 21v-5h3v5"/>
        <path d="M18.5 14c-.9-.8-.9-2 0-3 .9 1 .9 2.2 0 3z" ''' + F + '''/>'''),

    # ── Natura i widoki ─────────────────────────────────────────────────────
    'viewpoint': ('nature', '''
        <rect x="4.5" y="3.5" width="15" height="7.5" rx="2.5"/>
        <circle cx="8.8" cy="7.25" r="1.6"/><circle cx="15.2" cy="7.25" r="1.6"/>
        <path d="M12 11v6.5"/><path d="M12 17.5l-4.5 4M12 17.5l4.5 4"/>'''),
    'mountain_peak': ('nature', '''
        <path d="M2 20L9 6l7 14"/><path d="M13.5 15L17 10l5 10"/><path d="M2 20h20"/>
        <path d="M6.6 10.8l1.4 1.2L9 10.8l1 1.2 1.4-1.2"/>'''),
    'waterfall': ('nature', '''
        <path d="M2 21V9.5L5 5h3.5M22 21V9.5L19 5h-3.5"/>
        <path d="M9 5c-.6 4-.6 8.5 0 13M12 5v13M15 5c.6 4 .6 8.5 0 13"/>
        <path d="M7 20.5c1.2.8 2.3.8 3.5 0s2.3-.8 3.5 0 2.3.8 3.5 0"/>'''),
    'lake': ('nature', '''
        <path d="M6 14V9M9.5 14V6.5M13 14V9.5"/>
        <rect x="8.75" y="4.5" width="1.5" height="4.5" rx=".75" ''' + F + '''/>
        <rect x="5.25" y="7.5" width="1.5" height="3.5" rx=".75" ''' + F + '''/>
        <path d="M14 11.5c1.5-2 3.5-2.5 5-2"/>
        ''' + waves(16.5, 2, 22) + waves(20.5, 4, 20)),
    'beach': ('nature', '''
        <path d="M3.5 11a8.5 7.5 0 0 1 17 0z"/><path d="M8.5 11c0-4 1.5-6.7 3.5-7.5 2 .8 3.5 3.5 3.5 7.5"/>
        <path d="M12 11v7.5"/>
        ''' + waves(20.5, 2, 22)),
    'island': ('nature', '''
        <path d="M4.5 18.5a7.5 3.5 0 0 1 15 0"/>
        <path d="M12.5 16c.2-3-.4-5.8-2.2-8"/>
        <path d="M10.3 8C8.5 6.5 6 6.5 4 8M10.3 8c1-2 3.5-3 6-2.3M10.3 8c2.3.2 4.3 1.8 4.7 4.3M10.3 8C8.3 8.7 6.7 10.5 6.7 13"/>
        ''' + waves(21, 2, 22)),
    'national_park': ('nature', '''
        <circle cx="17.5" cy="6.5" r="3"/>
        <path d="M9 3L4.5 10.5H7L3.5 16.5h11L11 10.5h2.5z"/><path d="M9 16.5V21"/><path d="M2.5 21h19"/>'''),
    'nature_reserve': ('nature', '''
        <path d="M12 2.5l7.5 3v6c0 5-3.4 8.6-7.5 10-4.1-1.4-7.5-5-7.5-10v-6z"/>
        <path d="M8.5 15.5c0-4 2.8-6.6 7-7 0 4.2-2.8 7-7 7z"/><path d="M8.5 15.5l3.8-3.8"/>'''),
    'cave': ('nature', '''
        <path d="M2 20.5c0-6.5 3.5-12.5 10-13.5 6.5 1 10 7 10 13.5"/>
        <path d="M7.5 20.5v-3a4.5 4.5 0 0 1 9 0v3z" ''' + F + '''/><path d="M2 20.5h20"/>'''),
    'forest': ('nature', '''
        <path d="M5.5 8L2 15h7z"/><path d="M5.5 15v5"/>
        <path d="M12 3L8 12h8z"/><path d="M12 12v8"/>
        <path d="M18.5 8L15 15h7z"/><path d="M18.5 15v5"/><path d="M2 20.5h20"/>'''),
    'gorge_canyon': ('nature', '''
        <path d="M2.5 21V9.5L6 5l3 3.5L12 17l3-8.5L18 5l3.5 4.5V21"/>
        <path d="M2.5 21h19"/><path d="M11.4 18.5L9.5 21M12.6 18.5l1.9 2.5"/>'''),
    'spring': ('nature', '''
        <path d="M12 2.5c2.8 3.6 4.5 6 4.5 8.3a4.5 4.5 0 0 1-9 0c0-2.3 1.7-4.7 4.5-8.3z"/>
        <path d="M10 11.5a2 2 0 0 0 2 2"/>
        <path d="M3.5 18.5c2.5 1.8 14.5 1.8 17 0"/><path d="M7 21.5c2 .8 8 .8 10 0"/>'''),
    'river': ('nature', '''
        <path d="M5 2.5c0 3.5 7 3.5 7 7s-7 3.5-7 7c0 2.5 2 4 4 5"/>
        <path d="M12 2.5c0 3.5 7 3.5 7 7s-7 3.5-7 7c0 2.5 2 4 4 5"/>'''),

    # ── Aktywności i szlaki ─────────────────────────────────────────────────
    'hiking_trail': ('activities', '''
        <path d="M11 2.5V21.5"/><path d="M8 21.5h6"/>
        <path d="M11 5h7l2.5 2.5L18 10h-7"/><path d="M11 12.5H5.5L3 15l2.5 2.5H11"/>'''),
    'cycling_route': ('activities', '''
        <circle cx="5.5" cy="16" r="3.75"/><circle cx="18.5" cy="16" r="3.75"/>
        <path d="M5.5 16L9 9.5l3.5 6.5z"/><path d="M9 9.5h6.5L12.5 16"/><path d="M15.5 9.5l3 6.5"/>
        <path d="M7.5 7h3M9 7l.3 2.5"/><path d="M15.5 9.5L14.8 6.5h2.4"/>'''),
    'motorcycle_route': ('activities', '''
        <circle cx="5" cy="16.5" r="3.5"/><circle cx="19" cy="16.5" r="3.5"/>
        <path d="M5 16.5l4-4.5h7"/><path d="M8.5 16.5H13l3-4.5"/>
        <path d="M7.5 9.5h4l1.5-1.5h3"/><path d="M19 16.5L16 7h-2.5M16 7l1.5-1.5"/>'''),
    'scenic_drive': ('activities', '''
        <path d="M2 10.5l4.5-5 3 3 3.5-4.5 4.5 5 2-2 2.5 3.5"/>
        <path d="M10.5 12.5L5 21.5M13.5 12.5l5.5 9"/><path d="M12 14v1.5M12 18v2.5"/>'''),
    'cable_car': ('activities', '''
        <path d="M2 6.5L22 2.5"/><path d="M12 4.5V9"/>
        <rect x="5.5" y="9" width="13" height="11.5" rx="2.5"/><path d="M5.5 14h13"/><path d="M12 9v5"/>'''),
    'ski_slope': ('activities', '''
        <circle cx="16.5" cy="4" r="1.8"/>
        <path d="M15 7.5L10.5 10l3 3-2.5 4"/><path d="M15 7.5l2.5 3"/><path d="M10.5 10l-2.5 3.5"/>
        <path d="M3 15l17 6"/><path d="M19.5 7l-2 9"/>'''),
    'swimming_spot': ('activities', '''
        <circle cx="17" cy="7" r="2"/><path d="M3.5 13L9 8.5l3.5 3 2.5-2"/>
        ''' + waves(16.5, 2, 22) + waves(20.5, 2, 22)),
    'diving_spot': ('activities', '''
        <path d="M4.5 8h12a2 2 0 0 1 2 2v3.5a2 2 0 0 1-2 2H14l-1.5-2h-4L7 15.5H4.5a2 2 0 0 1-2-2V10a2 2 0 0 1 2-2z"/>
        <path d="M21 3v13a4 4 0 0 1-4 4h-3"/><circle cx="9" cy="4" r="1"/><circle cx="12.5" cy="3.5" r=".7"/>'''),
    'campsite': ('activities', '''
        <path d="M2.5 20.5h19"/><path d="M12 5L3.5 20.5M12 5l8.5 15.5"/>
        <path d="M12 12l-3.5 8.5M12 12l3.5 8.5"/><path d="M10.5 2.5L12 5l1.5-2.5"/>'''),
    'picnic_area': ('activities', '''
        <path d="M4 8h16"/><path d="M8.5 8l-4 13M15.5 8l4 13"/><path d="M3 14.5h18"/>'''),

    # ── Podróż i infrastruktura ─────────────────────────────────────────────
    'hotel': ('travel', '''
        <path d="M3 6v15M3 17.5h18M21 13.5V21"/><path d="M3 13.5h18"/>
        <rect x="5" y="9.5" width="4" height="3" rx="1.5"/><path d="M10.5 13.5V11h7a3 3 0 0 1 3 2.5"/>'''),
    'guesthouse': ('travel', '''
        <path d="M2.5 11.5L12 4l9.5 7.5"/><path d="M5 10v11h14V10"/><path d="M15.5 6.5V3.5h2v4.5"/>
        <path d="M12 17.5l-2.4-2.3a1.5 1.5 0 0 1 2.4-1.8 1.5 1.5 0 0 1 2.4 1.8z" ''' + F + '''/>
        <path d="M3 21h18"/>'''),
    'camping_ground': ('travel', '''
        <path d="M2 16.5V8a1.5 1.5 0 0 1 1.5-1.5h9.5l3.5 4h.5a1.5 1.5 0 0 1 1 1.5v4.5"/>
        <path d="M2 16.5h1.5M7.5 16.5h5.5M17 16.5h1"/>
        <circle cx="5.5" cy="17" r="2"/><circle cx="15" cy="17" r="2"/><path d="M4.5 9h4v2.5h-4z"/>
        <path d="M21 21V9.5M19.5 9.5h3"/><path d="M18 13h1.5a1.5 1.5 0 0 0 1.5-1.5"/>'''),
    'parking_lot': ('travel', '''
        <rect x="3" y="3" width="18" height="18" rx="4"/><path d="M9.5 17V7h3.5a3 3 0 0 1 0 6H9.5"/>'''),
    'gas_station': ('travel', '''
        <path d="M4.5 21V5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v16"/><path d="M3 21h13"/>
        <path d="M7 6.5h5V10H7z"/>
        <path d="M14.5 9h1.5a1.5 1.5 0 0 1 1.5 1.5V16a1.5 1.5 0 0 0 3 0V8L18 5.5"/>'''),
    'ev_charging': ('travel', '''
        <path d="M9 2.5v4.5M15 2.5v4.5"/><path d="M6 7h12v3.5a6 6 0 0 1-12 0z"/><path d="M12 16.5v5"/>
        <path d="M12.8 8.3l-2 2.7h2.4l-2 2.7"/>'''),
    'airport': ('travel', '''
        <g transform="rotate(45 12 12)">
        <path d="M12 2.5c.9 0 1.5 1 1.5 2.5v4.2l7 4.3v2l-7-2.3v4.3l2 1.5V20.5L12 19.5l-3.5 1V19l2-1.5v-4.3l-7 2.3v-2l7-4.3V5c0-1.5.6-2.5 1.5-2.5z"/>
        </g>'''),
    'railway_station': ('travel', '''
        <rect x="5" y="2.5" width="14" height="15" rx="3.5"/><path d="M7.5 5.5h9v4.5h-9z"/>
        <circle cx="8.8" cy="13.8" r="1" ''' + F + '''/><circle cx="15.2" cy="13.8" r="1" ''' + F + '''/>
        <path d="M8.5 17.5L6 21.5M15.5 17.5l2.5 4M7.2 19.5h9.6"/>'''),
    'harbour': ('travel', '''
        <circle cx="12" cy="4.5" r="2"/><path d="M12 6.5V21"/><path d="M8.5 10h7"/>
        <path d="M5.5 14H3.5a8.5 8.5 0 0 0 17 0h-2"/>'''),
    'marina': ('travel', '''
        <path d="M11.5 2.5V15"/><path d="M11.5 4L4.5 14h7"/><path d="M13.5 6.5l5 7.5h-5z"/>
        <path d="M3 16.5h18l-2.8 4H5.8z"/>'''),
    'ferry_terminal': ('travel', '''
        <path d="M2.5 13.5h19l-2.5 4.5H5z"/><path d="M5.5 13.5v-3h12v3"/><path d="M8.5 10.5V7.5h6v3"/>
        <path d="M11.5 7.5V4.5"/><path d="M8.5 12h1M11.5 12h1M14.5 12h1"/>
        ''' + waves(21, 2, 22)),

    # ── Rozrywka i kultura ──────────────────────────────────────────────────
    'theatre': ('entertainment', '''
        <path d="M2.5 3.5h9v5a4.5 4.5 0 0 1-9 0z"/><path d="M5 6.5h1M8 6.5h1"/><path d="M5.3 10.8a1.8 1.5 0 0 1 3.4 0"/>
        <path d="M12.5 10h9v5a4.5 4.5 0 0 1-9 0z"/><path d="M15 13h1M18 13h1"/><path d="M15.3 15.8a1.8 1.5 0 0 0 3.4 0"/>'''),
    'cinema': ('entertainment', '''
        <rect x="3" y="10" width="18" height="11" rx="1.5"/>
        <path d="M3 10l-.6-3.2 17.4-3.4.6 3.2z"/><path d="M7 6l2.5 3M11.5 5l2.5 3.2M16 4.2l2.5 3.2"/>
        <path d="M7 14h10"/>'''),
    'art_gallery': ('entertainment', '''
        <path d="M12 3a9 9 0 0 0 0 18c1.2 0 1.8-.8 1.8-1.7 0-1.5-1.3-1.7-1.3-3 0-1 .8-1.8 1.8-1.8H17a4 4 0 0 0 4-4C21 6.4 17 3 12 3z"/>
        <circle cx="7.5" cy="11.5" r="1.2" ''' + F + '''/><circle cx="9" cy="7.3" r="1.2" ''' + F + '''/>
        <circle cx="13.5" cy="6.5" r="1.2" ''' + F + '''/><circle cx="17" cy="9.5" r="1.2" ''' + F + '''/>'''),
    'concert_venue': ('entertainment', '''
        <path d="M9 18V5.5l11.5-2.5v12.5"/><path d="M9 9l11.5-2.5"/>
        <circle cx="6.5" cy="18" r="2.5"/><circle cx="18" cy="15.5" r="2.5"/>'''),
    'festival_event': ('entertainment', '''
        <path d="M3 21v-6.5L12 9l9 5.5V21"/><path d="M2 21h20"/><path d="M10 21l2-5.5 2 5.5"/>
        <path d="M12 9V3l3.5 1.3L12 5.6"/><path d="M3 14.5l-.8-2M21 14.5l.8-2"/>'''),
    'amusement_park': ('entertainment', '''
        <circle cx="12" cy="9.5" r="7"/><circle cx="12" cy="9.5" r="1.3"/>
        <path d="M12 2.5v5.7M12 10.8v5.7M5 9.5h5.7M13.3 9.5H19M7 4.5l4 4M13 10.5l4 4M17 4.5l-4 4M11 10.5l-4 4"/>
        <path d="M12 10.8L8 21.5M12 10.8l4 10.7"/><path d="M6 21.5h12"/>'''),
    'water_park': ('entertainment', '''
        <path d="M3.5 21V4M7.5 21V4M3.5 8h4M3.5 12h4M3.5 16h4"/>
        <path d="M7.5 5c5.5 0 11 1 11 4.5S10.5 12 10.5 15c0 1.6 1.6 2.2 4 2.2"/>
        ''' + waves(21, 9.5, 22)),
    'zoo': ('entertainment', '''
        <path d="M12 12.5c-3 0-5.5 3.2-5.5 5.5a2 2 0 0 0 2 2c1.3 0 2.2-.8 3.5-.8s2.2.8 3.5.8a2 2 0 0 0 2-2c0-2.3-2.5-5.5-5.5-5.5z"/>
        <ellipse cx="4.5" cy="10.5" rx="1.7" ry="2.2"/><ellipse cx="9" cy="5.5" rx="1.7" ry="2.3"/>
        <ellipse cx="15" cy="5.5" rx="1.7" ry="2.3"/><ellipse cx="19.5" cy="10.5" rx="1.7" ry="2.2"/>'''),
    'aquarium': ('entertainment', '''
        <path d="M2.5 12.5c3-4.5 9-6 13-3l4.5-3.5v13l-4.5-3.5c-4 3-10 1.5-13-3z"/>
        <circle cx="7" cy="11.5" r="1" ''' + F + '''/><path d="M11 10.5c.8 1.3.8 2.7 0 4"/>
        <circle cx="17" cy="3.5" r="1.2"/><circle cx="20.5" cy="2.8" r=".7"/>'''),
    'botanical_garden': ('entertainment', '''
        <path d="M6.5 15h11l-1.7 6.5H8.2z"/><path d="M12 15V8.5"/>
        <path d="M12 12c-3.5 0-5.5-2.2-5.5-5.5 3.5 0 5.5 2.2 5.5 5.5z"/>
        <path d="M12 9c0-3.5 2-6 5.5-6 0 3.5-2 6-5.5 6z"/>'''),

    # ── Punkty praktyczne ───────────────────────────────────────────────────
    'grocery_store': ('practical', '''
        <path d="M2.5 3.5h2.5l2.4 11.5h11l2-8.5H6"/>
        <circle cx="9" cy="19.5" r="1.6"/><circle cx="17" cy="19.5" r="1.6"/><path d="M10.5 9v3M14.5 9v3"/>'''),
    'pharmacy': ('practical', '''
        <path d="M9 3.5h6v5.5h5.5v6H15v5.5H9V15H3.5V9H9z"/>'''),
    'atm': ('practical', '''
        <rect x="3" y="2.5" width="18" height="11" rx="2"/><path d="M6.5 5.5h11v4h-11z"/><path d="M6 13.5h12"/>
        <path d="M8.5 13.5v8h7v-8"/><circle cx="12" cy="17.5" r="1.5"/>'''),
    'public_toilet': ('practical', '''
        <circle cx="7" cy="4.5" r="1.8" ''' + F + '''/><circle cx="17" cy="4.5" r="1.8" ''' + F + '''/>
        <path d="M5.2 8.5h3.6v6.5h-.8v6H6v-6h-.8z" fill="$c"/>
        <path d="M17 8.5l-3.3 7.5h6.6z" fill="$c"/><path d="M15.8 16v5M18.2 16v5"/>
        <path d="M12 3v18"/>'''),
    'tourist_info': ('practical', '''
        <circle cx="12" cy="12" r="9"/><path d="M12 11v6"/><circle cx="12" cy="7.5" r="1.2" ''' + F + '''/>'''),
    'bicycle_repair': ('practical', '''
        ''' + gear(9.5, 14.5, 7, 5.5, 8, 2.2) + wrench(14.8, 9.2, 19.2, 4.8, 2.5)),
    'car_repair': ('practical', '''
        <path d="M5 15l1.8-4.5h10.4L19 15"/><path d="M3.5 15h17v4.5h-17z"/><path d="M5.5 19.5v2M18.5 19.5v2"/>
        <circle cx="7" cy="17.2" r="1" ''' + F + '''/><circle cx="17" cy="17.2" r="1" ''' + F + '''/>
        ''' + wrench(9, 5, 4.6, 5, 2.2) + wrench(15, 5, 19.4, 5, 2.2) + '<path d="M9 5h6"/>'),
    'laundromat': ('practical', '''
        <rect x="4" y="2.5" width="16" height="19" rx="2"/><path d="M4 7h16"/>
        <circle cx="12" cy="14.2" r="4.5"/><path d="M9 14.6c1-.8 2-.8 3 0s2 .8 3 0"/>
        <circle cx="7" cy="4.8" r=".7" ''' + F + '''/><circle cx="9.8" cy="4.8" r=".7" ''' + F + '''/>'''),

    # ── „Inne” w każdej kategorii (v16) – ogólny znak kategorii ─────────────
    'gastronomy_other': ('gastronomy', '''
        <path d="M4 16.5a8 8 0 0 1 16 0z"/><path d="M2.5 16.5h19"/><path d="M5 19.5h14"/>
        <circle cx="12" cy="6.5" r="1.3"/>'''),
    'places_other': ('places', '''
        <path d="M6 21.5V3"/><path d="M6 4h12l-2.8 3.8L18 11.5H6"/><path d="M3.5 21.5h5"/>'''),
    'nature_other': ('nature', '''
        <path d="M4.5 19.5c0-8.5 5.5-15 15-15 0 9.5-6.5 15-15 15z"/><path d="M4.5 19.5l9.5-9.5"/>'''),
    'activities_other': ('activities', '''
        <path d="M2 20.5L10 9l4 5.5 2.2-3 5.8 9z"/><path d="M10 9V2.5l4.5 1.6L10 5.8"/>'''),
    'travel_other': ('travel', '''
        <rect x="3" y="7" width="18" height="13" rx="2"/>
        <path d="M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/><path d="M7.5 7v13M16.5 7v13"/>'''),
    'entertainment_other': ('entertainment', '''
        <path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z"/>'''),
    'practical_other': ('practical', '''
        ''' + wrench(4.5, 19.5, 17, 7, 2.6) + '''
        <path d="M4.5 4.5l2.5 1 5.5 5.5-1.5 1.5L5.5 7z"/><path d="M13 13.5l1.5-1.5 5.5 5.5a1.06 1.06 0 0 1-1.5 1.5z"/>'''),
}


def body(symbol, color):
    return '\n'.join(line.strip() for line in symbol.replace('$c', color).strip().splitlines())


def icon_svg(symbol, color):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">\n'
        f'<g fill="none" stroke="{color}" stroke-width="{ICON_STROKE}" stroke-linecap="round" stroke-linejoin="round">\n'
        f'{body(symbol, color)}\n</g>\n</svg>\n')


def pin_svg(symbol, color, state):
    p = PIN[state]
    vw, vh = p['view']
    w, h = p['size']
    ox, oy = PIN_OFFSET
    dy, blur, alpha = p['shadow']
    k = p['symbol'] / 24
    sx, sy = ox + w / 2 - p['symbol'] / 2, oy + w / 2 - p['symbol'] / 2
    ring = f' stroke="#FFFFFF" stroke-width="{p["ring"]}"' if p['ring'] else ''
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vw} {vh}" width="{vw}" height="{vh}">\n'
        '<defs>\n'
        f'<filter id="shadow" x="-30%" y="-15%" width="160%" height="160%">'
        f'<feDropShadow dx="0" dy="{dy}" stdDeviation="{blur}" flood-color="#000000" flood-opacity="{alpha}"/></filter>\n'
        '</defs>\n'
        f'<path transform="translate({ox} {oy})" filter="url(#shadow)" fill="{color}"{ring} d="{p["d"]}"/>\n'
        f'<g transform="translate({sx:g} {sy:g}) scale({k:.5f})" fill="none" stroke="#FFFFFF" '
        f'stroke-width="{PIN_STROKE / k:.3f}" stroke-linecap="round" stroke-linejoin="round">\n'
        f'{body(symbol, "#FFFFFF")}\n</g>\n</svg>\n')


def contact_sheet(out, sheet):
    rows = []
    for cat in PRIMARY:
        cells = ''.join(
            f'<figure><img src="{(out / cat / f"{t}_default.svg").resolve().as_uri()}" width=96>'
            f'<img src="{(out / cat / f"{t}_selected.svg").resolve().as_uri()}" width=108>'
            f'<span><img src="{(out / cat / f"{t}_icon.svg").resolve().as_uri()}" width=24>'
            f'<img src="{(out / cat / f"{t}_icon.svg").resolve().as_uri()}" width=48></span>'
            f'<figcaption>{t}</figcaption></figure>'
            for t, (c, _) in SYMBOLS.items() if c == cat)
        rows.append(f'<h2>{cat}</h2><div class=row>{cells}</div>')
    sheet.write_text(
        '<!doctype html><style>body{background:#e8e4dc;font:11px sans-serif;margin:8px}'
        '.row{display:flex;flex-wrap:wrap;gap:6px}h2{margin:6px 0 2px;font-size:13px}'
        'figure{margin:0;background:#fff;padding:4px;display:flex;align-items:flex-end;gap:2px;width:300px}'
        'span{display:flex;flex-direction:column;gap:4px}figcaption{font-size:11px;width:60px;word-break:break-all}'
        '</style>' + ''.join(rows))


def main():
    out = pathlib.Path(sys.argv[1])
    for t, (cat, symbol) in SYMBOLS.items():
        d = out / cat
        d.mkdir(parents=True, exist_ok=True)
        color = PRIMARY[cat]
        (d / f'{t}_icon.svg').write_text(icon_svg(symbol, color))
        (d / f'{t}_default.svg').write_text(pin_svg(symbol, color, 'default'))
        (d / f'{t}_selected.svg').write_text(pin_svg(symbol, color, 'selected'))
    if len(sys.argv) > 2:
        contact_sheet(out, pathlib.Path(sys.argv[2]))
    print(f'{len(SYMBOLS)} typów, {3 * len(SYMBOLS)} plików SVG')


main()
