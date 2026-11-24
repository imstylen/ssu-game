"""Shared helpers for group-4 one-shot cards (not a card; skipped by build.py)."""
from __future__ import annotations

import math

from art_lib import INK, blush, circle, closed_eye, ellipse, eye, line, path, polygon, smile

PINK = "#ff8fb1"


def limb(x1, y1, x2, y2, fur, w=80):
	"""Thick furry limb with ink outline."""
	return line(x1, y1, x2, y2, INK, w + 20) + line(x1, y1, x2, y2, fur, w)


def paw(cx, cy, r, fur, angle=0.0, toes=True):
	"""Round paw with toe bumps; `angle` (deg) points toward the fingertips."""
	out = ""
	if toes:
		a = math.radians(angle)
		for off in (-0.62, 0.0, 0.62):
			b = a + off
			out += circle(round(cx + math.cos(b) * r * 0.82, 1), round(cy + math.sin(b) * r * 0.82, 1), round(r * 0.36, 1), fur, INK, 8)
	out += circle(cx, cy, r, fur)
	return out


def sleeve(x1, y1, x2, y2, color, w=130):
	"""Sleeve segment (outlined) with a cuff stripe at the (x2, y2) end."""
	return limb(x1, y1, x2, y2, color, w)


def ears(cx, cy, r, kind, fur, inner):
	if kind == "bear":
		return (circle(cx - r * 0.72, cy - r * 0.72, r * 0.34, fur) + circle(cx - r * 0.72, cy - r * 0.72, r * 0.17, inner, None)
			+ circle(cx + r * 0.72, cy - r * 0.72, r * 0.34, fur) + circle(cx + r * 0.72, cy - r * 0.72, r * 0.17, inner, None))
	if kind == "mouse":
		return (circle(cx - r * 0.8, cy - r * 0.7, r * 0.48, fur) + circle(cx - r * 0.8, cy - r * 0.7, r * 0.28, inner, None)
			+ circle(cx + r * 0.8, cy - r * 0.7, r * 0.48, fur) + circle(cx + r * 0.8, cy - r * 0.7, r * 0.28, inner, None))
	if kind in ("cat", "fox"):
		out = ""
		for s in (-1, 1):
			out += polygon([(cx + s * r * 0.95, cy - r * 0.2), (cx + s * r * 0.78, cy - r * 1.25), (cx + s * r * 0.2, cy - r * 0.85)], fur, INK, 10)
			out += polygon([(cx + s * r * 0.8, cy - r * 0.42), (cx + s * r * 0.74, cy - r * 1.0), (cx + s * r * 0.4, cy - r * 0.78)], inner, None)
		return out
	if kind == "bunny":
		return (ellipse(cx - r * 0.42, cy - r * 1.2, r * 0.26, r * 0.7, fur, rotate=-10)
			+ ellipse(cx - r * 0.42, cy - r * 1.15, r * 0.12, r * 0.5, inner, None, rotate=-10)
			+ ellipse(cx + r * 0.42, cy - r * 1.2, r * 0.26, r * 0.7, fur, rotate=10)
			+ ellipse(cx + r * 0.42, cy - r * 1.15, r * 0.12, r * 0.5, inner, None, rotate=10))
	return ""


def dog_ears(cx, cy, r, color):
	return (ellipse(cx - r * 0.92, cy - r * 0.05, r * 0.28, r * 0.6, color, rotate=20)
		+ ellipse(cx + r * 0.92, cy - r * 0.05, r * 0.28, r * 0.6, color, rotate=-20))


def head(cx, cy, r, kind="bear", fur="#c89b6d", inner="#f6dcc0", happy=False, look=(0, 0), ear_color=None):
	"""Cute round animal head with face."""
	out = ears(cx, cy, r, kind, fur, inner) if kind != "dog" else ""
	out += circle(cx, cy, r, fur)
	if kind == "dog":
		out += dog_ears(cx, cy, r, ear_color or "#8a5a3c")
	out += ellipse(cx, cy + r * 0.38, r * 0.48, r * 0.32, inner, None)
	ex, ey, er = r * 0.38, cy - r * 0.05, max(r * 0.17, 8)
	if happy:
		out += closed_eye(cx - ex, ey, r * 0.3) + closed_eye(cx + ex, ey, r * 0.3)
	else:
		out += eye(cx - ex, ey, er, look) + eye(cx + ex, ey, er, look)
	out += ellipse(cx, cy + r * 0.25, r * 0.13, r * 0.09, "#2e2236", None)
	out += smile(cx, cy + r * 0.38, r * 0.36, open_mouth=happy)
	out += blush(cx - r * 0.62, cy + r * 0.3, r * 0.17, r * 0.09) + blush(cx + r * 0.62, cy + r * 0.3, r * 0.17, r * 0.09)
	return out


