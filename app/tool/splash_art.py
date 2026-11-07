"""Grafika ekranu powitalnego (v24) – jedyne źródło rysunków; SVG się nie edytuje.

Zapisuje do `assets/splash/`:
  camper_under.svg, camper_wheel.svg, camper_body.svg, camper_night.svg, dust.svg
  sky_<pora>.svg                – niebo, słońce albo księżyc (nieruchome)
  scene_NN/<warstwa>.svg        – warstwy paralaksy, każda zawija się w swoim okresie
  palettes.json                 – token (#xxxxxx w SVG) → kolor dla każdej pory dnia
  manifest.json                 – sceny, warstwy, okresy, prędkości, pierwszy kadr

W SVG są tylko ścieżki i gradienty (`flutter_svg` pomija filtry), a kolory to tokeny:
aplikacja podstawia kolor pory dnia przez `ColorMapper`. Kolory wynikają z modelu
światła: albedo materiału × (słońce/otoczenie) + mgła zależna od odległości, więc
wszystkie sceny są spójne w każdej porze bez ręcznego strojenia setek kolorów.

Współrzędne: scena ma 1000 jednostek wysokości, kamper stoi na y = GROUND.

Użycie (z katalogu app/):
  python3 -I tool/splash_art.py assets/splash
  python3 -I tool/splash_art.py assets/splash --preview <katalog_na_png>
"""
import json, math, pathlib, random, subprocess, sys

PERIODS = ('dawn', 'day', 'sunset', 'night')
SCENE_H = 1000
GROUND = 884  # y styku kół z drogą
CAMPER_SCALE = 0.48
SEAM_OVERLAP = 2  # jednostki; kafel warstwy jest o tyle szerszy niż jej okres
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

# ---------------------------------------------------------------- kolory i tokeny


def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def hx(c):
    return '#' + ''.join(f'{round(max(0, min(1, v)) * 255):02X}' for v in c)


def mix(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


LIGHT = {
    'dawn': dict(sun=(1.22, 1.00, 0.92), amb=(0.60, 0.62, 0.88), haze=rgb('#EDB8C4'), fog=0.74),
    'day': dict(sun=(1.16, 1.13, 1.00), amb=(0.60, 0.72, 0.96), haze=rgb('#BFE3EE'), fog=0.66),
    'sunset': dict(sun=(1.28, 0.95, 0.78), amb=(0.50, 0.56, 0.86), haze=rgb('#E78FA0'), fog=0.74),
    'night': dict(sun=(0.48, 0.60, 1.00), amb=(0.15, 0.17, 0.42), haze=rgb('#2F2C6E'), fog=0.70),
}

_tokens = {}  # krotka czterech kolorów → token


def token(values):
    """Token dla czterech kolorów pór dnia. Te same kolory = ten sam token."""
    key = tuple(values[p] for p in PERIODS)
    if key not in _tokens:
        _tokens[key] = f'#{0x100000 + len(_tokens) * 7:06X}'
    return _tokens[key]


def fixed(dawn, day, sunset, night):
    return token(dict(dawn=dawn, day=day, sunset=sunset, night=night))


def mat(albedo, lit, depth=0.0):
    """Materiał: `lit` 0 = w cieniu, 1 = w pełnym świetle; `depth` 0 = blisko, 1 = daleko."""
    a = rgb(albedo)
    out = {}
    for p in PERIODS:
        L = LIGHT[p]
        c = tuple(v * (s * lit + m * (1 - lit)) for v, s, m in zip(a, L['sun'], L['amb']))
        out[p] = hx(mix(c, L['haze'], depth * L['fog']))
    return token(out)


def haze():
    return token({p: hx(LIGHT[p]['haze']) for p in PERIODS})


def camper(base):
    """Kolor kampera: rozpoznawalny o każdej porze, lekko przyciemniony przez światło."""
    tint = dict(dawn=(1.0, 0.96, 0.95), day=(1.0, 1.0, 1.0), sunset=(1.0, 0.92, 0.88), night=(0.46, 0.50, 0.70))
    a = rgb(base)
    return token({p: hx(tuple(v * t for v, t in zip(a, tint[p]))) for p in PERIODS})


# ---------------------------------------------------------------- ścieżki i warstwy


def n(v):
    s = f'{v:.1f}'
    return s[:-2] if s.endswith('.0') else s


def area(pts):
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))


class Path:
    """Zamknięty kształt jako polilinia lub krzywa; zawsze ten sam kierunek obiegu,
    żeby kształty sklejone w jeden `d` nie wycinały w sobie dziur."""

    def __init__(self, pts, smooth=False):
        pts = list(pts)
        if area(pts) < 0:
            pts.reverse()
        self.pts = pts
        self.smooth = smooth

    def d(self, dx=0):
        p = self.pts
        out = [f'M{n(p[0][0] + dx)} {n(p[0][1])}']
        if not self.smooth:
            out += [f'L{n(x + dx)} {n(y)}' for x, y in p[1:]]
        else:
            m = len(p)
            for i in range(m):
                p0, p1, p2, p3 = p[i - 1], p[i], p[(i + 1) % m], p[(i + 2) % m]
                c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
                c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
                out.append(f'C{n(c1[0] + dx)} {n(c1[1])} {n(c2[0] + dx)} {n(c2[1])} {n(p2[0] + dx)} {n(p2[1])}')
        return ''.join(out) + 'Z'

    def xrange(self):
        xs = [x for x, _ in self.pts]
        return min(xs), max(xs)


class Layer:
    def __init__(self, width, height=SCENE_H):
        self.w, self.h = width, height
        self.items = []
        self.defs = {}

    def add(self, pts, fill, smooth=False, opacity=None):
        self.items.append((Path(pts, smooth), fill, opacity))

    def vgrad(self, y0, y1, stops):
        return self._grad('linearGradient', f'x1="0" y1="{n(y0)}" x2="0" y2="{n(y1)}"', stops)

    def rgrad(self, cx, cy, r, stops):
        return self._grad('radialGradient', f'cx="{n(cx)}" cy="{n(cy)}" r="{n(r)}"', stops)

    def _grad(self, tag, attrs, stops):
        body = ''.join(
            f'<stop offset="{o:.3g}" stop-color="{c}"' + (f' stop-opacity="{a:.3g}"' if a < 1 else '') + '/>'
            for o, c, a in ((s + (1,))[:3] for s in stops)
        )
        key = (tag, attrs, body)
        if key not in self.defs:
            self.defs[key] = f'g{len(self.defs)}'
        return f'url(#{self.defs[key]})'

    def render(self):
        out = [
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w + SEAM_OVERLAP}" height="{self.h}" '
            f'viewBox="0 0 {self.w + SEAM_OVERLAP} {self.h}">'
        ]
        if self.defs:
            out.append('<defs>')
            for (tag, attrs, body), gid in self.defs.items():
                out.append(f'<{tag} id="{gid}" gradientUnits="userSpaceOnUse" {attrs}>{body}</{tag}>')
            out.append('</defs>')
        run_fill, run_op, run = None, None, []

        def flush():
            if run:
                op = f' fill-opacity="{run_op:.3g}"' if run_op is not None else ''
                out.append(f'<path fill="{run_fill}"{op} d="{"".join(run)}"/>')
                run.clear()

        for path, fill, opacity in self.items:
            if (fill, opacity) != (run_fill, run_op):
                flush()
                run_fill, run_op = fill, opacity
            lo, hi = path.xrange()
            # Zawijanie: kształt wystający poza okres wraca z drugiej strony.
            for dx in (-self.w, 0, self.w):
                if hi + dx > 0 and lo + dx < self.w + SEAM_OVERLAP:
                    run.append(path.d(dx))
        flush()
        out.append('</svg>')
        return '\n'.join(out)


# ---------------------------------------------------------------- góry


def jag(p0, p1, rough, rng, depth=3):
    """Poszarpana linia między punktami: fasety zamiast gładkiego szumu."""
    if depth == 0:
        return [p0, p1]
    t = rng.uniform(0.35, 0.65)
    mx, my = p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    length = math.hypot(dx, dy) or 1
    off = rng.uniform(-1, 1) * rough * length
    m = (mx - dy / length * off, my + dx / length * off)
    return jag(p0, m, rough * 0.9, rng, depth - 1)[:-1] + jag(m, p1, rough * 0.9, rng, depth - 1)


def chain(points, rough, rng, depth=3):
    out = []
    for a, b in zip(points, points[1:]):
        out += jag(a, b, rough, rng, depth)[:-1]
    return out + [points[-1]]


def x_at_y(line, y):
    """x polilinii opadającej (y rośnie) na wysokości y."""
    for a, b in zip(line, line[1:]):
        if a[1] <= y <= b[1] and b[1] != a[1]:
            return a[0] + (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1])
    return line[-1][0]


def gully(layer, top, length, lean, width, fill, rng, rough=0.12):
    """Wąski, zwężający się klin – żleb, grań albo płyta skalna."""
    end = (top[0] + lean * length, top[1] + length)
    spine = jag(top, end, rough, rng, 3)
    m = len(spine) - 1
    out = []
    for i, (x, y) in enumerate(spine):
        s = math.sin(math.pi * min(1, (i / m) * 1.05 + 0.02)) ** 0.8
        out.append((x + width * s * rng.uniform(0.55, 1.15), y + width * 0.2 * s))
    layer.add(spine + out[::-1][1:-1], fill)


