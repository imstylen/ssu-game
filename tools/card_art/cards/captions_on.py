"""Captions On: a video screen with a talking bunny and a bold caption bar, watched by a hearing-aid cat."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, circle, ellipse, group, path, polygon, rect, text  # noqa: E402
from _group4_helpers import head  # noqa: E402

STYLE = "sky"

NAVY = "#2f3f73"
SCREEN = "#cfe9ff"


def _play(cx, cy, r, fill) -> str:
	return circle(cx, cy, r, fill) + polygon([(cx - r * 0.3, cy - r * 0.42), (cx - r * 0.3, cy + r * 0.42), (cx + r * 0.45, cy)], "#ffffff", None)


def _screen() -> str:
	x0, y0, x1, y1 = 190, 190, 834, 640
	sx0, sy0, sx1, sy1 = x0 + 28, y0 + 28, x1 - 28, y1 - 28
	clip = f'<clipPath id="capscreen"><rect x="{sx0}" y="{sy0}" width="{sx1 - sx0}" height="{sy1 - sy0}" rx="24"/></clipPath>'
	stand = rect(472, 630, 80, 70, NAVY) + ellipse(512, 710, 150, 30, NAVY)
	frame = rect(x0, y0, x1 - x0, y1 - y0, NAVY, INK, 12, 46)
	# talking bunny inside the screen
	inner = rect(sx0, sy0, sx1 - sx0, sy1 - sy0, SCREEN, None)
	inner += circle(300, 270, 26, "#ffffff", None, extra='opacity="0.7"') + circle(740, 300, 18, "#ffffff", None, extra='opacity="0.7"')
	inner += ellipse(470, 560, 150, 110, "#f7a8c4")  # shoulders / sweater
	inner += head(470, 390, 105, "bunny", "#ffffff", "#ffd0de")
	inner += ellipse(470, 432, 20, 16, "#c94f6d", None)  # talking mouth
	# speech icon
	bubble = path("M600,250 h150 a28,28 0 0 1 28,28 v62 a28,28 0 0 1 -28,28 h-90 l-34,30 v-30 h-26 a28,28 0 0 1 -28,-28 v-62 a28,28 0 0 1 28,-28 Z",
		"#ffffff", INK, 8)
	bubble += circle(638, 309, 11, NAVY, None) + circle(675, 309, 11, NAVY, None) + circle(712, 309, 11, NAVY, None)
	# caption bar with text lines
	bar = rect(sx0, 482, sx1 - sx0, sy1 - 482, "#1f2a52", None)
	bar += rect(270, 510, 300, 26, "#ffffff", None, 0, 13) + rect(590, 510, 160, 26, "#ffe27a", None, 0, 13)
	bar += rect(330, 556, 210, 26, "#ffffff", None, 0, 13) + rect(560, 556, 130, 26, "#ffffff", None, 0, 13)
	screen = clip + f'<g clip-path="url(#capscreen)">{inner}{bubble}{bar}</g>'
	cc = rect(236, 236, 104, 70, "#ffffff", INK, 8, 16) + text(288, 286, "CC", 46, NAVY)
	return stand + frame + screen + cc


def _viewer() -> str:
	fur, inner = "#f6b26b", "#ffe2c2"
	body = ellipse(300, 850, 110, 70, fur)
	face = head(300, 750, 92, "cat", fur, inner, happy=True)
	hearing_aid = path("M384,700 q32,10 26,52 q-6,26 -26,22", "#7fb8ff", INK, 9) + circle(386, 778, 10, "#7fb8ff", INK, 6)
	return body + face + hearing_aid


def draw() -> str:
	return group(_screen(), _viewer(), _play(730, 810, 62, "#ff86b0"), _play(820, 700, 34, "#6ea9dc"))
