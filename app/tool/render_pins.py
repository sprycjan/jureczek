"""SVG pinezek → PNG 3x przez Chrome headless; PNG przycięty tak, że czubek leży na dolnej krawędzi.

Oprócz gotowych pinezek (`<out>/<nazwa>.png`) zapisuje warstwy do barwienia
w aplikacji (v14, własny kolor pinezki) w `<out>/tint/`:
  <nazwa>_body.png    – korpus na biało (z cieniem); aplikacja mnoży go przez kolor,
  <nazwa>_overlay.png – to, co zostaje bez zmian: biały symbol, biała obwódka, tarcza,
  <nazwa>_accent.png  – kolorowe elementy nad nakładką (kropka pinezki domyślnej).
Elementy „w kolorze” to te z kolorem kategorii albo gradientem `pin-gradient`.

Użycie (z katalogu app/):
  python3 -I tool/render_pins.py assets/markers/src assets/markers <pusty katalog roboczy>
"""
import copy, math, pathlib, subprocess, sys
import xml.etree.ElementTree as ET

src = pathlib.Path(sys.argv[1]); out = pathlib.Path(sys.argv[2]); work = pathlib.Path(sys.argv[3])
(out / 'tint').mkdir(exist_ok=True)
chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
SVG = 'http://www.w3.org/2000/svg'
ET.register_namespace('', SVG)
q = lambda tag: f'{{{SVG}}}{tag}'
NEUTRAL = {None, 'none', '#FFFFFF', '#ffffff', '#000000'}

# (szerokość viewBox, wysokość, y czubka, skala do dp): korpus default = 36 dp, selected = 42 dp.
geo = {
    'default': (48, 56, 48, 1.0),
    'selected': (54, 64, 56, 1.0),
    'standard_default': (72, 88, 74.5, 0.75),
    'standard_selected': (72, 88, 74.5, 0.875),
}

# Gradienty pinezki domyślnej przełożone na odcienie bieli: po pomnożeniu przez
# kolor dają jaśniejszą górę i ciemniejszy dół, jak oryginał.
TINT_DEFS = '''<defs xmlns="http://www.w3.org/2000/svg">
  <linearGradient id="tint-fill" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#FFFFFF"/><stop offset="100%" stop-color="#B0B0B0"/>
  </linearGradient>
  <linearGradient id="tint-stroke" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.8"/><stop offset="100%" stop-color="#5A5A5A" stop-opacity="0.9"/>
  </linearGradient>
</defs>'''


def is_tint(el):
    fill = el.get('fill')
    return fill == 'url(#pin-gradient)' or fill not in NEUTRAL and not fill.startswith('url(')


def main_group(root):
    return next(c for c in root if c.tag == q('g'))


def layers(svg_text):
    """Zwraca (body, overlay, accent | None) jako teksty SVG."""
    result = []
    for layer in ('body', 'overlay', 'accent'):
        root = ET.fromstring(svg_text)
        root.append(ET.fromstring(TINT_DEFS))
        group = main_group(root)
        seen_neutral = False
        kept = 0
        for el in list(group):
            tint = is_tint(el)
            accent = tint and seen_neutral
            seen_neutral |= not tint
            if layer == 'body':
                if not tint or accent:
                    group.remove(el); continue
                el.set('fill', 'url(#tint-fill)' if el.get('fill').startswith('url(') else '#FFFFFF')
                if el.get('stroke') == 'url(#pin-stroke)':
                    el.set('stroke', 'url(#tint-stroke)')
            elif layer == 'overlay':
                if tint and el.get('stroke') == '#FFFFFF' and not accent:
                    el.set('fill', 'none')  # sama biała obwódka zaznaczenia
                elif tint:
                    group.remove(el); continue
            else:
                if not accent:
                    group.remove(el); continue
                el.set('fill', '#FFFFFF')
            kept += 1
        if layer != 'body':
            group.attrib.pop('filter', None)  # cień jest już w warstwie korpusu
        result.append(ET.tostring(root, encoding='unicode') if kept else None)
    return result


def render(svg_path, png, w, h, cut):
    html = work / f'{png.stem}.html'
    html.write_text(
        '<!doctype html><html><head><style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}'
        f'img{{display:block;width:{w}px;height:{h}px}}</style></head>'
        f'<body><img src="{svg_path.as_uri()}"></body></html>')
    subprocess.run([chrome, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--force-device-scale-factor=3', '--default-background-color=00000000',
                    f'--window-size={math.ceil(w)},{cut}', f'--screenshot={png}', html.as_uri()],
                   check=True, capture_output=True)


for svg in sorted(src.glob('*.svg')):
    name = svg.stem
    key = name if name.startswith('standard') else name.split('_')[-1]
    vw, vh, tip, k = geo[key]
    w, h, cut = vw * k, vh * k, round(tip * k)
    render(svg.resolve(), out / f'{name}.png', w, h, cut)
    for layer, text in zip(('body', 'overlay', 'accent'), layers(svg.read_text())):
        if text is None:
            continue
        tmp = (work / f'{name}_{layer}.svg').resolve()
        tmp.write_text(text)
        render(tmp, out / 'tint' / f'{name}_{layer}.png', w, h, cut)
    print(name, math.ceil(w), cut)