# Sylwetki masywów: (u, v), u -1..1 przez szerokość, v 0 = wierzchołek, 1 = podstawa.
# Celowo różne: tylko jedna jest iglicą, reszta to kopuły, stoły, ramiona i grzbiety.
MASSIFS = {
    'horn': [(-1, 1), (-.74, .74), (-.52, .6), (-.32, .36), (-.15, .22), (0, 0), (.15, .13), (.3, .36), (.52, .5), (.76, .75), (1, 1)],
    'broad': [(-1, 1), (-.8, .72), (-.62, .5), (-.48, .42), (-.36, .2), (-.22, .1), (-.12, .02), (.02, 0), (.1, .05), (.18, .03), (.28, .14), (.36, .12), (.46, .28), (.6, .46), (.76, .7), (1, 1)],
    'hump': [(-1, 1), (-.84, .7), (-.64, .44), (-.44, .23), (-.22, .08), (.02, 0), (.24, .05), (.44, .18), (.6, .4), (.8, .68), (1, 1)],
    'table': [(-1, 1), (-.87, .74), (-.72, .62), (-.63, .36), (-.55, .1), (-.46, .04), (-.1, .01), (.24, 0), (.35, .06), (.42, .3), (.57, .38), (.67, .62), (.85, .77), (1, 1)],
    'twin': [(-1, 1), (-.79, .67), (-.57, .37), (-.39, .07), (-.28, 0), (-.13, .2), (.03, .35), (.14, .27), (.3, .1), (.41, .13), (.57, .35), (.77, .63), (1, 1)],
    'shoulder': [(-1, 1), (-.72, .78), (-.46, .62), (-.22, .44), (0, .27), (.2, .1), (.34, 0), (.46, .03), (.53, .28), (.66, .45), (.75, .71), (1, 1)],
    'cliff': [(-1, 1), (-.76, .72), (-.66, .46), (-.54, .05), (-.42, 0), (-.26, .06), (-.02, .22), (.24, .42), (.5, .58), (.76, .78), (1, 1)],
    'ridge': [(-1, 1), (-.79, .6), (-.63, .42), (-.5, .5), (-.36, .22), (-.24, .3), (-.1, .06), (.02, .2), (.14, 0), (.3, .2), (.43, .12), (.58, .36), (.75, .52), (1, 1)],
    'crag': [(-1, 1), (-.81, .7), (-.69, .66), (-.57, .4), (-.41, .34), (-.31, .08), (-.1, 0), (.06, .06), (.14, .25), (.3, .29), (.43, .5), (.6, .56), (.73, .78), (1, 1)],
}

# Doliny odbijają zieleń i chłód: podstawa masywu przechodzi w ten kolor.
VALLEY = fixed('#8FA6B5', '#A9D2D8', '#6F8F96', '#25305E')


class Massif:
    def __init__(self, layer, x, top, half, base, shape, rock, rng, depth):
        self.layer, self.x, self.top, self.half, self.base = layer, x, top, half, base
        self.rock, self.rng, self.depth = rock, rng, depth
        self.h = base - top
        knots = [
            (x + half * (u + (rng.uniform(-.03, .03) if abs(u) < 1 else 0)),
             top + self.h * max(0, min(1, v + (rng.uniform(-.03, .03) if 0 < v < 1 else 0))))
            for u, v in MASSIFS[shape]
        ]
        self.knots = knots
        self.sky = chain(knots, 0.055, rng, depth=2)
        self.lo, self.hi = x - half, x + half
        # Tabela wysokości stoku co jednostkę: wnętrze rysunku nie wyjdzie poza sylwetkę.
        self.table = {}
        for (ax, ay), (bx, by) in zip(self.sky, self.sky[1:]):
            x0, x1 = sorted((ax, bx))
            for ix in range(math.floor(x0), math.ceil(x1) + 1):
                t = 0 if bx == ax else max(0, min(1, (ix - ax) / (bx - ax)))
                y = ay + (by - ay) * t
                self.table[ix] = min(self.table.get(ix, 1e9), y)
        # Wierzchołki: lokalne minima v w węzłach.
        self.summits = [
            k for prev, k, nxt in zip(knots, knots[1:], knots[2:])
            if k[1] <= prev[1] and k[1] <= nxt[1]
        ]

    def sky_y(self, x):
        return self.table.get(round(max(self.lo, min(self.hi, x))), self.base)

    def inside(self, pts):
        """Przycina punkty do sylwetki, zostawiając na wierzchu tylko rysunek masywu."""
        out = []
        for x, y in pts:
            x = max(self.lo, min(self.hi, x))
            out.append((x, min(self.base, max(y, self.sky_y(x) + 0.4))))
        return out

    def tone(self, lit, depth=None):
        return mat(self.rock, round(lit * 10) / 10, self.depth if depth is None else depth)

    def segments(self):
        """Dla każdego wierzchołka: stok w stronę słońca i przeciwny, jako zakresy x."""
        xs = [k[0] for k in self.summits]
        for i, sx in enumerate(xs):
            right = (xs[i + 1] + sx) / 2 if i + 1 < len(xs) else self.hi
            left = (xs[i - 1] + sx) / 2 if i else self.lo
            yield sx, self.summits[i][1], left, right

    def spindle(self, sx, sy, length, angle, width, fill, bend=None, opacity=None):
        """Kanciasta, zwężająca się smuga: warstwa skały, półka albo rysa."""
        rng = self.rng
        bend = rng.uniform(-.045, .045) * length if bend is None else bend
        dx, dy = math.cos(angle), math.sin(angle)
        count = 6
        top, bottom = [], []
        # Najgrubsza nie w połowie, tylko bliżej początku: smuga jak pociągnięcie pędzla.
        fat = rng.uniform(.22, .5)
        for i in range(count + 1):
            t = i / count
            cx = sx + dx * length * t - dy * bend * math.sin(math.pi * t)
            cy = sy + dy * length * t + dx * bend * math.sin(math.pi * t)
            env = t / fat if t < fat else (1 - t) / (1 - fat)
            th = width * env * rng.uniform(.55, 1.3)
            top.append((cx + dy * th * .5, cy - dx * th * .5))
            bottom.append((cx - dy * th * .5, cy + dx * th * .5))
        self.layer.add(self.inside(top + bottom[::-1][1:-1]), fill, opacity=opacity)

    def cluster(self, x, y, angle, h, fill, opacity=None):
        """Kilka niemal równoległych smug: pasmo warstw skalnych."""
        rng = self.rng
        for i in range(rng.randint(2, 5)):
            off = i * h * rng.uniform(.014, .034)
            self.spindle(
                x + math.sin(angle) * off + rng.uniform(-6, 6),
                y - math.cos(angle) * off,
                h * rng.uniform(.05, .17),
                angle + rng.uniform(-.07, .07),
                h * rng.uniform(.008, .022),
                fill,
                opacity=opacity,
            )

    def plane(self, cx, cy, w, h, fill, opacity=None):
        """Duża, kanciasta płaszczyzna skały o ściętych narożnikach."""
        rng = self.rng
        count = rng.randint(6, 9)
        pts = []
        start = rng.uniform(0, 6.28)
        for i in range(count):
            a = start + 2 * math.pi * i / count + rng.uniform(-.22, .22)
            r = rng.uniform(.68, 1.08)
            pts.append((cx + math.cos(a) * w * r, cy + math.sin(a) * h * r))
        self.layer.add(self.inside(pts), fill, opacity=opacity)

    def draw(self, snow=0.0, detail=1.0, sun=1):
        L, rng, h = self.layer, self.rng, self.h
        outline = [(self.lo, self.base)] + self.sky[1:-1] + [(self.hi, self.base)]
        L.add(outline, L.vgrad(self.top, self.base, [(0, self.tone(.34)), (.6, self.tone(.24)), (1, self.tone(.3))]))

        # Duże płaszczyzny: mały kontrast, budują bryłę.
        for _ in range(round(15 * detail)):
            px = rng.uniform(self.lo + self.half * .12, self.hi - self.half * .12)
            py = rng.uniform(self.sky_y(px) + h * .05, self.base - h * .04)
            self.plane(px, py, self.half * rng.uniform(.1, .32), h * rng.uniform(.05, .14), self.tone(rng.choice((.1, .18, .28, .42))), opacity=rng.uniform(.5, .85))

        for sx, sy, left, right in self.segments():
            far = left if sun > 0 else right
            near = right if sun > 0 else left
            run = self.base - sy
            # Cień od wierzchołka w dół: po stronie odwróconej od słońca, gaśnie ku podstawie.
            spine = chain(
                [(sx, sy), (sx + sun * self.half * .05, sy + run * .26),
                 (sx - sun * self.half * .06, sy + run * .54),
                 (sx + sun * self.half * rng.uniform(.02, .14), self.base - h * .1)],
                .08, rng, depth=2,
            )
            shade = self.inside(spine + [(far + sun * self.half * .1, self.base - h * .15), (far, self.sky_y(far))] +
                                [(x, self.sky_y(x)) for x in _span(far, sx, 10)])
            sh = self.tone(.04)
            L.add(shade, L.vgrad(sy, self.base, [(0, sh, .95), (.5, sh, .55), (1, sh, 0)]))

            # Żebra: długie smugi od grani w dół, rozchodzące się wachlarzem jak na referencji.
            for _ in range(round(16 * detail)):
                side = rng.choice((-1, 1))
                u = rng.uniform(.03, .95)
                px = sx + ((right - sx) if side > 0 else (sx - left)) * side * u
                ground = self.sky_y(px)
                py = ground + (self.base - ground) * rng.uniform(.02, .3)
                length = (self.base - py) * rng.uniform(.35, .8)
                deg = 90 - side * (rng.uniform(6, 20) + 30 * u)
                if side == sun and rng.random() < .55:
                    fill = self.tone(rng.choice((.5, .62, .78)))
                else:
                    fill = self.tone(rng.choice((.06, .12, .2)))
                self.spindle(px, py, length, math.radians(deg), h * rng.uniform(.018, .05), fill, bend=rng.uniform(-.1, .1) * length, opacity=rng.choice((.6, .75, .9)))

            # Rozświetlone płaszczyzny po stronie słońca, wysoko: tam skała jest najcieplejsza.
            for _ in range(round(2 * detail)):
                px = sx + (near - sx) * rng.uniform(.1, .9)
                ground = self.sky_y(px)
                py = ground + (self.base - ground) * rng.uniform(.04, .42)
                self.plane(px, py, self.half * rng.uniform(.07, .17), h * rng.uniform(.03, .08), self.tone(rng.choice((.62, .72, .84))), opacity=rng.choice((.45, .6, .7)))

            # Żleby: od grani w dół i na zewnątrz, po obu stronach.
            for _ in range(round(3 * detail)):
                t = rng.uniform(.08, .78)
                px = x_at_y(spine, sy + run * t) + rng.uniform(-.03, .03) * self.half
                py = sy + run * t
                side = rng.choice((-1, 1))
                ang = math.radians(rng.uniform(28, 74))
                self.spindle(px, py, h * rng.uniform(.12, .28), ang if side > 0 else math.pi - ang, h * rng.uniform(.016, .036), self.tone(rng.choice((0, .05, .1))), opacity=rng.uniform(.65, 1))

        # Warstwy skalne: pasma smug po obu stronach, gęstsze wysoko.
        for _ in range(round(11 * detail)):
            px = rng.uniform(self.lo + self.half * .08, self.hi - self.half * .08)
            ground = self.sky_y(px)
            py = ground + (self.base - ground) * rng.uniform(.03, .85) ** 1.5
            nearest = min(self.summits, key=lambda k: abs(k[0] - px))
            slope = 1 if px >= nearest[0] else -1  # kierunek opadania stoku
            on_sun = slope == sun
            deg = rng.uniform(10, 58)
            angle = math.radians(deg) if slope > 0 else math.pi - math.radians(deg)
            if on_sun and rng.random() < .3:
                fill = self.tone(rng.choice((.72, .84, .96)))
            elif on_sun:
                fill = self.tone(rng.choice((.06, .12, .2)))
            else:
                fill = self.tone(rng.choice((.0, .08, .16, .36)))
            self.cluster(px, py, angle, h, fill)

        # Światło przy krawędzi od słońca: nieregularne półki, nie równe zęby.
        for sx, sy, left, right in self.segments():
            near = right if sun > 0 else left
            xs = _rough_span(sx, near, 7, 34, rng)
            if len(xs) < 3:
                continue
            reach = rng.uniform(.45, .9)
            thick = min(self.half * rng.uniform(.07, .14), h * .12)
            edge, top_edge = [], []
            for i, x in enumerate(xs):
                t = abs(x - sx) / max(1, abs(near - sx))
                if t > reach:
                    break
                body = thick * math.sin(math.pi * min(1, t / reach) ** .5) ** .75
                d = body * rng.choice((.2, .35, .5, .75, 1.0, 1.3))
                edge.append((x - sun * d * rng.uniform(.5, 1.1), self.sky_y(x) + d * rng.uniform(.25, .75)))
                top_edge.append((x, self.sky_y(x)))
            if len(edge) >= 2:
                L.add(self.inside(top_edge + edge[::-1]), L.vgrad(sy, sy + (self.base - sy) * .7, [(0, self.tone(1.0)), (.7, self.tone(.8)), (1, self.tone(.6))]))
            # Półki wchodzące z jasnego pasa w ścianę.
            for _ in range(round(3 * detail)):
                x = rng.choice(xs)
                y = self.sky_y(x) + thick * rng.uniform(.1, 1.1)
                deg = rng.uniform(158, 200) if sun > 0 else rng.uniform(-20, 22)
                fill = self.tone(rng.choice((.2, .3, .9)))
                self.spindle(x, y, thick * rng.uniform(.8, 2.2), math.radians(deg), h * rng.uniform(.006, .018), fill)

        if snow > 0:
            self._snow(snow, sun)
        L.add(outline, L.vgrad(self.top + h * .42, self.base, [(0, VALLEY, 0), (1, VALLEY, .78 if self.depth > .15 else .42)]))

    def _snow(self, snow, sun):
        """Śnieg wysoko i nierówno: płaty przy grani, półki śnieżne, bez czapy z zębami."""
        L, rng, h = self.layer, self.rng, self.h
        white = '#F8F4EF'
        lit, shade = mat(white, 1.0, self.depth * .5), mat(white, .14, self.depth * .5)
        limit = self.top + h * snow
        for sx, sy, left, right in self.segments():
            if sy > limit - h * .04:
                continue
            for lo_x, hi_x, fill in ((sx, right, lit if sun > 0 else shade), (sx, left, shade if sun > 0 else lit)):
                xs = [x for x in _rough_span(lo_x, hi_x, 5, 30, rng) if self.sky_y(x) < limit]
                if len(xs) < 2:
                    continue
                edge = []
                for x in xs:
                    fade = 1 - (self.sky_y(x) - sy) / max(1, limit - sy)
                    d = h * snow * .46 * fade ** .55 * rng.choice((.12, .25, .4, .7, 1.0, 1.5))
                    edge.append((x + rng.uniform(-4, 4), self.sky_y(x) + d))
                L.add(self.inside([(x, self.sky_y(x)) for x in xs] + edge[::-1]), fill)
        # Półki śnieżne niżej: wąskie, ułożone wzdłuż warstw skały.
        segs = list(self.segments())
        for _ in range(10):
            sx, sy, left, right = rng.choice(segs)
            if sy > limit:
                continue
            x = rng.uniform(left, right)
            y = self.sky_y(x) + h * snow * rng.uniform(.25, 1.0)
            if y > limit + h * snow * .5:
                continue
            on_sun = (x > sx) == (sun > 0)
            deg = rng.uniform(8, 34)
            angle = math.radians(deg) if x > sx else math.pi - math.radians(deg)
            self.spindle(x, y, h * rng.uniform(.04, .13), angle, h * rng.uniform(.006, .014), lit if on_sun else shade)