def _bar(x1, y1, x2, y2, color, w):
	return line(round(x1, 1), round(y1, 1), round(x2, 1), round(y2, 1), INK, w + 14) \
		+ line(round(x1, 1), round(y1, 1), round(x2, 1), round(y2, 1), color, w)


def wheelchair_back(wx, wy, r, d=1, frame="#6ea9dc"):
	"""Back rest and push handle (draw before the rider). d=+1 faces right, -1 faces left."""
	bx = wx - d * r * 0.6
	return _bar(bx, wy - r * 0.8, bx - d * r * 0.08, wy - r * 2.1, frame, 16) \
		+ _bar(bx - d * r * 0.08, wy - r * 2.1, bx - d * r * 0.4, wy - r * 2.1, "#4b3159", 14)


def wheelchair_front(wx, wy, r, d=1, frame="#6ea9dc"):
	"""Seat, footrest, caster and big wheel (draw after the rider's body)."""
	out = _bar(wx - d * r * 0.6, wy - r * 0.8, wx + d * r * 0.75, wy - r * 0.8, frame, 16)
	out += _bar(wx + d * r * 0.75, wy - r * 0.8, wx + d * r * 1.15, wy + r * 0.45, frame, 14)
	out += _bar(wx + d * r * 1.12, wy + r * 0.45, wx + d * r * 1.4, wy + r * 0.45, frame, 12)
	out += circle(round(wx + d * r * 1.05, 1), round(wy + r * 0.78, 1), round(r * 0.22, 1), "#ffffff", INK, 8)
	out += circle(wx, wy, r, "#ffffff", INK, 11) + circle(wx, wy, round(r * 0.8, 1), None, frame, 8)
	for i in range(8):
		a = math.pi * i / 4
		out += line(wx, wy, round(wx + math.cos(a) * r * 0.74, 1), round(wy + math.sin(a) * r * 0.74, 1), "#a8b4c8", 4)
	out += circle(wx, wy, round(r * 0.15, 1), frame, INK, 6)
	return out


def arc(cx, cy, r, a0, a1, color, width, outline=True):
	"""Circular arc from angle a0 to a1 (degrees, clockwise in screen space)."""
	x0, y0 = cx + r * math.cos(math.radians(a0)), cy + r * math.sin(math.radians(a0))
	x1, y1 = cx + r * math.cos(math.radians(a1)), cy + r * math.sin(math.radians(a1))
	large = 1 if (a1 - a0) % 360 > 180 else 0
	d = f"M{x0:.1f},{y0:.1f} A{r},{r} 0 {large} 1 {x1:.1f},{y1:.1f}"
	out = path(d, None, INK, width + 16) if outline else ""
	return out + path(d, None, color, width)


def confetti(points, colors):
	"""Small confetti bits: list of (x, y, kind, rot)."""
	out = ""
	for i, (x, y, kind, rot) in enumerate(points):
		c = colors[i % len(colors)]
		if kind == "r":
			out += f'<rect x="{x - 14}" y="{y - 8}" width="28" height="16" rx="4" fill="{c}" stroke="{INK}" stroke-width="5" transform="rotate({rot} {x} {y})"/>'
		elif kind == "c":
			out += circle(x, y, 11, c, INK, 5)
		else:
			out += path(f"M{x - 20},{y} q10,-16 20,0 t20,0", None, INK, 13).replace("<path", f'<path transform="rotate({rot} {x} {y})"') \
				+ path(f"M{x - 20},{y} q10,-16 20,0 t20,0", None, c, 6).replace("<path", f'<path transform="rotate({rot} {x} {y})"')
	return out
