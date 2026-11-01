"""SVG pinezek → PNG 3x przez Chrome headless; PNG przycięty tak, że czubek leży na dolnej krawędzi.

Użycie (z katalogu app/):
  python3 -I tool/render_pins.py assets/markers/src assets/markers <pusty katalog roboczy>
"""
import subprocess, sys, pathlib, math
src = pathlib.Path(sys.argv[1]); out = pathlib.Path(sys.argv[2]); work = pathlib.Path(sys.argv[3])
chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
# (szerokość viewBox, y czubka, skala do dp): korpus default = 36 dp, selected = 42 dp.
geo = {
    'default': (48, 56, 48, 1.0),
    'selected': (54, 64, 56, 1.0),
    'standard_default': (72, 88, 74.5, 0.75),
    'standard_selected': (72, 88, 74.5, 0.875),
}
for svg in sorted(src.glob('*.svg')):
    name = svg.stem
    key = name if name.startswith('standard') else name.split('_')[-1]
    vw, vh, tip, k = geo[key]
    w, h, cut = vw * k, vh * k, round(tip * k)
    html = work / f'{name}.html'
    html.write_text(
        '<!doctype html><html><head><style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}'
        f'img{{display:block;width:{w}px;height:{h}px}}</style></head>'
        f'<body><img src="{svg.as_uri()}"></body></html>')
    png = out / f'{name}.png'
    subprocess.run([chrome, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--force-device-scale-factor=3', '--default-background-color=00000000',
                    f'--window-size={math.ceil(w)},{cut}', f'--screenshot={png}', html.as_uri()],
                   check=True, capture_output=True)
    print(name, math.ceil(w), cut)