def _span(a, b, step):
    """Wartości od a do b włącznie, co około `step`, w kierunku od a do b."""
    count = max(1, round(abs(b - a) / step))
    return [a + (b - a) * i / count for i in range(count + 1)]


def _rough_span(a, b, lo, hi, rng):
    """Jak `_span`, ale o nierównych odstępach: krawędzie nie wyglądają jak piła."""
    out = [a]
    sign = 1 if b >= a else -1
    x = a
    while True:
        x += sign * rng.uniform(lo, hi)
        if (x - b) * sign >= 0:
            break
        out.append(x)
    return out + [b]


def massif(layer, x, top, half, base, shape, rock, rng, depth=.25, snow=0.0, detail=1.0, sun=1):
    Massif(layer, x, top, half, base, shape, rock, rng, depth).draw(snow, detail, sun)


# ---------------------------------------------------------------- chmury


CLOUD = {
    # Od słońca do cienia: czapa, światło, cień u góry bryły, cień u podstawy.
    'cap': fixed('#FFEBD8', '#FFFFFF', '#FFE0B4', '#8E8DD2'),
    'light': fixed('#F9CFC8', '#F2F7FC', '#F8B39A', '#5F5DA8'),
    'shade0': fixed('#E0AABE', '#D6E3F0', '#D8849C', '#3F3D86'),
    'shade1': fixed('#AF93C6', '#B2C8E1', '#9C72B0', '#272662'),
    # Cienkie smugi.
    'wisp0': fixed('#E9B2C4', '#DCE9F4', '#E58FA6', '#34326F'),
    'wisp1': fixed('#B79CCB', '#BCD2E7', '#A77CB8', '#232258'),
}


def egg(cx, cy, rx, ry, rot=0.0, steps=14, peak_up=0.0, start=0.0, end=2 * math.pi):
    pts = []
    cr, sr = math.cos(rot), math.sin(rot)
    full = end - start >= 2 * math.pi - 1e-6
    for i in range(steps + (0 if full else 1)):
        a = start + (end - start) * i / steps
        x, y = math.cos(a) * rx, math.sin(a) * ry
        if y < 0:
            y *= 1 + peak_up * (1 - abs(x) / rx)
        pts.append((cx + x * cr - y * sr, cy + x * sr + y * cr))
    return pts


def billows(x0, x1, base, H, rng, crest, spread):
    """Kłęby jako okręgi trzech rozmiarów: duże niosą kształt, mniejsze siedzą na ich górze."""
    width = x1 - x0

    def env(u):
        return math.sin(math.pi * max(0, min(1, u))) ** .9 * math.exp(-((u - crest) / spread) ** 2)

    big = []
    u = rng.uniform(.03, .07)
    while u < .97:
        e = env(u)
        r = max(width * .04, min(H * .46, width * rng.uniform(.09, .16) * (.5 + .8 * e)))
        top = base - H * e * rng.uniform(.8, 1)
        big.append((x0 + width * u, min(top + r, base - r * .25), r))
        u += rng.uniform(.07, .13) * (1.25 - .5 * e)
    medium = []
    for cx, cy, r in big:
        for _ in range(rng.randint(1, 2)):
            a = math.radians(rng.uniform(-160, -20))
            d = r * rng.uniform(.72, 1)
            medium.append((cx + math.cos(a) * d, cy + math.sin(a) * d, r * rng.uniform(.3, .55)))
    small = []
    for cx, cy, r in medium:
        if rng.random() < .28:
            a = math.radians(rng.uniform(-170, -10))
            small.append((cx + math.cos(a) * r * .85, cy + math.sin(a) * r * .85, r * rng.uniform(.32, .5)))
    return big + medium + small, env


def _circle_top(circles, x, kx=0.0, ky=0.0):
    """Górna obwiednia okręgów; przesunięcie jest proporcjonalne do promienia każdego z nich."""
    best = math.inf
    for cx, cy, r in circles:
        d = x - (cx + kx * r)
        if abs(d) < r:
            best = min(best, cy + ky * r - math.sqrt(r * r - d * d))
    return best


