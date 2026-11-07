#!/usr/bin/env python3
"""Generates the 3D camper from resorces/screen.png as a GLB (glTF 2.0).

Run: python3 app/tool/camper_3d.py
Writes: resorces/camper_3d/camper.glb and preview.html (the model embedded in a
page with <model-viewer>, for rotating it in a browser).

Edit the model and the page here, never the outputs. Standard library only.

Conventions: Y up, metres, ground at y=0, centred on the car, front along +Z
(the glTF default), so the car's right side is at -X. That is the side visible
in the illustration. Each colour is one named material.

Geometry is read off the illustration through crop(): cx, cy are pixels of a 2x
crop of screen.png with its corner at (150, 220).

Dark outlines are inverted hulls: an inflated copy with flipped faces, which
back-face culling shows only around the silhouette. Windows and lines are
decals projected onto the body and lifted slightly along the surface normal.

Animations: "Jazda" spins the wheels in a loop, "Namiot" folds and raises the
tent once. The tent walls scale in Y by tan(angle) / tan(open angle), which keeps
their top edge exactly on the underside of the lid at every angle.
"""

import base64
import json
import math
import os
import struct
from collections import defaultdict

KPX = 0.004  # metres per crop pixel


def crop(cx, cy):
    """Crop pixel -> (z, y) in metres."""
    return ((cx - 762) * KPX, (938 - cy) * KPX)


