"""Stim Toy: a paw pressing a rainbow pop-it beside a spinning fidget spinner."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, circle, ellipse, group, path, rect  # noqa: E402
from _group4_helpers import arc, head, limb, paw  # noqa: E402

STYLE = "lavender"

ROWS = ["#ff8fa3", "#ffb870", "#ffe27a", "#8fe3b8", "#8cc8f5", "#b79cf0"]
FUR = "#f2c48d"


def _pop_it() -> str:
	x0, y0, w, h = 210, 350, 440, 440
	clip = f'<clipPath id="popit"><rect x="{x0}" y="{y0}" width="{w}" height="{h}" rx="60"/></clipPath>'
	bands = "".join(rect(x0, y0 + i * h / 6, w, h / 6 + 1, c, None) for i, c in enumerate(ROWS))
	body = clip + f'<g clip-path="url(#popit)">{bands}</g>' + rect(x0, y0, w, h, None, INK, 12, 60)
	bubbles = ""
	for row in range(6):
		cy = y0 + 37 + row * h / 6
		for col in range(5):
			cx = x0 + 56 + col * 82
			pressed = (row, col) in ((1, 1), (3, 3), (4, 0))
			bubbles += circle(cx, cy, 28, ROWS[row], INK, 6)
			if pressed:
				bubbles += circle(cx, cy + 3, 18, INK, None, extra='opacity="0.25"')
			else:
				bubbles += path(f"M{cx - 15},{cy - 6} Q{cx - 12},{cy - 17} {cx - 2},{cy - 19}", None, "#ffffff", 7)
	return group(body, bubbles, transform="rotate(-8 430 570)")


def _spinner(cx, cy) -> str:
	out = ""
	angles = (-60, 60, 180)
	pts = [(cx + 88 * math.cos(math.radians(a)), cy + 88 * math.sin(math.radians(a))) for a in angles]
	for x, y in pts:
		out += f'<line x1="{cx}" y1="{cy}" x2="{x:.1f}" y2="{y:.1f}" stroke="{INK}" stroke-width="76" stroke-linecap="round"/>'
	for x, y in pts:
		out += f'<line x1="{cx}" y1="{cy}" x2="{x:.1f}" y2="{y:.1f}" stroke="#7fdcc0" stroke-width="56" stroke-linecap="round"/>'
	for x, y in pts:
		out += circle(round(x, 1), round(y, 1), 50, "#7fdcc0", INK, 10) + circle(round(x, 1), round(y, 1), 24, "#ffffff", INK, 7)
	out += circle(cx, cy, 44, "#ff86b0", INK, 10) + circle(cx, cy, 16, "#ffe27a", INK, 6)
	# motion swooshes
	out += arc(cx, cy, 165, 200, 250, "#ffffff", 12) + arc(cx, cy, 165, 20, 70, "#ffffff", 12)
	return out


def _swirl(cx, cy, s, color) -> str:
	pts = []
	for k in range(0, 46):
		t = k * 0.28
		r = s * 0.12 * t
		pts.append(f"{cx + r * math.cos(t):.1f},{cy + r * math.sin(t):.1f}")
	return path("M" + " L".join(pts), None, color, 11)


def draw() -> str:
	swirls = _swirl(235, 255, 40, "#b79cf0") + _swirl(225, 870, 30, "#8fe3b8") + _swirl(840, 560, 30, "#ff8fa3")
	shoulders = ellipse(770, 905, 120, 60, "#ff9cc2")
	friend = head(770, 790, 88, "mouse", FUR, "#ffd0de", happy=True)
	arm = limb(715, 870, 632, 712, FUR, 64)
	hand = paw(612, 688, 54, FUR, angle=-130)
	return group(swirls, _pop_it(), _spinner(690, 300), shoulders, friend, arm, hand)