def cumulus(layer, x0, x1, base, H, rng, crest=.5, spread=.42):
    """Jedna bryła: wspólny kontur, a światło to pasy pod konturem o wcięciach przy każdym kłębie."""
    circles, env = billows(x0, x1, base, H, rng, crest, spread)
    width = x1 - x0
    step = max(1.6, min(2.8, width / 110))
    x_lo = min(min(c[0] - c[2] for c in circles), x0)
    x_hi = max(max(c[0] + c[2] for c in circles), x1)
    xs = [x_lo + i * step for i in range(int((x_hi - x_lo) / step) + 1)] + [x_hi]
    outer = []
    for x in xs:
        core = base - H * env((x - x0) / width) * .5
        outer.append(min(core, _circle_top(circles, x), base))
    layer.add(list(zip(xs, outer)) + [(x_hi, base + 2), (x_lo, base + 2)],
              layer.vgrad(base - H, base, [(0, CLOUD['shade0']), (1, CLOUD['shade1'])]))
    # Słońce z prawej u góry: dolna krawędź światła to te same kłęby przesunięte w lewo i w dół.
    for kx, ky, depth, fill in ((-.4, 1.0, .5, CLOUD['light']), (-.2, .42, .24, CLOUD['cap'])):
        inner = []
        for x, top in zip(xs, outer):
            lower = _circle_top(circles, x, kx, ky)
            inner.append(max(top, min(lower, top + H * depth, base)))
        layer.add(list(zip(xs, outer)) + list(zip(xs, inner))[::-1], fill)


def comet(layer, x0, x1, y, th, fill, rng, bulge=None, sag=None):
    """Długie pasmo: jeden koniec tępy, drugi zwęża się w szpic, oś lekko faluje."""
    p = rng.uniform(.5, .8) if bulge is None else bulge
    sag = rng.uniform(-.25, .25) * th if sag is None else sag
    top, bottom = [], []
    steps = 30
    phi = rng.uniform(0, 6.28)
    for i in range(steps + 1):
        u = (1 - math.cos(math.pi * i / steps)) / 2
        env = math.sin(math.pi * u ** p) ** .8
        cy = y + sag * math.sin(math.pi * u * 2 + phi)
        x = x0 + (x1 - x0) * u
        top.append((x, cy - th * .55 * env * (1 + .1 * math.sin(u * 9 + phi))))
        bottom.append((x, cy + th * .45 * env * (1 + .14 * math.sin(u * 13 + phi * 2))))
    layer.add(top + bottom[::-1][1:-1], fill)


def cloud(layer, cx, base, w, h, rng, kind='massive'):
    """Chmura stoi na `base`. `kind`: massive – trzy bryły, tower – wysoka, bank – długa i niska,
    lumps – mały obłok. Bryły idą od tyłu, smugi zakrywają ich płaskie podstawy."""
    crest = rng.uniform(.38, .62)
    masses = {
        'massive': ((-.36, .34, 1, crest, .4), (-.52, .02, .54, .56, .42), (-.1, .52, .66, .44, .42), (-.28, .22, .36, .5, .44)),
        'tower': ((-.34, .32, 1, crest, .42), (-.5, .46, .5, .5, .44)),
        'bank': ((-.5, -.04, .66, .5, .42), (-.2, .26, 1, crest, .42), (.08, .5, .56, .5, .42)),
        'lumps': ((-.5, .5, 1, crest, .4),),
    }[kind]
    for u0, u1, tall, c, spread in masses:
        drop = (1 - tall) * h * .1
        cumulus(layer, cx + w * u0, cx + w * u1, base + drop, h * tall, rng, c, spread)
    th = max(3.5, h * .1)
    foot = layer.vgrad(base - th, base + th, [(0, CLOUD['shade1']), (1, CLOUD['wisp1'])])
    comet(layer, cx - w * .62, cx + w * .6, base + th * .2, th * 1.15, foot, rng, bulge=.72, sag=0)
    comet(layer, cx - w * .36, cx + w * .74, base + th * .95, th * .5, CLOUD['wisp0'], rng, bulge=.86)
    if kind != 'lumps':
        comet(layer, cx - w * .7, cx + w * .12, base + th * 1.5, th * .32, CLOUD['wisp1'], rng, bulge=.62)


def streak(layer, cx, cy, w, h, rng):
    """Same cienkie smugi: oddech między chmurami."""
    comet(layer, cx - w / 2, cx + w / 2, cy, h, layer.vgrad(cy - h, cy + h, [(0, CLOUD['wisp0']), (1, CLOUD['wisp1'])]), rng, bulge=rng.uniform(.6, .9))
    comet(layer, cx - w * .2, cx + w * .42, cy + h * .6, h * .42, CLOUD['wisp1'], rng)


# ---------------------------------------------------------------- teren i roślinność


def wave(w, base, terms):
    """Funkcja okresowa w `w`: suma (amplituda, całkowita liczba fal, faza)."""
    return lambda x: base + sum(a * math.sin(2 * math.pi * k * x / w + p) for a, k, p in terms)


def band(layer, f, bottom, fill, step=12):
    w = layer.w
    pts = [(x, f(x)) for x in range(-24, w + 25, step)]
    layer.add([(pts[0][0], bottom)] + pts + [(pts[-1][0], bottom)], fill)


def swathe(layer, f, x0, length, offset, thick, fill, rng):
    """Smuga światła albo cienia wzdłuż zbocza, zwężona na końcach."""
    steps = 10
    top, bottom = [], []
    wobble = rng.uniform(0, 6.28)
    for i in range(steps + 1):
        u = i / steps
        x = x0 + length * u
        env = math.sin(math.pi * u) ** 1.2
        y = f(x % layer.w) + offset + math.sin(u * 5 + wobble) * thick * 0.4
        top.append((x, y - thick * 0.5 * env))
        bottom.append((x, y + thick * 0.5 * env))
    layer.add(top + bottom[::-1][1:-1], fill, smooth=True)


def conifer_outline(x, base, h, rng, tiers=None, width=0.42):
    tiers = tiers or max(3, round(h / 15))
    left, right = [], []
    for i in range(tiers):
        u0 = i / tiers
        u1 = (i + 1) / tiers
        wide = h * width * u1 ** 0.92 * rng.uniform(0.88, 1.1)
        y1 = base - h + h * u1
        tuck = 0.48
        left += [(x - wide, y1 + h * 0.012), (x - wide * tuck, y1 - h * 0.018)]
        right += [(x + wide * rng.uniform(0.88, 1.08), y1 + h * 0.012), (x + wide * tuck, y1 - h * 0.018)]
    top = (x + rng.uniform(-0.5, 0.5), base - h)
    return top, left, right


def conifer(layer, x, base, h, rng, dark, lit, rim=None):
    """Świerk: sylwetka z piętrami, jasna strona, opcjonalny sierp światła."""
    top, left, right = conifer_outline(x, base, h, rng)
    layer.add([top] + right + [(x, base)] + left[::-1], dark)
    layer.add([top] + right + [(x + h * 0.03, base - h * 0.02)], lit)
    if rim:
        layer.add([top, right[0], right[1], (x + 0.5, base - h * 0.72)], rim)


def forest_band(layer, f, x0, x1, density, h0, h1, rng, dark, lit):
    x = x0
    while x < x1:
        h = rng.uniform(h0, h1) * (0.75 + 0.35 * math.sin(x * 0.019) ** 2)
        y = f(x % layer.w) + rng.uniform(1, 6)
        conifer(layer, x, y, h, rng, dark, lit)
        x += rng.uniform(0.4, 1.0) * density


def rock(layer, x, base, w, h, rng, tones):
    """Głaz o płaskich ścianach: sylwetka, górna płyta w świetle, pęknięcia."""
    outline = [
        (x - w * 0.5, base),
        (x - w * rng.uniform(0.44, 0.5), base - h * rng.uniform(0.3, 0.5)),
        (x - w * rng.uniform(0.2, 0.32), base - h * rng.uniform(0.85, 1.0)),
        (x + w * rng.uniform(0.02, 0.14), base - h),
        (x + w * rng.uniform(0.32, 0.42), base - h * rng.uniform(0.62, 0.8)),
        (x + w * 0.5, base),
    ]
    layer.add(outline, tones[0])
    layer.add([outline[2], outline[3], outline[4], (x + w * 0.1, base - h * 0.5), (x - w * 0.2, base - h * 0.55)], tones[2])
    layer.add([outline[1], outline[2], (x - w * 0.2, base - h * 0.55), (x - w * 0.14, base - h * 0.14), outline[0]], tones[1])
    for _ in range(3):
        gully(layer, (x + w * rng.uniform(-0.3, 0.3), base - h * rng.uniform(0.3, 0.75)), h * rng.uniform(0.18, 0.35), rng.uniform(-0.4, 0.4), h * 0.03, tones[0], rng, rough=0.1)


def grass(layer, x, base, h, count, spread, fill, rng):
    for _ in range(count):
        bx = x + rng.uniform(-spread, spread)
        bh = h * rng.uniform(0.45, 1.1)
        lean = rng.uniform(-0.45, 0.45) * bh
        w = rng.uniform(1.0, 2.2)
        layer.add(
            [(bx - w, base), (bx - w * 0.5 + lean * 0.4, base - bh * 0.55), (bx + lean, base - bh), (bx + w * 0.6 + lean * 0.4, base - bh * 0.5), (bx + w, base)],
            fill,
        )


def bush(layer, x, base, w, h, rng, tones):
    for i, tone in enumerate(tones):
        k = 1 - i * 0.22
        for j in range(4):
            u = (j + 0.5) / 4
            cx = x - w * 0.45 * k + w * 0.9 * k * u + (i * w * 0.05)
            env = math.sin(math.pi * u) ** 0.6
            layer.add(egg(cx, base - h * 0.42 * env - i * h * 0.1, w * 0.2 * k, h * 0.5 * env * k, steps=9), tone, smooth=True)