def srgb(hex_colour):
    def channel(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    h = hex_colour.lstrip("#")
    return [round(channel(int(h[i : i + 2], 16)), 5) for i in (0, 2, 4)] + [1.0]


MATERIALS = {
    "zielen": ("#547C65", 0.85),
    "krem": ("#F4E5C5", 0.85),
    "koral": ("#EC896C", 0.85),
    "brzoskwinia": ("#F2CFA4", 0.6),
    "kontur": ("#1B1A18", 0.9),
    "opona": ("#3E5247", 0.95),
    "felga": ("#EBD5BE", 0.6),
    "kolpak": ("#BCC9CF", 0.35),
    "zderzak": ("#F1DFBE", 0.7),
    "reflektor": ("#E5BD82", 0.4),
    "swiatlo_tyl": ("#C28273", 0.6),
    "zielen_bagaz": ("#61816C", 0.85),
    "walizka_jasna": ("#D5BFA8", 0.85),
    "walizka_braz": ("#AA7D6A", 0.85),
}
UNLIT = {"kontur"}

# Vectors ------------------------------------------------------------------


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def mul(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def unit(a):
    n = math.sqrt(dot(a, a))
    return (0.0, 1.0, 0.0) if n < 1e-12 else (a[0] / n, a[1] / n, a[2] / n)


def face_normal(t):
    return cross(sub(t[1], t[0]), sub(t[2], t[0]))


def key(p):
    return (round(p[0], 4), round(p[1], 4), round(p[2], 4))


# Solids: lists of triangles (p0, p1, p2) wound outwards --------------------


def orient_outward(tris):
    volume = sum(dot(t[0], cross(t[1], t[2])) for t in tris)
    return tris if volume >= 0 else [(t[0], t[2], t[1]) for t in tris]


def loft(rings, cap_start=True, cap_end=True):
    """Skins rings of equal length into a closed solid."""
    tris = []
    n = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for j in range(n):
            k = (j + 1) % n
            tris.append((a[j], a[k], b[k]))
            tris.append((a[j], b[k], b[j]))

    def cap(ring, flip):
        c = mul(tuple(map(sum, zip(*ring))), 1 / len(ring))
        for j in range(n):
            k = (j + 1) % n
            tris.append((c, ring[k], ring[j]) if flip else (c, ring[j], ring[k]))

    if cap_start:
        cap(rings[0], True)
    if cap_end:
        cap(rings[-1], False)
    tris = [t for t in tris if dot(face_normal(t), face_normal(t)) > 1e-14]
    return orient_outward(tris)


def rounded_rect(hu, hv, r, corner=2):
    """Rounded rectangle centred at 0, 4 * (corner + 1) points."""
    r = min(r, hu - 1e-4, hv - 1e-4)
    pts = []
    for su, sv, start in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        for i in range(corner + 1):
            a = math.radians(start + 90 * i / corner)
            pts.append((su * (hu - r) + r * math.cos(a), sv * (hv - r) + r * math.sin(a)))
    return pts


def rbox(x0, x1, y0, y1, z0, z1, r=0.03, corner=2, rows=2):
    """Box with rounded plan corners and bevelled top and bottom."""
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    hx, hz = (x1 - x0) / 2, (z1 - z0) / 2
    r = min(r, hx * 0.95, hz * 0.95, (y1 - y0) / 2 * 0.95)
    lower = []
    for i in range(rows, -1, -1):
        a = math.pi / 2 * i / rows
        lower.append((y0 + r * (1 - math.sin(a)), r * (1 - math.cos(a))))
    profile = lower + [(y1 - (y - y0), inset) for y, inset in reversed(lower)]
    rings = []
    for y, inset in profile:
        plan = rounded_rect(hx - inset, hz - inset, max(r - inset, 1e-3), corner)
        rings.append([(cx + u, y, cz + v) for u, v in plan])
    return loft(rings)


def extrude_x(poly, x0, x1):
    """Extrudes a (z, y) polygon along X."""
    tris = []
    n = len(poly)
    for i in range(n):
        a, b = poly[i], poly[(i + 1) % n]
        tris.append(((x0, a[1], a[0]), (x1, a[1], a[0]), (x1, b[1], b[0])))
        tris.append(((x0, a[1], a[0]), (x1, b[1], b[0]), (x0, b[1], b[0])))
    for a, b, c in earclip(poly):
        tris.append(((x0, a[1], a[0]), (x0, b[1], b[0]), (x0, c[1], c[0])))
        tris.append(((x1, a[1], a[0]), (x1, c[1], c[0]), (x1, b[1], b[0])))
    return orient_outward(tris)


def tube(p0, p1, r, sides=6):
    d = unit(sub(p1, p0))
    u = unit(cross(d, (0.0, 0.0, 1.0) if abs(d[2]) < 0.9 else (1.0, 0.0, 0.0)))
    v = cross(d, u)
    circle = []
    for i in range(sides):
        a = 2 * math.pi * i / sides
        circle.append(add(mul(u, r * math.cos(a)), mul(v, r * math.sin(a))))
    return loft([[add(p0, c) for c in circle], [add(p1, c) for c in circle]])


def ellipsoid(c, rx, ry, rz, segs=10, rows=6):
    rings = []
    for i in range(1, rows):
        a = math.pi * i / rows
        ring = []
        for j in range(segs):
            b = 2 * math.pi * j / segs
            ring.append(
                (
                    c[0] + rx * math.sin(a) * math.cos(b),
                    c[1] + ry * math.cos(a),
                    c[2] + rz * math.sin(a) * math.sin(b),
                )
            )
        rings.append(ring)
    return loft(rings)


def lathe(profile, axis, center, segs):
    """Revolves (radius, axial) points around axis 'x' or 'z'."""
    rings = []
    for r, a in profile:
        ring = []
        for j in range(segs):
            b = 2 * math.pi * j / segs
            u, v = r * math.cos(b), r * math.sin(b)
            offset = (a, u, v) if axis == "x" else (u, v, a)
            ring.append(add(center, offset))
        rings.append(ring)
    return loft(rings)


def sweep(path, hu, hv, y, r):
    """Sweeps a rounded section along a (x, z) path, with bevelled ends."""
    section = rounded_rect(hu, hv, r, corner=1)
    rings = []
    last = len(path) - 1
    for i, p in enumerate(path):
        a, b = path[max(i - 1, 0)], path[min(i + 1, last)]
        tx, tz = unit((b[0] - a[0], 0, b[1] - a[1]))[0], unit((b[0] - a[0], 0, b[1] - a[1]))[2]
        nx, nz = tz, -tx
        scale = 0.55 if i in (0, last) else 1.0
        rings.append(
            [(p[0] + nx * u * scale, y + v * scale, p[1] + nz * u * scale) for u, v in section]
        )
    return loft(rings)


# Shading -------------------------------------------------------------------


def shade(tris, crease=50):
    """Per-corner normals: area-weighted, smoothed below the crease angle."""
    cos_crease = math.cos(math.radians(crease))
    normals = [face_normal(t) for t in tris]
    units = [unit(n) for n in normals]
    at = defaultdict(list)
    for i, t in enumerate(tris):
        for p in t:
            at[key(p)].append(i)
    out = []
    for i, t in enumerate(tris):
        corners = []
        for p in t:
            total = (0.0, 0.0, 0.0)
            for j in at[key(p)]:
                if dot(units[i], units[j]) >= cos_crease:
                    total = add(total, normals[j])
            corners.append((p, unit(total)))
        out.append(tuple(corners))
    return out


def inflate(tris, d):
    """Inverted hull: pushes vertices out along averaged normals, flips faces."""
    normals = defaultdict(lambda: (0.0, 0.0, 0.0))
    for t in tris:
        n = unit(face_normal(t))
        for p in t:
            normals[key(p)] = add(normals[key(p)], n)
    moved = lambda p: add(p, mul(unit(normals[key(p)]), d))
    return [(moved(t[0]), moved(t[2]), moved(t[1])) for t in tris]


def clip(shaded, field):
    """Splits shaded triangles along field(p) == 0, interpolating normals."""
    out = []

    def mix(a, b, fa, fb):
        s = fa / (fa - fb)
        p = add(a[0], mul(sub(b[0], a[0]), s))
        return (p, unit(add(mul(a[1], 1 - s), mul(b[1], s))))

    for t in shaded:
        f = [field(c[0]) for c in t]
        inside = [v >= 0 for v in f]
        if all(inside) or not any(inside):
            out.append(t)
            continue
        lone = inside.index(sum(inside) == 1)
        a, b, c = t[lone], t[(lone + 1) % 3], t[(lone + 2) % 3]
        fa, fb, fc = f[lone], f[(lone + 1) % 3], f[(lone + 2) % 3]
        ab, ac = mix(a, b, fa, fb), mix(a, c, fa, fc)
        out += [(a, ab, ac), (ab, b, c), (ab, c, ac)]
    return out


# 2D polygons ---------------------------------------------------------------


def area2(poly):
    return sum(
        poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1]
        for i in range(len(poly))
    )


def ccw(poly):
    return poly if area2(poly) > 0 else poly[::-1]


def earclip(poly):
    poly = ccw(list(poly))
    idx = list(range(len(poly)))
    out = []

    def cross2(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1
        for i in range(len(idx)):
            pi, ci, ni = idx[i - 1], idx[i], idx[(i + 1) % len(idx)]
            a, b, c = poly[pi], poly[ci], poly[ni]
            if cross2(a, b, c) <= 1e-12:
                continue
            if any(
                cross2(a, b, poly[j]) >= 0 and cross2(b, c, poly[j]) >= 0 and cross2(c, a, poly[j]) >= 0
                for j in idx
                if j not in (pi, ci, ni)
            ):
                continue
            out.append((a, b, c))
            idx.pop(i)
            break
        else:
            idx.pop(0)  # only collinear points remain
    if len(idx) == 3:
        out.append(tuple(poly[j] for j in idx))
    return out


def round_poly(poly, r, n=2):
    out = []
    m = len(poly)
    for i in range(m):
        a, b, c = poly[i - 1], poly[i], poly[(i + 1) % m]
        la, lc = math.dist(a, b), math.dist(c, b)
        d = min(r, la / 2, lc / 2)
        p0 = (b[0] + (a[0] - b[0]) * d / la, b[1] + (a[1] - b[1]) * d / la)
        p1 = (b[0] + (c[0] - b[0]) * d / lc, b[1] + (c[1] - b[1]) * d / lc)
        for k in range(n + 1):
            s = k / n
            out.append(
                (
                    (1 - s) ** 2 * p0[0] + 2 * s * (1 - s) * b[0] + s**2 * p1[0],
                    (1 - s) ** 2 * p0[1] + 2 * s * (1 - s) * b[1] + s**2 * p1[1],
                )
            )
    return out


def rrect2(u0, v0, u1, v1, r):
    u0, u1 = min(u0, u1), max(u0, u1)
    v0, v1 = min(v0, v1), max(v0, v1)
    return round_poly([(u0, v0), (u1, v0), (u1, v1), (u0, v1)], r)


def circle2(cu, cv, r, n=12):
    return [
        (cu + r * math.cos(2 * math.pi * i / n), cv + r * math.sin(2 * math.pi * i / n))
        for i in range(n)
    ]


def grow(poly, d):
    """Offsets a polygon outwards by d."""
    poly = ccw(poly)
    out = []
    m = len(poly)
    for i in range(m):
        a, b, c = poly[i - 1], poly[i], poly[(i + 1) % m]
        n1 = unit((b[1] - a[1], -(b[0] - a[0]), 0))
        n2 = unit((c[1] - b[1], -(c[0] - b[0]), 0))
        n = unit((n1[0] + n2[0], n1[1] + n2[1], 0))
        miter = d / max(dot(n, n1), 0.4)
        out.append((b[0] + n[0] * miter, b[1] + n[1] * miter))
    return out


def smooth_path(pts, r, n=2):
    """Open polyline with filleted inner corners."""
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = pts[i - 1], pts[i], pts[i + 1]
        la, lc = math.dist(a, b), math.dist(c, b)
        d = min(r, la / 2, lc / 2)
        p0 = (b[0] + (a[0] - b[0]) * d / la, b[1] + (a[1] - b[1]) * d / la)
        p1 = (b[0] + (c[0] - b[0]) * d / lc, b[1] + (c[1] - b[1]) * d / lc)
        for k in range(n + 1):
            s = k / n
            out.append(
                (
                    (1 - s) ** 2 * p0[0] + 2 * s * (1 - s) * b[0] + s**2 * p1[0],
                    (1 - s) ** 2 * p0[1] + 2 * s * (1 - s) * b[1] + s**2 * p1[1],
                )
            )
    out.append(pts[-1])
    return out


def stroke_tris(path, width, closed=False):
    pts = path + [path[0]] if closed else path
    h = width / 2
    left, right = [], []
    for i, p in enumerate(pts):
        a, b = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
        if closed and i in (0, len(pts) - 1):
            a, b = path[-1], path[1]
        t = unit((b[0] - a[0], b[1] - a[1], 0))
        left.append((p[0] - t[1] * h, p[1] + t[0] * h))
        right.append((p[0] + t[1] * h, p[1] - t[0] * h))
    tris = []
    for i in range(len(pts) - 1):
        tris.append((left[i], right[i], right[i + 1]))
        tris.append((left[i], right[i + 1], left[i + 1]))
    return tris


def subdivide(tri, limit):
    a, b, c = tri
    ab = math.dist(a, b) > limit
    bc = math.dist(b, c) > limit
    ca = math.dist(c, a) > limit
    mid = lambda p, q: ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
    if not (ab or bc or ca):
        return [tri]
    if ab and bc and ca:
        d, e, f = mid(a, b), mid(b, c), mid(c, a)
        parts = [(a, d, f), (d, b, e), (f, e, c), (d, e, f)]
    elif ab and bc:
        d, e = mid(a, b), mid(b, c)
        parts = [(d, b, e), (a, d, e), (a, e, c)]
    elif bc and ca:
        e, f = mid(b, c), mid(c, a)
        parts = [(e, c, f), (b, e, f), (b, f, a)]
    elif ca and ab:
        f, d = mid(c, a), mid(a, b)
        parts = [(f, a, d), (c, f, d), (c, d, b)]
    elif ab:
        d = mid(a, b)
        parts = [(a, d, c), (d, b, c)]
    elif bc:
        e = mid(b, c)
        parts = [(a, b, e), (a, e, c)]
    else:
        f = mid(c, a)
        parts = [(a, b, f), (f, b, c)]
    return [s for p in parts for s in subdivide(p, limit)]


# Decals --------------------------------------------------------------------


class Projector:
    """Finds the outermost point of a solid along an axis, for a (u, v) in the plane."""

    CELL = 0.1

    def __init__(self, tris, axis, sign, limit=0.16):
        self.tris = tris
        self.limit = limit  # longest decal edge; flat surfaces can take long ones
        self.axis = axis
        self.sign = sign
        self.u = 2 if axis == 0 else 0
        self.bins = defaultdict(list)
        for t in tris:
            n = unit(face_normal(t))
            if n[axis] * sign < 1e-4:
                continue
            us = [p[self.u] for p in t]
            vs = [p[1] for p in t]
            for i in range(int(min(us) // self.CELL), int(max(us) // self.CELL) + 1):
                for j in range(int(min(vs) // self.CELL), int(max(vs) // self.CELL) + 1):
                    self.bins[(i, j)].append((t, n))

    def _ray(self, u, v):
        best = None
        for t, n in self.bins.get((int(u // self.CELL), int(v // self.CELL)), ()):
            a, b, c = t
            ax, ay, bx, by, cx, cy = a[self.u], a[1], b[self.u], b[1], c[self.u], c[1]
            det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(det) < 1e-12:
                continue
            l0 = ((by - cy) * (u - cx) + (cx - bx) * (v - cy)) / det
            l1 = ((cy - ay) * (u - cx) + (ax - cx) * (v - cy)) / det
            l2 = 1 - l0 - l1
            if min(l0, l1, l2) < -1e-6:
                continue
            w = l0 * a[self.axis] + l1 * b[self.axis] + l2 * c[self.axis]
            if best is None or w * self.sign > best[0] * self.sign:
                best = (w, n)
        return best

    def hit(self, u, v, center, lift):
        """Surface point lifted along its normal; slides towards center past an edge."""
        for step in range(60):
            s = min(step * 0.012 / max(math.dist((u, v), center), 1e-6), 1.0)
            uu, vv = u + (center[0] - u) * s, v + (center[1] - v) * s
            found = self._ray(uu, vv)
            if found:
                w, n = found
                p = [0.0, vv, 0.0]
                p[self.axis] = w
                p[self.u] = uu
                return add(tuple(p), mul(n, lift))
        raise ValueError(f"decal misses the solid at {u:.3f}, {v:.3f}")


# Parts: one node each ------------------------------------------------------


class Part:
    def __init__(self, name, translation=None, rotation=None, parent=None):
        self.name = name
        self.translation = translation
        self.rotation = rotation
        self.parent = parent
        self.prims = defaultdict(list)

    def solid(self, mat, tris, outline=0.0, crease=50):
        self.prims[mat] += shade(tris, crease)
        if outline:
            self.prims["kontur"] += shade(inflate(tris, outline), 180)

    def decal(self, proj, mat, poly, lift):
        poly = ccw(poly)
        self.decal_tris(proj, mat, earclip(poly), lift)

    def stroke(self, proj, mat, path, width, lift, closed=False):
        self.decal_tris(proj, mat, stroke_tris(path, width, closed), lift)

    def decal_tris(self, proj, mat, tris2, lift):
        pts = [p for t in tris2 for p in t]
        center = (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))
        seen = {}

        def lifted(p):
            k = (round(p[0], 5), round(p[1], 5))
            if k not in seen:
                seen[k] = proj.hit(p[0], p[1], center, lift)
            return seen[k]

        out = []
        for t in tris2:
            for s in subdivide(t, proj.limit):
                a, b, c = lifted(s[0]), lifted(s[1]), lifted(s[2])
                f = (a, b, c)
                if dot(face_normal(f), face_normal(f)) < 1e-14:
                    continue
                if face_normal(f)[proj.axis] * proj.sign < 0:
                    f = (a, c, b)
                out.append(f)
        self.prims[mat] += shade(out, 60)


# Body ----------------------------------------------------------------------

W = 0.88
WHEEL_R = 0.36
WHEEL_X = 0.78
ARCH_R = 0.43
Z_REAR_WHEEL = crop(415, 0)[0]
Z_FRONT_WHEEL = crop(1040, 0)[0]


def interp(pts, x):
    if x <= pts[0][0]:
        return pts[0][1]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return pts[-1][1]


Z_MIN, Z_MAX = crop(205, 0)[0], crop(1320, 0)[0]
BODY_TOP = 2.13
TOP_PROFILE = [
    (Z_MIN, 1.432),
    (-2.188, 1.752),
    (-2.13, 1.95),
    (-2.048, BODY_TOP),
    (1.752, BODY_TOP),
    (2.072, 1.572),
    (2.18, 1.2),
    (Z_MAX, 0.952),
]
BOTTOM_PROFILE = [(Z_MIN, 0.512), (-1.85, 0.41), (-1.82, 0.352), (1.54, 0.352), (1.632, 0.512), (Z_MAX, 0.512)]


def body_bottom(z):
    y = interp(BOTTOM_PROFILE, z)
    for zc in (Z_REAR_WHEEL, Z_FRONT_WHEEL):
        d = z - zc
        if abs(d) < ARCH_R:
            y = max(y, WHEEL_R + math.sqrt(ARCH_R * ARCH_R - d * d))
    return y


def body_halfwidth(z):
    if z > 1.35:
        t = min((z - 1.35) / (Z_MAX - 1.35), 1.0)
        return W * (0.62 + 0.38 * (1 - t**3.2) ** (1 / 3.2))
    if z < -1.9:
        t = min((-1.9 - z) / (-1.9 - Z_MIN), 1.0)
        return W * (0.72 + 0.28 * (1 - t**3) ** (1 / 3))
    return W


def taper(y):
    return 1.0 if y < 0.9 else 1 - 0.12 * ((y - 0.9) / (BODY_TOP - 0.9)) ** 2


def spow(v, e):
    return math.copysign(abs(v) ** e, v)


def body_solid(ring_pts=24):
    stations = {Z_MIN, -2.188, -2.13, -2.048, -1.95, -1.85, -0.75, -0.3, 0.15, 0.5}
    stations |= {1.632, 1.752, 1.86, 1.96, 2.072, 2.13, 2.18, Z_MAX}
    for zc in (Z_REAR_WHEEL, Z_FRONT_WHEEL):
        for i in range(11):
            stations.add(zc - ARCH_R * math.cos(math.pi * i / 10))
    rings = []
    for z in sorted(stations):
        top, bottom = interp(TOP_PROFILE, z), body_bottom(z)
        cy, h, w = (top + bottom) / 2, (top - bottom) / 2, body_halfwidth(z)
        ring = []
        for k in range(ring_pts):
            a = 2 * math.pi * k / ring_pts
            y = cy + h * spow(math.sin(a), 0.4)
            ring.append((w * taper(y) * spow(math.cos(a), 0.4), y, z))
        rings.append(ring)
    return loft(rings)


BELT_TOP = [(-3.0, 1.512), (1.35, 1.512), (1.75, 1.40), (2.19, 1.03), (3.0, 0.95)]
STRIPE = 0.08
LINE = 0.018
UNDERSIDE = 0.86  # the underside is dark inside this fraction of the half-width


def belt_top(x, z):
    y = interp(BELT_TOP, z)
    if z > 1.75:
        k = (z - 1.75) / (Z_MAX - 1.75)
        y -= k * 0.35 * max(0.0, 1 - abs(x) / 0.72)
    return y


def add_body_paint(part, tris):
    shaded = shade(tris, 60)
    shaded = clip(shaded, lambda p: p[1] - belt_top(p[0], p[2]))
    shaded = clip(shaded, lambda p: p[1] - belt_top(p[0], p[2]) + STRIPE)
    shaded = clip(shaded, lambda p: p[1] - belt_top(p[0], p[2]) + STRIPE + LINE)
    shaded = clip(shaded, lambda p: abs(p[0]) - UNDERSIDE * body_halfwidth(p[2]))
    for t in shaded:
        c = mul(add(add(t[0][0], t[1][0]), t[2][0]), 1 / 3)
        n = unit(face_normal((t[0][0], t[1][0], t[2][0])))
        d = c[1] - belt_top(c[0], c[2])
        if n[1] < -0.3 and abs(c[0]) < UNDERSIDE * body_halfwidth(c[2]):
            mat = "kontur"
        elif d >= 0:
            mat = "krem"
        elif d >= -STRIPE:
            mat = "koral"
        elif d >= -STRIPE - LINE:
            mat = "kontur"
        else:
            mat = "zielen"
        part.prims[mat].append(t)


def poly_crop(*pts):
    return [crop(*p) for p in pts]


CURTAINS = [
    poly_crop((640, 435), (695, 435), (690, 470), (662, 505), (672, 545), (640, 545)),
    poly_crop((883, 435), (825, 435), (835, 470), (862, 505), (850, 545), (883, 545)),
    poly_crop((463, 435), (520, 435), (510, 475), (485, 505), (495, 545), (463, 545)),
    poly_crop((935, 435), (985, 435), (975, 470), (960, 500), (990, 545), (935, 545)),
]
WINDOWS = [
    rrect2(*crop(458, 430), *crop(590, 550), 0.06),
    rrect2(*crop(635, 430), *crop(888, 550), 0.06),
    round_poly(poly_crop((930, 430), (1096, 430), (1136, 548), (930, 548)), 0.06),
    round_poly(poly_crop((1110, 432), (1145, 432), (1203, 548), (1150, 548)), 0.05),
]
PANEL_LINE = 0.024
LIFT_DARK, LIFT_FILL, LIFT_TOP = 0.010, 0.016, 0.022


def add_side(part, proj, sliding_door):
    for w in WINDOWS:
        part.decal(proj, "kontur", grow(w, 0.018), LIFT_DARK)
        part.decal(proj, "brzoskwinia", w, LIFT_FILL)
    for c in CURTAINS:
        part.decal(proj, "koral", round_poly(c, 0.045), LIFT_TOP)

    if sliding_door:
        door = smooth_path(
            poly_crop((612, 408), (612, 825), (908, 825), (908, 408)), 0.1
        )
        part.stroke(proj, "kontur", door, PANEL_LINE, LIFT_DARK)
    else:
        part.stroke(proj, "kontur", poly_crop((908, 408), (908, 720)), PANEL_LINE, LIFT_DARK)
    wing = smooth_path(poly_crop((908, 720), (1050, 720), (1125, 750), (1172, 812)), 0.12)
    part.stroke(proj, "kontur", wing, PANEL_LINE, LIFT_DARK)
    part.stroke(proj, "kontur", poly_crop((1222, 595), (1240, 808)), PANEL_LINE, LIFT_DARK)

    for cy in (605, 626, 647, 668, 688):
        part.stroke(proj, "kontur", poly_crop((292, cy), (380, cy)), 0.03, LIFT_DARK)
    part.decal(proj, "kontur", rrect2(*crop(392, 612), *crop(452, 674), 0.05), LIFT_DARK)
    part.decal(proj, "zielen", rrect2(*crop(402, 622), *crop(442, 664), 0.035), LIFT_FILL)
    part.decal(proj, "kontur", rrect2(*crop(928, 618), *crop(1006, 644), 0.045), LIFT_DARK)
    part.decal(proj, "krem", rrect2(*crop(937, 625), *crop(997, 637), 0.02), LIFT_FILL)
    cz, cy = crop(1260, 658)
    part.decal(proj, "kontur", circle2(cz, cy, 0.065), LIFT_DARK)
    part.decal(proj, "krem", circle2(cz, cy, 0.04), LIFT_FILL)


def add_front(part, proj):
    for s in (1, -1):
        shield = round_poly(
            [(s * 0.035, 1.6), (s * 0.70, 1.6), (s * 0.64, 2.06), (s * 0.035, 2.06)], 0.07
        )
        part.decal(proj, "kontur", grow(shield, 0.022), LIFT_DARK)
        part.decal(proj, "brzoskwinia", shield, LIFT_FILL)


def add_rear(part, proj):
    hatch = rrect2(-0.52, 1.56, 0.52, 2.0, 0.08)
    part.stroke(proj, "kontur", hatch, PANEL_LINE, LIFT_DARK, closed=True)
    win = rrect2(-0.42, 1.64, 0.42, 1.92, 0.06)
    part.decal(proj, "kontur", grow(win, 0.018), LIFT_DARK)
    part.decal(proj, "brzoskwinia", win, LIFT_FILL)
    for s in (1, -1):
        curtain = round_poly(
            [(s * 0.40, 1.655), (s * 0.28, 1.655), (s * 0.31, 1.78), (s * 0.26, 1.905), (s * 0.40, 1.905)],
            0.035,
        )
        part.decal(proj, "koral", curtain, LIFT_TOP)
    engine = rrect2(-0.50, 0.66, 0.50, 1.34, 0.08)
    part.stroke(proj, "kontur", engine, PANEL_LINE, LIFT_DARK, closed=True)
    part.decal(proj, "kontur", rrect2(-0.1, 1.17, 0.1, 1.23, 0.025), LIFT_DARK)
    part.decal(proj, "krem", rrect2(-0.07, 1.185, 0.07, 1.215, 0.012), LIFT_FILL)
    part.decal(proj, "kontur", rrect2(-0.2, 0.74, 0.2, 0.88, 0.025), LIFT_DARK)
    part.decal(proj, "krem", rrect2(-0.18, 0.76, 0.18, 0.86, 0.015), LIFT_FILL)


def bumper_path(front):
    if front:
        z_side, z_face, z_start = 1.86, crop(1345, 0)[0] - 0.05, crop(1160, 0)[0]
    else:
        z_side, z_face, z_start = -2.0, crop(175, 0)[0] + 0.05, crop(275, 0)[0]
    x_side, x_face = W + 0.05, 0.5
    side = [(x_side, z_start), (x_side, z_start + (z_side - z_start) * 0.5), (x_side, z_side)]
    arc = []
    for i in range(1, 5):
        a = math.pi / 2 * i / 4
        arc.append(
            (x_face + (x_side - x_face) * math.cos(a), z_side + (z_face - z_side) * math.sin(a))
        )
    half = side + arc
    return half + [(-x, z) for x, z in reversed(half)]


def build_body():
    part = Part("nadwozie")
    tris = body_solid()
    add_body_paint(part, tris)
    part.prims["kontur"] += shade(inflate(tris, 0.024), 180)

    add_side(part, Projector(tris, 0, -1, limit=0.17), sliding_door=True)
    add_side(part, Projector(tris, 0, 1, limit=0.17), sliding_door=False)
    front_proj = Projector(tris, 2, 1)
    rear_proj = Projector(tris, 2, -1)
    add_front(part, front_proj)
    add_rear(part, rear_proj)

    # Roof rim: overhangs the body, with a visor at the front.
    rim_rings = []
    for y, hx, z0, z1 in (
        (2.11, 0.84, -2.06, 1.87),
        (2.14, 0.875, -2.08, 1.89),
        (2.17, 0.87, -2.06, 1.85),
        (2.25, 0.82, -1.98, 1.72),
        (2.30, 0.74, -1.82, 1.58),
    ):
        cz, hz = (z0 + z1) / 2, (z1 - z0) / 2
        rim_rings.append([(u, y, cz + v) for u, v in rounded_rect(hx, hz, 0.34, corner=3)])
    part.solid("krem", loft(rim_rings), outline=0.024)

    # Underbody: closes the wheel arches and carries the bumpers.
    part.solid("kontur", rbox(-0.6, 0.6, 0.37, 0.95, -2.0, 2.0, r=0.02, corner=1, rows=1))
    part.solid("kontur", rbox(-0.5, 0.5, 0.33, 0.5, -2.31, 2.3, r=0.02, corner=1, rows=1))
    y_bumper = (crop(0, 865)[1] + crop(0, 810)[1]) / 2
    for front in (True, False):
        part.solid(
            "zderzak", sweep(bumper_path(front), 0.055, 0.105, y_bumper, 0.05), outline=0.022
        )

    # Headlights, tail lights, mirrors.
    for s in (1, -1):
        centre = front_proj.hit(s * 0.54, 0.84, (0.0, 0.84), 0.0)
        c = (centre[0], centre[1], centre[2] - 0.05)
        lamp = lathe(
            [(0.135, 0.0), (0.135, 0.085), (0.105, 0.105), (0.10, 0.108), (0.06, 0.135), (0.0, 0.145)],
            "z",
            c,
            20,
        )
        shaded = shade(lamp, 40)
        for t in shaded:
            pts = [q[0] for q in t]
            r = max(math.hypot(p[0] - c[0], p[1] - c[1]) for p in pts)
            part.prims["reflektor" if r <= 0.104 else "kolpak"].append(t)
        part.prims["kontur"] += shade(inflate(lamp, 0.018), 180)

        rear = rear_proj.hit(s * 0.5, 0.78, (0.0, 0.78), 0.0)
        part.solid(
            "swiatlo_tyl",
            rbox(rear[0] - 0.075, rear[0] + 0.075, 0.63, 0.92, rear[2] - 0.075, rear[2] + 0.05, r=0.03),
            outline=0.018,
        )

        x_out = s * (W * taper(1.5) + 0.04)
        arm0 = (s * W * 0.82, *crop(1195, 595)[::-1])
        elbow = (x_out, *crop(1190, 560)[::-1])
        glass = (x_out + s * 0.02, *crop(1155, 530)[::-1])
        part.solid("kolpak", tube(arm0, elbow, 0.014), outline=0.01)
        part.solid("kolpak", tube(elbow, glass, 0.014), outline=0.01)
        part.solid("kolpak", ellipsoid(glass, 0.03, 0.095, 0.058), outline=0.014)
    return part


# Wheels --------------------------------------------------------------------

BANDS = (
    (0.15, "kolpak"),
    (0.165, "kontur"),
    (0.235, "felga"),
    (0.25, "kontur"),
)


def build_wheel(name, x_side, z):
    """Local X points away from the car on the outer face, multiplied by x_side."""
    part = Part(name, translation=(x_side * WHEEL_X, WHEEL_R, z))
    profile = [
        (0.0, -0.12),
        (0.30, -0.12),
        (0.36, -0.07),
        (0.36, 0.07),
        (0.30, 0.12),
        (0.25, 0.122),
        (0.235, 0.135),
        (0.20, 0.142),
        (0.165, 0.132),
        (0.15, 0.135),
        (0.10, 0.168),
        (0.0, 0.184),
    ]
    profile = [(r, a * x_side) for r, a in profile]
    solid = lathe(profile, "x", (0.0, 0.0, 0.0), 18)
    tyre_outline = inflate(
        lathe(
            [(0.25, -0.12 * x_side), (0.36, -0.07 * x_side), (0.36, 0.07 * x_side), (0.25, 0.12 * x_side)],
            "x",
            (0.0, 0.0, 0.0),
            18,
        ),
        0.016,
    )
    part.prims["kontur"] += shade(tyre_outline, 180)
    for t in shade(solid, 35):
        pts = [q[0] for q in t]
        r = max(math.hypot(p[1], p[2]) for p in pts)
        outer = min(p[0] * x_side for p in pts) > 0.1
        mat = "opona"
        if outer:
            for limit, band in BANDS:
                if r <= limit + 1e-4:
                    mat = band
                    break
        part.prims[mat].append(t)
    # Bolts: a plain hubcap would show no rotation at all.
    for i in range(5):
        a = 2 * math.pi * i / 5
        y, zz = 0.092 * math.cos(a), 0.092 * math.sin(a)
        bolt = ellipsoid((0.17 * x_side, y, zz), 0.016, 0.018, 0.018, segs=5, rows=3)
        part.solid("kontur", bolt, crease=70)
    return part


# Tent, lid, rack -----------------------------------------------------------

HINGE_Z, _ = crop(270, 0)
HINGE_Y = 2.30
LID_SLOPE = (345 - 85) / (890 - 275)
OPEN_ANGLE = math.atan(LID_SLOPE)
CLOSED_ANGLE = math.radians(0.6)
TENT_X = 0.70
LID_TOP = 0.20


def to_hinge(z_y):
    return (z_y[0] - HINGE_Z, z_y[1] - HINGE_Y)


def build_tent():
    part = Part("namiot_scianki", translation=(0.0, HINGE_Y, HINGE_Z))
    front_top_z = crop(860, 0)[0] - HINGE_Z
    front_base_z = crop(895, 0)[0] - HINGE_Z
    # The top edge lies exactly on the lid's underside line through the hinge.
    wall = [(0.0, 0.0), (front_base_z, 0.0), (front_top_z, front_top_z * LID_SLOPE)]
    prism = extrude_x(wall, -TENT_X, TENT_X)
    part.solid("koral", prism, outline=0.02, crease=30)

    win = round_poly([to_hinge(p) for p in poly_crop((520, 310), (785, 195), (815, 312))], 0.055)
    strut = [to_hinge(p) for p in poly_crop((345, 358), (385, 305), (438, 358))]
    for sign in (-1, 1):
        proj = Projector(prism, 0, sign, limit=5.0)
        part.decal(proj, "kontur", grow(win, 0.018), LIFT_DARK)
        part.decal(proj, "brzoskwinia", win, LIFT_FILL)
        part.stroke(proj, "kontur", strut, 0.018, LIFT_DARK)
    # Front wall: a small rounded window, invented for the unseen side.
    proj = Projector(prism, 2, 1, limit=5.0)
    mid_y = front_top_z * LID_SLOPE * 0.5
    front_win = rrect2(-0.34, mid_y - 0.2, 0.34, mid_y + 0.2, 0.07)
    part.decal(proj, "kontur", grow(front_win, 0.018), LIFT_DARK)
    part.decal(proj, "brzoskwinia", front_win, LIFT_FILL)
    return part


def rotation_x(angle):
    return (math.sin(angle / 2), 0.0, 0.0, math.cos(angle / 2))


def build_lid():
    """Modelled flat in the hinge frame; the open pose is the node rotation."""
    lid = Part(
        "namiot_pokrywa",
        translation=(0.0, HINGE_Y, HINGE_Z),
        rotation=rotation_x(-OPEN_ANGLE),
    )
    length = (890 - 270) / math.cos(OPEN_ANGLE) * KPX
    lid.solid("krem", rbox(-0.78, 0.78, 0.02, LID_TOP, 0.0, length, r=0.06, rows=1), outline=0.024)

    board = Part("deska", parent="namiot_pokrywa")
    z0, z1, base = -0.10, 2.05, LID_TOP + 0.005
    rings = []
    for i in range(13):
        t = i / 12
        hw = max(0.28 * math.sin(math.pi * t**0.72) ** 0.72, 0.008)
        ring = []
        for j in range(8):
            a = 2 * math.pi * j / 8
            ring.append((hw * math.cos(a), base + 0.05 + 0.05 * math.sin(a), z0 + (z1 - z0) * t))
        rings.append(ring)
    board_solid = loft(rings)
    board.solid("koral", board_solid, outline=0.018, crease=70)
    fin = extrude_x([(-0.02, base + 0.085), (0.24, base + 0.085), (0.02, base + 0.265), (-0.09, base + 0.265)], -0.014, 0.014)
    board.solid("koral", fin, outline=0.014)

    bag = Part("torba", parent="namiot_pokrywa")
    # The bag and its straps reach down to the lid.
    bag.solid("zielen_bagaz", rbox(-0.25, 0.25, base + 0.085, base + 0.325, 0.39, 1.26, r=0.04, rows=1), outline=0.02)
    for z in (0.58, 1.03):
        bag.solid(
            "kontur",
            rbox(-0.262, 0.262, base - 0.015, base + 0.338, z, z + 0.035, r=0.012, corner=1, rows=1),
        )
    return [lid, board, bag]


def build_rack():
    part = Part("bagaznik")
    shift = 0.15
    z0, z1 = 0.74, 1.70
    part.solid("zderzak", rbox(-0.62, 0.62, 2.40, 2.47, z0, z1, r=0.03, corner=1, rows=1), outline=0.018)
    for z in (0.86, 1.56):
        for s in (1, -1):
            part.solid(
                "zderzak",
                rbox(s * 0.54 - 0.03, s * 0.54 + 0.03, 2.27, 2.41, z - 0.035, z + 0.035, r=0.015, corner=1, rows=1),
                outline=0.014,
            )
    rail_y = 2.60
    corners = [(-0.58, z0 + 0.04), (0.58, z0 + 0.04), (0.58, z1 - 0.04), (-0.58, z1 - 0.04)]
    for i, (x, z) in enumerate(corners):
        nx, nz = corners[(i + 1) % 4]
        part.solid("zderzak", tube((x, rail_y, z), (nx, rail_y, nz), 0.016, sides=4), outline=0.011)
        part.solid("zderzak", tube((x, 2.46, z), (x, rail_y, z), 0.016, sides=4), outline=0.011)

    z_green = (crop(940, 0)[0] + shift, crop(1055, 0)[0] + shift)
    part.solid(
        "zielen_bagaz",
        rbox(-0.44, 0.40, 2.475, crop(0, 232)[1], z_green[0], z_green[1], r=0.022, rows=1),
        outline=0.018,
    )
    part.solid(
        "walizka_jasna",
        rbox(-0.36, 0.30, crop(0, 232)[1] + 0.012, crop(0, 185)[1], z_green[0] + 0.14, z_green[1] - 0.01, r=0.022, rows=1),
        outline=0.018,
    )
    z_brown = (crop(1062, 0)[0] + shift, crop(1138, 0)[0] + shift)
    part.solid(
        "walizka_braz",
        rbox(-0.30, 0.36, 2.475, crop(0, 192)[1], z_brown[0], z_brown[1], r=0.022, rows=1),
        outline=0.018,
    )
    # Straps wrapped around the brown case.
    for x in (-0.08, 0.14):
        part.solid(
            "kontur",
            rbox(x, x + 0.03, 2.47, crop(0, 192)[1] + 0.006, z_brown[0] - 0.006, z_brown[1] + 0.006, r=0.01, corner=1, rows=1),
        )
    return part


# Animations ----------------------------------------------------------------


def smoothstep(t):
    return t * t * (3 - 2 * t)


def anim_wheels():
    seconds, keys = 1.2, 8
    times = [seconds * i / keys for i in range(keys + 1)]
    # Positive rotation about +X moves the top of the wheel towards +Z: forwards.
    rotations = [rotation_x(2 * math.pi * i / keys) for i in range(keys + 1)]
    return times, rotations


def anim_tent():
    fold, hold = 1.6, 0.6
    steps = 14
    times, angles = [], []
    for i in range(steps + 1):
        t = i / steps
        times.append(fold * t)
        angles.append(OPEN_ANGLE + (CLOSED_ANGLE - OPEN_ANGLE) * smoothstep(t))
    for i in range(steps + 1):
        t = i / steps
        times.append(fold + hold + fold * t)
        angles.append(CLOSED_ANGLE + (OPEN_ANGLE - CLOSED_ANGLE) * smoothstep(t))
    rotations = [rotation_x(-a) for a in angles]
    scales = [(1.0, math.tan(a) / math.tan(OPEN_ANGLE), 1.0) for a in angles]
    return times, rotations, scales


# GLB -----------------------------------------------------------------------


class Writer:
    def __init__(self):
        self.bin = bytearray()
        self.views = []
        self.accessors = []

    def _blob(self, data, target=None):
        while len(self.bin) % 4:
            self.bin.append(0)
        view = {"buffer": 0, "byteOffset": len(self.bin), "byteLength": len(data)}
        if target:
            view["target"] = target
        self.views.append(view)
        self.bin += data
        return len(self.views) - 1

    def accessor(self, values, kind, component=5126, target=None, bounds=False):
        size = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}[kind]
        fmt = {5126: "f", 5123: "H"}[component]
        flat = [c for v in values for c in (v if size > 1 else (v,))]
        data = struct.pack(f"<{len(flat)}{fmt}", *flat)
        acc = {
            "bufferView": self._blob(data, target),
            "componentType": component,
            "count": len(values),
            "type": kind,
        }
        if bounds:
            # Bounds must match the stored float32 values, not the doubles.
            rounded = struct.unpack(f"<{len(flat)}{fmt}", data)
            acc["min"] = [min(rounded[i::size]) for i in range(size)]
            acc["max"] = [max(rounded[i::size]) for i in range(size)]
        self.accessors.append(acc)
        return len(self.accessors) - 1


def primitive(writer, material, tris):
    index = {}
    positions, normals, indices = [], [], []
    for t in tris:
        tri = []
        for p, n in t:
            k = (key(p), round(n[0], 3), round(n[1], 3), round(n[2], 3))
            if k not in index:
                if len(positions) >= 65535:
                    raise ValueError("primitive too large for 16-bit indices")
                index[k] = len(positions)
                positions.append(p)
                normals.append(n)
            tri.append(index[k])
        if len(set(tri)) == 3:
            indices += tri
    return {
        "attributes": {
            "POSITION": writer.accessor(positions, "VEC3", target=34962, bounds=True),
            "NORMAL": writer.accessor(normals, "VEC3", target=34962),
        },
        "indices": writer.accessor(indices, "SCALAR", component=5123, target=34963),
        "material": material,
    }, len(indices) // 3


def write_glb(path, parts, wheel_names):
    writer = Writer()
    mat_names = list(MATERIALS)
    materials = []
    for name in mat_names:
        colour, roughness = MATERIALS[name]
        mat = {
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": srgb(colour),
                "metallicFactor": 0.0,
                "roughnessFactor": roughness,
            },
        }
        if name in UNLIT:
            mat["extensions"] = {"KHR_materials_unlit": {}}
        materials.append(mat)

    nodes = [{"name": "kamper", "children": []}]
    meshes = []
    node_of = {}
    triangles = 0
    for part in parts:
        prims = []
        for name in mat_names:
            if part.prims.get(name):
                prim, count = primitive(writer, mat_names.index(name), part.prims[name])
                prims.append(prim)
                triangles += count
        meshes.append({"name": part.name, "primitives": prims})
        node = {"name": part.name, "mesh": len(meshes) - 1}
        if part.translation:
            node["translation"] = list(part.translation)
        if part.rotation:
            node["rotation"] = list(part.rotation)
        nodes.append(node)
        node_of[part.name] = len(nodes) - 1
        if part.parent:
            nodes[node_of[part.parent]].setdefault("children", []).append(len(nodes) - 1)
        else:
            nodes[0]["children"].append(len(nodes) - 1)

    def sampler(times, values, kind):
        return {
            "input": writer.accessor(times, "SCALAR", bounds=True),
            "output": writer.accessor(values, kind),
            "interpolation": "LINEAR",
        }

    times, rotations = anim_wheels()
    drive = {
        "name": "Jazda",
        "samplers": [sampler(times, rotations, "VEC4")],
        "channels": [
            {"sampler": 0, "target": {"node": node_of[n], "path": "rotation"}} for n in wheel_names
        ],
    }
    times, rotations, scales = anim_tent()
    tent = {
        "name": "Namiot",
        "samplers": [sampler(times, rotations, "VEC4"), sampler(times, scales, "VEC3")],
        "channels": [
            {"sampler": 0, "target": {"node": node_of["namiot_pokrywa"], "path": "rotation"}},
            {"sampler": 1, "target": {"node": node_of["namiot_scianki"], "path": "scale"}},
        ],
    }

    while len(writer.bin) % 4:
        writer.bin.append(0)
    doc = {
        "asset": {"version": "2.0", "generator": "app/tool/camper_3d.py"},
        "extensionsUsed": ["KHR_materials_unlit"],
        "scene": 0,
        "scenes": [{"name": "kamper", "nodes": [0]}],
        "nodes": nodes,
        "meshes": meshes,
        "materials": materials,
        "animations": [drive, tent],
        "accessors": writer.accessors,
        "bufferViews": writer.views,
        "buffers": [{"byteLength": len(writer.bin)}],
    }
    text = json.dumps(doc, separators=(",", ":")).encode()
    text += b" " * (-len(text) % 4)
    total = 12 + 8 + len(text) + 8 + len(writer.bin)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(text), 0x4E4F534A))
        f.write(text)
        f.write(struct.pack("<II", len(writer.bin), 0x004E4942))
        f.write(writer.bin)
    return triangles, total


PREVIEW = """<title>Kamper 3D</title>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Epilogue:wght@500;700&display=swap">
<style>
/* One screen: the model fills it, with a slim control bar like a van's dash. */
:root {
  --ground: #e6ece7;
  --ink: #20302a;
  --quiet: #566a60;
  --body: #547c65;
  --on-body: #fbf6e8;
  --line: #c6d2ca;
  --font: "Epilogue", "Segoe UI", system-ui, sans-serif;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --ground: #17201c;
    --ink: #eaf0ea;
    --quiet: #a0b2a8;
    --body: #7aa58c;
    --on-body: #10201a;
    --line: #33423a;
    color-scheme: dark;
  }
}
:root[data-theme="dark"] {
  --ground: #17201c;
  --ink: #eaf0ea;
  --quiet: #a0b2a8;
  --body: #7aa58c;
  --on-body: #10201a;
  --line: #33423a;
  color-scheme: dark;
}
html, body { height: 100%; margin: 0; }
body {
  background: var(--ground);
  color: var(--ink);
  font-family: var(--font);
  display: flex;
  flex-direction: column;
}
model-viewer {
  flex: 1;
  min-height: 0;
  width: 100%;
  background: transparent;
  --poster-color: transparent;
}
.bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px 16px;
  border-top: 1px solid var(--line);
  padding-block: 12px;
  padding-left: max(16px, env(safe-area-inset-left, 0px));
  padding-right: max(16px, env(safe-area-inset-right, 0px));
}
.controls { display: flex; gap: 8px; }
button {
  font: 700 15px/1 var(--font);
  color: var(--on-body);
  background: var(--body);
  border: 2px solid var(--body);
  border-radius: 8px;
  padding: 11px 16px 9px;
  min-width: 92px;
  cursor: pointer;
}
button[aria-pressed="true"] {
  color: var(--body);
  background: transparent;
}
button:disabled { opacity: 0.55; cursor: default; }
button:focus-visible { outline: 3px solid var(--ink); outline-offset: 2px; }
.note {
  flex: 1 1 240px;
  min-width: 0;
  margin: 0;
  font-size: 13px;
  line-height: 1.4;
  color: var(--quiet);
  font-weight: 500;
}
.spec { font-variant-numeric: tabular-nums; }
</style>
<script type="module" src="https://unpkg.com/@google/model-viewer@4.4.0/dist/model-viewer.min.js"></script>
<model-viewer id="camper" alt="Zielono-kremowy kamper z rozłożonym koralowym namiotem, deską surfingową i walizkami na bagażniku"
  src="data:model/gltf-binary;base64,__GLB__"
  camera-controls auto-rotate rotation-per-second="14deg" auto-rotate-delay="0"
  camera-orbit="-50deg 74deg auto" field-of-view="24deg" min-camera-orbit="auto 5deg auto" max-camera-orbit="auto 100deg auto"
  shadow-intensity="1" shadow-softness="0.8" tone-mapping="neutral" exposure="1"
  animation-crossfade-duration="0" interaction-prompt="none" touch-action="pan-y"></model-viewer>
<div class="bar">
  <div class="controls">
    <button id="drive" type="button" aria-pressed="false" disabled>Jazda</button>
    <button id="tent" type="button" disabled>Namiot</button>
  </div>
  <p class="note" id="note">Przeciągnij, żeby obrócić. Kółkiem lub dwoma palcami przybliżysz.
    <span class="spec">Dł. __LENGTH__ m, __TRIS__ tys. trójkątów.</span></p>
</div>
<script>
const viewer = document.getElementById("camper");
const drive = document.getElementById("drive");
const tent = document.getElementById("tent");

if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
  viewer.removeAttribute("auto-rotate");
}

function setDriving(on) {
  drive.setAttribute("aria-pressed", String(on));
  drive.textContent = on ? "Stop" : "Jazda";
}

viewer.addEventListener("load", () => {
  drive.disabled = false;
  tent.disabled = false;
});

viewer.addEventListener("error", () => {
  // Some hosts forbid fetching data: URLs, so retry the same bytes as a blob: URL.
  if (viewer.src.startsWith("data:")) {
    const bytes = Uint8Array.from(atob(viewer.src.split(",")[1]), (c) => c.charCodeAt(0));
    viewer.src = URL.createObjectURL(new Blob([bytes], { type: "model/gltf-binary" }));
    return;
  }
  document.getElementById("note").textContent =
    "Nie udało się wczytać modelu. Odśwież stronę albo otwórz ją w innej przeglądarce.";
});

drive.addEventListener("click", () => {
  if (drive.getAttribute("aria-pressed") === "true") {
    viewer.pause();
    setDriving(false);
    return;
  }
  viewer.animationName = "Jazda";
  viewer.play();
  setDriving(true);
});

tent.addEventListener("click", () => {
  setDriving(false);
  tent.disabled = true;
  viewer.animationName = "Namiot";
  viewer.currentTime = 0;
  viewer.play({ repetitions: 1 });
});

viewer.addEventListener("finished", () => {
  tent.disabled = false;
});
</script>
"""


def write_preview(path, glb_path, triangles):
    with open(glb_path, "rb") as f:
        encoded = base64.b64encode(f.read()).decode()
    length = f"{(crop(1345, 0)[0] - crop(175, 0)[0]):.1f}".replace(".", ",")
    page = PREVIEW.replace("__GLB__", encoded)
    page = page.replace("__LENGTH__", length).replace("__TRIS__", str(round(triangles / 1000)))
    with open(path, "w", encoding="utf-8") as f:
        f.write(page)


def main():
    wheels = [
        build_wheel("kolo_przod_prawe", -1, Z_FRONT_WHEEL),
        build_wheel("kolo_przod_lewe", 1, Z_FRONT_WHEEL),
        build_wheel("kolo_tyl_prawe", -1, Z_REAR_WHEEL),
        build_wheel("kolo_tyl_lewe", 1, Z_REAR_WHEEL),
    ]
    parts = [build_body(), build_rack(), *wheels, build_tent(), *build_lid()]
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out_dir = os.path.join(root, "resorces", "camper_3d")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "camper.glb")
    triangles, size = write_glb(out, parts, [w.name for w in wheels])
    write_preview(os.path.join(out_dir, "preview.html"), out, triangles)
    print(f"{out}: {triangles} triangles, {size / 1024:.0f} KiB")


if __name__ == "__main__":
    main()