# ---------------------------------------------------------------- niebo


SKY = {
    'dawn': ['#5F76BF', '#9D8CC6', '#E0A5BE', '#F9C8A5', '#FBDDB2'],
    'day': ['#2F8FD9', '#5BB4E4', '#93D6E8', '#CBEBE5', '#EEF3D5'],
    'sunset': ['#8C78BC', '#AB86BC', '#D585A4', '#EB8C90', '#F29C86'],
    'night': ['#0E0E2E', '#1A1848', '#2E2565', '#4B3580', '#6A4590'],
}
# Natywne tło startowe: neutralny zmierzch, z którego przenika każda pora dnia.
LAUNCH_SKY = ['#7D74B4', '#B884AE', '#D98E9E']
SKY_W = 3000


def sky_layer(period):
    L = Layer(SKY_W)
    tok = [token({p: c for p in PERIODS}) for c in SKY[period]]
    stops = list(zip((0, 0.3, 0.55, 0.76, 1.0), tok))
    L.add([(0, 0), (SKY_W, 0), (SKY_W, SCENE_H), (0, SCENE_H)], L.vgrad(0, 800, stops))
    cx = SKY_W / 2
    rng = random.Random(f'sky-{period}')

    def disc(x, y, r, glow, glow_r, colors, glow_a=0.8):
        g, top, bottom = [token({p: c for p in PERIODS}) for c in (glow, *colors)]
        L.add(egg(x, y, glow_r, glow_r, steps=20), L.rgrad(x, y, glow_r, [(0, g, glow_a), (0.42, g, glow_a * 0.3), (1, g, 0)]), smooth=True)
        L.add(egg(x, y, r, r, steps=20), L.vgrad(y - r, y + r, [(0, top), (1, bottom)]), smooth=True)

    if period == 'sunset':
        disc(cx + 128, 556, 54, '#FFD58A', 300, ('#E4B24C', '#FFE9A6'))
    elif period == 'dawn':
        disc(cx + 128, 590, 48, '#FFE3B0', 300, ('#FFD9A0', '#FFF4D6'))
    elif period == 'day':
        disc(cx + 110, 176, 40, '#FFFBE0', 240, ('#FFF4B8', '#FFFBDC'), glow_a=0.65)
    else:
        star = token({p: '#F4F2E0' for p in PERIODS})
        dim = token({p: '#A4A6DC' for p in PERIODS})
        for i in range(260):
            x, y = rng.uniform(0, SKY_W), rng.uniform(0, 560)
            r = rng.uniform(0.7, 1.7) * (1 - y / 900)
            L.add([(x, y - r * 2), (x + r * 0.55, y - r * 0.55), (x + r * 2, y), (x + r * 0.55, y + r * 0.55), (x, y + r * 2), (x - r * 0.55, y + r * 0.55), (x - r * 2, y), (x - r * 0.55, y - r * 0.55)], star if i % 3 else dim)
        moon = token({p: '#EDE9D2' for p in PERIODS})
        mare = token({p: '#CFCBBC' for p in PERIODS})
        glow = token({p: '#8F8FE0' for p in PERIODS})
        mx, my = cx + 96, 184
        L.add(egg(mx, my, 200, 200, steps=20), L.rgrad(mx, my, 200, [(0, glow, 0.5), (1, glow, 0)]), smooth=True)
        L.add(egg(mx, my, 37, 37, steps=20), moon, smooth=True)
        for dx, dy, r in ((-13, -11, 8), (12, 6, 11), (-8, 15, 5), (15, -16, 4)):
            L.add(egg(mx + dx, my + dy, r, r * 0.86, steps=10), mare, smooth=True)
    return L


# ---------------------------------------------------------------- kamper


def camper_svgs():
    ink = camper('#1F2A2B')
    cream0, cream1 = camper('#FBF0D2'), camper('#EFDDB4')
    cream_d = camper('#E2C99B')
    green0, green1, green_d = camper('#5B8A70'), camper('#476F5B'), camper('#3A5C4C')
    coral, coral_d = camper('#EE9478'), camper('#DE7D66')
    stripe = camper('#E8A68C')
    glass0, glass1 = camper('#FAD9A8'), camper('#F3C592')
    tan, brick, brick_d = camper('#D9BFA0'), camper('#C87C62'), camper('#A9654F')
    metal0, metal1 = camper('#E8EEF0'), camper('#A8B4BA')
    lamp0, lamp1 = camper('#FBE3A4'), camper('#E7BC73')
    tyre, tyre_d = camper('#35594A'), camper('#223B33')
    well = camper('#16211F')

    def s(d, fill='none', sw=5.0, stroke=ink, extra=''):
        st = f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"' if sw else ''
        return f'<path d="{d}" fill="{fill}"{st}{extra}/>'

    def rr(x, y, w, h, r):
        return (
            f'M{x + r} {y}H{x + w - r}Q{x + w} {y} {x + w} {y + r}V{y + h - r}Q{x + w} {y + h} {x + w - r} {y + h}'
            f'H{x + r}Q{x} {y + h} {x} {y + h - r}V{y + r}Q{x} {y} {x + r} {y}Z'
        )

    defs = (
        f'<linearGradient id="green" gradientUnits="userSpaceOnUse" x1="0" y1="510" x2="0" y2="645"><stop offset="0" stop-color="{green0}"/><stop offset="0.72" stop-color="{green1}"/><stop offset="1" stop-color="{green_d}"/></linearGradient>'
        f'<linearGradient id="cream" gradientUnits="userSpaceOnUse" x1="0" y1="424" x2="0" y2="505"><stop offset="0" stop-color="{cream0}"/><stop offset="1" stop-color="{cream1}"/></linearGradient>'
        f'<linearGradient id="lid" gradientUnits="userSpaceOnUse" x1="430" y1="290" x2="450" y2="335"><stop offset="0" stop-color="{cream0}"/><stop offset="1" stop-color="{cream_d}"/></linearGradient>'
        f'<linearGradient id="tent" gradientUnits="userSpaceOnUse" x1="0" y1="285" x2="0" y2="400"><stop offset="0" stop-color="{coral_d}"/><stop offset="0.3" stop-color="{coral}"/><stop offset="1" stop-color="{coral}"/></linearGradient>'
        f'<linearGradient id="glass" gradientUnits="userSpaceOnUse" x1="0" y1="430" x2="0" y2="498"><stop offset="0" stop-color="{glass1}"/><stop offset="1" stop-color="{glass0}"/></linearGradient>'
        f'<linearGradient id="tentglass" gradientUnits="userSpaceOnUse" x1="0" y1="320" x2="0" y2="376"><stop offset="0" stop-color="{glass1}"/><stop offset="1" stop-color="{glass0}"/></linearGradient>'
    )
    W, H, X, Y = 620, 480, 215, 225
    head = lambda extra='': f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="{X} {Y} {W} {H}">{extra}'

    body = 'M272 424C262 446 255 480 252 500L250 512C250 560 251 600 252 628L304 628C306 612 318 607 331 607L388 607C403 607 413 626 420 643L612 643L620 643C622 612 645 592 671 592C700 592 722 605 731 624L811 624C814 600 812 575 807 553C802 530 797 510 789 492L752 426Z'
    belt_low = 'L605 510C650 510 720 510 755 521C777 528 795 540 806 557'
    green = f'M250 510{belt_low}C811 575 814 600 811 624L731 624C722 605 700 592 671 592C645 592 622 612 620 643L420 643C413 626 403 607 388 607L331 607C318 607 306 612 304 628L252 628C251 600 250 560 250 510Z'
    stripe_d = f'M252 500L605 500C650 500 716 500 758 510C780 516 797 530 804 546L806 557C795 540 777 528 755 521C720 510 650 510 605 510L250 510Z'

    p = [head(f'<defs>{defs}</defs>')]
    # Bagaże na relingu.
    p.append(s(rr(638, 312, 40, 26, 6), tan))
    p.append(s('M638 324H678', sw=4))
    p.append(s(rr(679, 315, 39, 66, 7), brick))
    p.append(s('M700 315V380M679 358H718', sw=4))
    p.append(s('M682 322H698V352H682Z', brick_d, sw=0, extra=' fill-opacity="0.35"'))
    p.append(s(rr(619, 335, 60, 46, 6), green1))
    p.append(s('M629 335V380M619 360H679', sw=4))
    p.append(s('M668 340H677V378H668Z', green_d, sw=0, extra=' fill-opacity="0.7"'))
    # Reling.
    p.append(s('M610 380V368Q610 361 617 361H720Q727 361 727 368V380', sw=4))
    # Deska i torba.
    p.append(s('M289 312C300 307 320 316 332 328L310 342C298 332 291 322 289 312Z', coral))
    p.append(s('M327 297C323 293 325 288 331 286L405 258C411 256 416 258 418 262L430 289L340 322Z', green1))
    p.append(s('M354 279L352 322', sw=4.5))
    p.append(s('M285 351C318 322 395 288 468 263C490 256 508 252 524 252L360 340Z', coral))
        # Namiot.
    p.append(s('M318 399L314 385L576 275C582 310 590 360 594 399Z', 'url(#tent)'))
    p.append(s('M326 399L342 373L368 399', sw=4))
    p.append(s('M410 374L540 320C546 318 551 320 552 326L556 366C556 371 553 374 548 374Z', 'url(#tentglass)', sw=4.5))
    # Klapa dachu.
    p.append(s('M290 391C291 375 297 362 306 353L574 240C582 236 588 238 590 244L595 257C596 261 594 263 590 265Z', 'url(#lid)'))
    p.append(s('M311 362L572 251', stroke=cream0, sw=3, extra=' stroke-opacity="0.9"'))
    # Dach.
    p.append(s('M272 424C280 410 292 403 310 402L724 402C745 404 758 412 766 424Z', cream0))
    # Nogi relingu i platforma.
    p.append(s('M623 391C618 400 617 412 618 424', stroke=tan, sw=6.5))
    p.append(s('M711 391C716 400 717 412 717 424', stroke=tan, sw=6.5))
    p.append(s(rr(603, 380, 133, 11, 5), tan, sw=4.5))
    # Nadwozie.
    p.append(s(body, 'url(#cream)', sw=0))
    p.append(s(green, 'url(#green)', sw=0))
    p.append(s(stripe_d, stripe, sw=0))
    # Cień pod progiem.
    p.append(s('M252 610L304 610L304 628L252 628ZM424 628L612 628L612 643L420 643Z', green_d, sw=0, extra=' fill-opacity="0.55"'))
    p.append(s(f'M250 510{belt_low}', sw=4.5))
    # Szyby z zasłonami.

    def window(x, y, w, h, left=True, right=True):
        out = [s(rr(x, y, w, h, 7), 'url(#glass)', sw=0)]
        if left:
            out.append(s(f'M{x + 2} {y + 2}H{x + w * 0.22}C{x + w * 0.2} {y + h * 0.35} {x + w * 0.08} {y + h * 0.55} {x + w * 0.11} {y + h * 0.62}C{x + w * 0.09} {y + h * 0.75} {x + w * 0.16} {y + h * 0.9} {x + w * 0.2} {y + h - 2}H{x + 2}Z', coral, sw=0))
        if right:
            out.append(s(f'M{x + w - 2} {y + 2}H{x + w * 0.78}C{x + w * 0.8} {y + h * 0.35} {x + w * 0.92} {y + h * 0.55} {x + w * 0.89} {y + h * 0.62}C{x + w * 0.91} {y + h * 0.75} {x + w * 0.84} {y + h * 0.9} {x + w * 0.8} {y + h - 2}H{x + w - 2}Z', coral, sw=0))
        out.append(s(rr(x, y, w, h, 7), sw=4.5))
        return ''.join(out)

    p.append(window(380, 436, 65, 59, right=False))
    p.append(window(468.5, 436, 124.5, 59))
    # Okno kabiny.
    p.append(s('M622 436L720 436L747 495L622 495C618 495 616 493 616 489L616 442C616 438 618 436 622 436Z', 'url(#glass)'))
    p.append(s('M621 438H639C640 454 630 466 631 472C632 480 637 488 640 493H621Z', coral, sw=0))
    p.append(s('M622 436L720 436L747 495L622 495C618 495 616 493 616 489L616 442C616 438 618 436 622 436Z', sw=4.5))
    # Elementy nad szybą kabiny: wspólne dla dnia i nocy, bo nocna nakładka leży nad nadwoziem.
    cab_divider = s('M697 438L717 494', sw=4)
    mirror = (
        s('M734 492C744 498 751 506 754 518', stroke=metal1, sw=5)
        + s('M728 468C722 468 720 477 720 484C720 493 723 502 729 502C735 502 737 493 737 484C737 477 734 468 728 468Z', metal0, sw=4.5)
    )
    p.append(cab_divider)
    # Przednia szyba.
    p.append(s('M735 428L752 428L787 492C780 495 772 496 766 495L733 436C732 432 733 429 735 428Z', 'url(#glass)', sw=4.5))
    # Drzwi i linie blach.
    p.append(s('M458 428V620Q458 631 469 631H593Q604 631 604 620V428', sw=4))
    p.append(s('M606 582H682C706 582 722 600 731 622', sw=4))
    p.append(s('M758 521C764 560 768 600 769 624', sw=4))
    p.append(s(rr(616, 530, 36, 11, 5), cream0, sw=4.5))
    # Kratka i klapka.
    for y in (522, 532.5, 543, 553.5, 564):
        p.append(s(f'M296 {y}H341', sw=3.6))
    p.append(s(rr(347, 527, 27, 29, 6), sw=4))
    # Lampy.
    p.append(s(rr(240.5, 577, 11, 32, 5), coral, sw=4.5))
    p.append(s('M787 544a7.5 7.5 0 1 0 -15 0a7.5 7.5 0 1 0 15 0Z', lamp1, sw=4))
    p.append(s('M800 564C786 564 781 575 781 585C781 596 787 606 800 606C812 606 816 596 816 585C816 574 812 564 800 564Z', metal0, sw=4.5))
    p.append(s('M803 568C795 570 790 577 790 585C790 594 795 601 803 602C811 600 814 593 814 585C814 577 811 570 803 568Z', lamp0, sw=2.5))
    # Lusterko.
    p.append(mirror)
    # Obrys całości i zderzaki.
    p.append(s(body))
    p.append(s('M272 424H766', sw=4.5))
    p.append(s(rr(238, 626, 51, 25, 11), cream0, sw=5))
    p.append(s(rr(729, 625, 92, 26, 12), cream0, sw=5))
    p.append(s('M736 645H813', stroke=cream_d, sw=3, extra=' stroke-opacity="0.8"'))
    p.append('</svg>')
    body_svg = ''.join(p)

    shadow = token({k: v for k, v in zip(PERIODS, ('#2A1E3A', '#1D3A2C', '#2A1630', '#05061A'))})
    under = (
        head(f'<defs><radialGradient id="sh" gradientUnits="userSpaceOnUse" cx="530" cy="690" r="330" gradientTransform="matrix(1 0 0 0.075 0 638)"><stop offset="0" stop-color="{shadow}" stop-opacity="0.72"/><stop offset="0.8" stop-color="{shadow}" stop-opacity="0.42"/><stop offset="1" stop-color="{shadow}" stop-opacity="0"/></radialGradient></defs>')
        + '<path d="M200 660H860V705H200Z" fill="url(#sh)"/>'
        + f'<path d="M304 628C306 612 318 607 331 607L388 607C403 607 413 626 420 643L304 643Z" fill="{well}"/>'
        + f'<path d="M620 643C622 612 645 592 671 592C700 592 722 605 731 624L731 640Z" fill="{well}"/>'
        + '</svg>'
    )

    # Koło: bez śrub i refleksu obrót byłby niewidoczny – kołpak w referencji jest symetryczny.
    r = 47.5
    bolts = ''.join(
        f'<circle cx="{10.5 * math.cos(a):.2f}" cy="{10.5 * math.sin(a):.2f}" r="2.3" fill="{ink}"/>'
        for a in (2 * math.pi * i / 5 - math.pi / 2 for i in range(5))
    )
    tread = ''.join(
        f'<path d="M{37 * math.cos(a):.2f} {37 * math.sin(a):.2f}L{43.5 * math.cos(a):.2f} {43.5 * math.sin(a):.2f}" stroke="{tyre}" stroke-width="3.2" stroke-linecap="round"/>'
        for a in (2 * math.pi * i / 10 for i in range(10))
    )
    wheel = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="-50 -50 100 100">'
        f'<defs><linearGradient id="hub" gradientUnits="userSpaceOnUse" x1="-12" y1="-14" x2="12" y2="14"><stop offset="0" stop-color="{metal0}"/><stop offset="1" stop-color="{metal1}"/></linearGradient></defs>'
        f'<circle r="{r - 2}" fill="{tyre_d}" stroke="{ink}" stroke-width="5"/>{tread}'
        f'<circle r="26" fill="{tan}" stroke="{ink}" stroke-width="4.5"/>'
        f'<circle r="17.5" fill="url(#hub)" stroke="{ink}" stroke-width="3.5"/>{bolts}'
        f'<path d="M-3 -14A14 14 0 0 1 10 -9L6 -6A9 9 0 0 0 -2 -9Z" fill="{cream0}"/>'
        f'</svg>'
    )

    # Noc: świecące okna i snop światła reflektora.
    warm, warm_hi = token({p: '#FFC56E' for p in PERIODS}), token({p: '#FFF0B8' for p in PERIODS})
    beam = token({p: '#FFE9A8' for p in PERIODS})
    def lit(d):
        return f'<path d="{d}" fill="url(#w)"/>'
    red, red_hot, red_glow = token({p: '#F2261C' for p in PERIODS}), token({p: '#FFB9A4' for p in PERIODS}), token({p: '#FF2A1C' for p in PERIODS})
    pad = NIGHT_PAD
    night_w = 1120 + pad
    night = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{night_w}" height="{H}" viewBox="{X - pad} {Y} {night_w} {H}"><defs>'
        f'<radialGradient id="r" gradientUnits="userSpaceOnUse" cx="246" cy="593" r="96"><stop offset="0" stop-color="{red_glow}" stop-opacity="0.72"/><stop offset="0.35" stop-color="{red_glow}" stop-opacity="0.28"/><stop offset="1" stop-color="{red_glow}" stop-opacity="0"/></radialGradient>'
        f'<linearGradient id="w" gradientUnits="userSpaceOnUse" x1="0" y1="432" x2="0" y2="498"><stop offset="0" stop-color="{warm_hi}"/><stop offset="1" stop-color="{warm}"/></linearGradient>'
        f'<linearGradient id="t" gradientUnits="userSpaceOnUse" x1="0" y1="318" x2="0" y2="376"><stop offset="0" stop-color="{warm_hi}"/><stop offset="1" stop-color="{warm}"/></linearGradient>'
        f'<linearGradient id="b" gradientUnits="userSpaceOnUse" x1="812" y1="0" x2="1330" y2="0"><stop offset="0" stop-color="{beam}" stop-opacity="0.72"/><stop offset="0.5" stop-color="{beam}" stop-opacity="0.2"/><stop offset="1" stop-color="{beam}" stop-opacity="0"/></linearGradient>'
        f'</defs>'
        + f'<path d="M812 572L1330 500V700L812 600Z" fill="url(#b)"/>'
        + '<path d="M150 493H342V693H150Z" fill="url(#r)"/>'
        + f'<path d="{rr(242.5, 579, 7, 28, 3.5)}" fill="{red}"/>'
        + f'<path d="{rr(244.5, 583, 3, 15, 1.5)}" fill="{red_hot}"/>'
        + lit(f'{rr(382.5, 438.5, 60, 54, 5)}{rr(471, 438.5, 119.5, 54, 5)}')
        + lit('M622 438.5L719 438.5L743 492.5L622 492.5C620 492.5 618.5 491 618.5 489L618.5 442C618.5 440 620 438.5 622 438.5Z')
        # Przednia szyba, wewnątrz jej obrysu.
        + lit('M736.5 430.5L750.6 430.5L783.6 490.9C778 492.8 771.5 493.5 767.4 492.7L735.2 435.6C734.7 433.4 735.3 431.3 736.5 430.5Z')
        + cab_divider
        + mirror
        + f'<path d="M415 372L540 322C545 320 549 322 550 326L553.5 366C553.5 370 551 371.5 548 371.5Z" fill="url(#t)"/>'
        + f'<path d="M803 569C796 571 791 578 791 585C791 593 796 600 803 601C810 599 813 592 813 585C813 578 810 571 803 569Z" fill="{warm_hi}"/>'
        + '</svg>'
    )

    # Obłok kurzu za autem (rysowany kilka razy, Flutter go przesuwa i wygasza).
    dust0, dust1 = camper('#E5D3AE'), camper('#BFA683')
    dust = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="80" height="50" viewBox="0 0 80 50"><defs>'
        f'<linearGradient id="d" gradientUnits="userSpaceOnUse" x1="0" y1="4" x2="0" y2="46"><stop offset="0" stop-color="{dust0}"/><stop offset="1" stop-color="{dust1}"/></linearGradient></defs>'
        f'<path d="M6 46C-2 46 -1 33 9 32C9 22 24 18 29 26C33 12 54 12 57 26C66 21 76 31 72 39C78 41 78 46 72 46Z" fill="url(#d)" stroke="{dust1}" stroke-width="2.5" stroke-linejoin="round"/></svg>'
    )
    return dict(camper_under=under, camper_wheel=wheel, camper_body=body_svg, camper_night=night, dust=dust)


NIGHT_PAD = 100  # o tyle obraz nocny wystaje za kampera z lewej: poświata tylnej lampy
CAMPER_BOX = dict(x=215, y=225, w=620, h=480, wheels=[(358, 641), (669, 641)], radius=47.5, ground=688.5, centerX=530, nightPad=NIGHT_PAD)


# ---------------------------------------------------------------- scena 1: Alpy


FG = fixed('#2C2440', '#123A30', '#2B1A33', '#080818')
FG_MID = fixed('#3C2F52', '#1B5040', '#3A2442', '#101028')
ROAD = dict(
    top=fixed('#6B5C72', '#6A6E72', '#5F4B62', '#20204A'),
    bottom=fixed('#4C4058', '#4B5258', '#42314A', '#14143A'),
    line=fixed('#EFD9B0', '#F4E9C6', '#E8C29A', '#6A689C'),
    edge=fixed('#A99A92', '#BFB9A3', '#94776F', '#3A3868'),
)
ROCK_TONES = (
    fixed('#40365A', '#3D4A58', '#3C2C4A', '#12122E'),
    fixed('#5E5275', '#5A6A78', '#57446B', '#1E1E48'),
    fixed('#8D7C99', '#8FA09F', '#8F7392', '#37366F'),
)


def road_layer(period_w, rng):
    L = Layer(period_w)
    top, edge_y = 854, 850
    L.add([(0, edge_y), (period_w, edge_y), (period_w, 945), (0, 945)], L.vgrad(edge_y, 930, [(0, ROAD['top']), (1, ROAD['bottom'])]))
    L.add([(0, edge_y - 2), (period_w, edge_y - 2), (period_w, top), (0, top)], ROAD['edge'])
    # Przerywana linia środkowa: pełna liczba kresek w okresie, bez skoku na szwie.
    dash, gap = 62, 62
    count = period_w // (dash + gap)
    pitch = period_w / count
    for i in range(count):
        x = i * pitch
        L.add([(x, 901), (x + dash, 901), (x + dash + 2, 905), (x + 2, 905)], ROAD['line'])
    # Drobne łaty asfaltu, żeby droga nie była jednolitym paskiem.
    for _ in range(16):
        x = rng.uniform(0, period_w)
        y = rng.uniform(860, 925)
        w = rng.uniform(30, 90)
        L.add([(x, y), (x + w, y), (x + w * 0.9, y + rng.uniform(1.5, 3)), (x + w * 0.1, y + 2)], ROAD['bottom'], opacity=0.55)
    return L


def front_layer(period_w, rng, extra=None):
    L = Layer(period_w)
    f = wave(period_w, 926, [(4, 3, 0.4), (2.5, 7, 1.7), (1.5, 13, 3.1)])
    band(L, f, SCENE_H, L.vgrad(915, 1000, [(0, FG_MID), (0.3, FG), (1, FG)]), step=16)
    x = 0
    while x < period_w:
        grass(L, x, f(x) + 3, rng.uniform(16, 38), rng.randint(6, 10), 22, FG, rng)
        x += rng.uniform(24, 52)
    for _ in range(46):
        x = rng.uniform(0, period_w)
        grass(L, x, f(x) + 18 + rng.uniform(0, 40), rng.uniform(10, 26), 5, 16, FG_MID, rng)
    # Głazy i kępy przy drodze.
    for x in (210, 640, 1140):
        rock(L, x, f(x) + 14, rng.uniform(84, 124), rng.uniform(44, 66), rng, ROCK_TONES)
        grass(L, x, f(x) + 16, 26, 12, 46, FG, rng)
    for x in (420, 900, 1330):
        bush(L, x, f(x) + 8, rng.uniform(80, 110), rng.uniform(36, 52), rng, (FG, FG_MID))
    # Łodygi z kwiatkami.
    for _ in range(26):
        x = rng.uniform(0, period_w)
        h = rng.uniform(22, 46)
        base = f(x) + 2
        lean = rng.uniform(-6, 6)
        L.add([(x - 0.9, base), (x + lean, base - h), (x + 0.9, base)], FG)
        L.add(egg(x + lean, base - h, 2.6, 2.6, steps=8), FG, smooth=True)
    if extra:
        extra(L, f)
    return L


def scene_alps():
    w_cloud, w_far, w_near, w_hill, w_tree, w_road, w_front = 2400, 2200, 1900, 2600, 1700, 1240, 1500
    rock_blue = '#8D8FB4'
    layers = []

    # Chmury: każda inna, jak w zaplanowanej kompozycji.
    rng = random.Random('alps-clouds')
    L = Layer(w_cloud)
    for cx, base, wc, hc, kind in (
        (1090, 372, 270, 138, 'massive'),
        (1068, 138, 138, 66, 'tower'),
        (1372, 432, 160, 44, 'bank'),
        (1720, 330, 290, 150, 'massive'),
        (1960, 150, 150, 74, 'tower'),
        (2210, 420, 220, 58, 'bank'),
        (480, 310, 300, 150, 'massive'),
        (220, 136, 150, 80, 'tower'),
        (740, 446, 170, 42, 'bank'),
        (150, 440, 110, 26, 'lumps'),
        (1530, 100, 96, 26, 'lumps'),
    ):
        cloud(L, cx, base, wc, hc, rng, kind)
    for cx, cy, wc, hc in ((1392, 74, 210, 7), (1238, 496, 170, 6), (820, 80, 230, 8), (2070, 66, 220, 7), (340, 510, 210, 8)):
        streak(L, cx, cy, wc, hc, rng)
    layers.append(('clouds', L, 5, 1200))

    # Dalekie pasmo: każdy masyw ma inny charakter, od kopuł po płaskie stoły.
    rng = random.Random('alps-far')
    L = Layer(w_far)
    H = 1100
    for x, top, half, shape, snow, detail in (
        (H + 900, 520, 300, 'ridge', 0.24, .75),
        (H - 880, 530, 320, 'hump', 0.0, .7),
        (H - 560, 462, 280, 'horn', 0.34, .85),
        (H + 660, 470, 270, 'cliff', 0.28, .85),
        (H + 360, 488, 270, 'table', 0.0, .9),
        (H - 118, 428, 330, 'broad', 0.17, 1.15),
    ):
        massif(L, x, top, half, 790, shape, rock_blue, rng, depth=0.24, snow=snow, detail=detail)
    layers.append(('far', L, 12, H))

    # Bliższe, ciemniejsze: niskie grzbiety i stoki, bez śniegu.
    rng = random.Random('alps-near')
    L = Layer(w_near)
    H = 950
    for x, top, half, shape, snow in (
        (H - 760, 628, 220, 'crag', 0.0),
        (H + 640, 620, 240, 'shoulder', 0.0),
        (H + 300, 640, 210, 'hump', 0.0),
        (H - 340, 646, 230, 'ridge', 0.0),
        (H + 60, 672, 190, 'crag', 0.0),
    ):
        massif(L, x, top, half, 816, shape, '#5E6A92', rng, depth=0.1, snow=snow, detail=.7)
    # Ciemny las u stóp grani.
    f = wave(w_near, 762, [(9, 2, 0.5), (6, 5, 1.4), (3, 11, 2.2)])
    dark, lit = mat('#1F5540', 0.3, 0.16), mat('#2F8052', 0.85, 0.14)
    band(L, f, 842, L.vgrad(742, 832, [(0, mat('#1F5540', 0.35, 0.16)), (1, mat('#2C6A48', 0.55, 0.08))]))
    forest_band(L, f, 0, w_near, 11, 24, 44, rng, dark, lit)
    layers.append(('near', L, 26, H))

    # Hala i dalsze świerki.
    rng = random.Random('alps-hills')
    L = Layer(w_hill)
    f = wave(w_hill, 800, [(14, 2, 0.3), (9, 3, 2.2), (5, 7, 0.9)])
    meadow = '#74B24A'
    band(L, f, 882, L.vgrad(772, 872, [(0, mat(meadow, 0.95, 0.1)), (1, mat(meadow, 0.62, 0.02))]))
    for _ in range(26):
        x = rng.uniform(0, w_hill)
        swathe(L, f, x, rng.uniform(120, 300), rng.uniform(10, 42), rng.uniform(5, 14), mat('#A8D65A', 1.0, 0.08), rng)
    for _ in range(14):
        x = rng.uniform(0, w_hill)
        swathe(L, f, x, rng.uniform(140, 320), rng.uniform(24, 56), rng.uniform(6, 13), mat(meadow, 0.2, 0.06), rng)
    dark, lit = mat('#245A40', 0.28, 0.1), mat('#3E8A52', 0.9, 0.08)
    for x0, x1 in ((120, 520), (820, 1040), (1500, 2000), (2300, 2520)):
        forest_band(L, f, x0, x1, 14, 26, 56, rng, dark, lit)
    layers.append(('hills', L, 54, 1300))

    # Bliska łąka z pojedynczymi świerkami sięgająca pobocza.
    rng = random.Random('alps-trees')
    L = Layer(w_tree)
    f = wave(w_tree, 834, [(8, 2, 1.1), (4, 5, 0.2), (2, 11, 2.0)])
    band(L, f, 872, L.vgrad(812, 862, [(0, mat('#7CC043', 1.0, 0.0)), (1, mat('#4E9A3C', 0.6, 0.0))]))
    for _ in range(18):
        swathe(L, f, rng.uniform(0, w_tree), rng.uniform(90, 200), rng.uniform(6, 18), rng.uniform(3, 7), mat('#C7E86A', 1.0, 0.0), rng)
    dark, lit, rim = mat('#1E5237', 0.28), mat('#2F7B46', 0.9), mat('#7CB95A', 1.0)
    groups = ((86, 3), (500, 3), (800, 5), (1260, 2), (1520, 3))
    for gx, count in groups:
        for i in range(count):
            x = gx + i * rng.uniform(24, 42) + rng.uniform(-8, 8)
            conifer(L, x, f(x % w_tree) + 3, rng.uniform(76, 142), rng, dark, lit, rim)
    for x in (300, 720, 1060, 1420):
        bush(L, x, f(x) + 4, rng.uniform(60, 96), rng.uniform(24, 38), rng, (mat('#245A3A', 0.3), mat('#3B8A4A', 0.8), mat('#74B24A', 1.0)))
    grass_tone = mat('#3E8A42', 0.6)
    for x in range(0, w_tree, 34):
        grass(L, x, f(x) + 1, rng.uniform(8, 16), 4, 16, grass_tone, rng)
    layers.append(('trees', L, 92, 300))

    rng = random.Random('alps-road')
    layers.append(('road', road_layer(w_road, rng), 170, 0))
    rng = random.Random('alps-front')
    layers.append(('front', front_layer(w_front, rng), 215, 0))
    return layers


SCENES = {'alps': scene_alps}

# ---------------------------------------------------------------- zapis i podgląd


def write(out):
    out.mkdir(parents=True, exist_ok=True)
    files = {}
    for name, svg in camper_svgs().items():
        files[f'{name}.svg'] = svg
    for period in PERIODS:
        files[f'sky_{period}.svg'] = sky_layer(period).render()
    scenes = []
    for i, (key, build) in enumerate(SCENES.items(), 1):
        folder = f'scene_{i:02d}'
        layers = []
        for name, layer, speed, start in build():
            files[f'{folder}/{name}.svg'] = layer.render()
            layers.append(dict(file=f'{folder}/{name}.svg', period=layer.w, speed=speed, start=start))
        scenes.append(dict(key=key, layers=layers))

    for rel, text in files.items():
        path = out / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    palette = {tok: dict(zip(PERIODS, key)) for key, tok in _tokens.items()}
    (out / 'palettes.json').write_text(json.dumps(palette, indent=0, sort_keys=True))
    manifest = dict(sceneHeight=SCENE_H, ground=GROUND, skyWidth=SKY_W, camperScale=CAMPER_SCALE, camper=CAMPER_BOX, launchSky=LAUNCH_SKY, scenes=scenes)
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=1))
    print(f'{len(files)} SVG, {sum(len(t) for t in files.values()) // 1024} KB, {len(palette)} tokenów')
    return files, palette


def recolor(text, palette, period):
    for tok, colors in palette.items():
        text = text.replace(tok, colors[period])
    return text


def inner(svg):
    """Zawartość SVG jako grupa z prefiksem id, żeby gradienty warstw się nie myliły."""
    return svg[svg.index('>') + 1: svg.rindex('</svg>')]


_uid = 0


def embed(svg, x, y, w, h, viewbox=None):
    global _uid
    _uid += 1
    prefix = f'u{_uid}_'
    body = inner(svg).replace('id="', f'id="{prefix}').replace('url(#', f'url(#{prefix}')
    head = svg[:svg.index('>')]
    vb = head[head.index('viewBox="') + 9:].split('"')[0] if viewbox is None else viewbox
    return f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{vb}">{body}</svg>'


def frame(files, palette, period, scene_idx, view_w, scroll=0.0):
    """Jedna klatka: pierwszy kadr sceny w szerokości `view_w` jednostek."""
    folder = f'scene_{scene_idx:02d}'
    key = list(SCENES)[scene_idx - 1]
    manifest = json.loads((OUT / 'manifest.json').read_text())
    scene = next(s for s in manifest['scenes'] if s['key'] == key)
    parts = []
    sky = recolor(files[f'sky_{period}.svg'], palette, period)
    parts.append(embed(sky, view_w / 2 - SKY_W / 2, 0, SKY_W + SEAM_OVERLAP, SCENE_H))

    def layer_svg(layer):
        svg = recolor(files[layer['file']], palette, period)
        p = layer['period']
        x = (layer['start'] - view_w / 2 + layer['speed'] * scroll) % p
        out = []
        tile = -x
        while tile < view_w:
            out.append(embed(svg, tile, 0, p + SEAM_OVERLAP, SCENE_H))
            tile += p
        return ''.join(out)

    for layer in scene['layers']:
        if layer['file'].endswith('front.svg'):
            continue
        parts.append(layer_svg(layer))

    s = CAMPER_SCALE
    box = CAMPER_BOX
    cx = view_w / 2 - (box['x'] + box['w'] / 2 - 15) * s
    cy = GROUND - box['ground'] * s
    def piece(name, wide=None):
        svg = recolor(files[f'{name}.svg'], palette, period)
        head = svg[:svg.index('>')]
        vw = float(head.split('width="')[1].split('"')[0])
        vh = float(head.split('height="')[1].split('"')[0])
        return embed(svg, cx + box['x'] * s, cy + box['y'] * s, vw * s, vh * s)
    parts.append(piece('camper_under'))
    wheel = recolor(files['camper_wheel.svg'], palette, period)
    for wx, wy in box['wheels']:
        parts.append(embed(wheel, cx + (wx - 50) * s, cy + (wy - 50) * s, 100 * s, 100 * s))
    parts.append(piece('camper_body'))
    if period == 'night':
        svg = recolor(files['camper_night.svg'], palette, period)
        head = svg[:svg.index('>')]
        vw = float(head.split('width="')[1].split('"')[0])
        vh = float(head.split('height="')[1].split('"')[0])
        parts.append(embed(svg, cx + (box['x'] - NIGHT_PAD) * s, cy + box['y'] * s, vw * s, vh * s))
    parts.append(layer_svg(next(l for l in scene['layers'] if l['file'].endswith('front.svg'))))
    return parts


def render_png(parts, view_w, view_h, css_w, css_h, png):
    # Scena kotwiczona u dołu: węższa wysokość ucina niebo.
    top = SCENE_H - view_h
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{css_w}" height="{css_h}" '
        f'viewBox="0 {top} {view_w} {view_h}" preserveAspectRatio="xMidYMax slice">' + ''.join(parts) + '</svg>'
    )
    html = png.with_suffix('.html')
    html.write_text(f'<!doctype html><html><body style="margin:0;background:#000">{svg}</body></html>')
    subprocess.run(
        [CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=2',
         f'--window-size={css_w},{css_h}', f'--screenshot={png}', html.as_uri()],
        check=True, capture_output=True,
    )
    html.unlink()


def preview(files, palette, folder):
    folder.mkdir(parents=True, exist_ok=True)
    for period in PERIODS:
        parts = frame(files, palette, period, 1, 461)
        render_png(parts, 461, 1000, 423, 917, folder / f'scene01_{period}.png')
    parts = frame(files, palette, 'sunset', 1, 1802)
    render_png(parts, 1802, 831, 917, 423, folder / 'scene01_sunset_wide.png')
    # Sam kamper na neutralnym tle, do porównania z referencją.
    svg = ''.join(
        [embed(files['camper_under.svg'], 215, 225, 620, 480)]
        + [embed(files['camper_wheel.svg'], x - 50, y - 50, 100, 100) for x, y in CAMPER_BOX['wheels']]
        + [embed(files['camper_body.svg'], 215, 225, 620, 480)]
    )
    render_png([recolor(svg, palette, 'day')], 1024, 1024, 512, 512, folder / 'camper.png')


OUT = None

if __name__ == '__main__':
    OUT = pathlib.Path(sys.argv[1])
    files_, palette_ = write(OUT)
    if '--preview' in sys.argv:
        preview(files_, palette_, pathlib.Path(sys.argv[sys.argv.index('--preview') + 1]))
