"""Noise-Cancelling Narwhal: narwhal floating serenely in big over-ear headphones, tusk pointing up."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, closed_eye, ellipse, group, path, rect, smile  # noqa: E402
from _group2_helpers import bubble  # noqa: E402

STYLE = "sky"

BODY = "#9fb9dc"
BELLY = "#e6effa"
SPOT = "#6f89b8"
NAVY = "#2f3e6b"
LAV = "#b9a3ee"
TUSK = "#fbf1d6"


def draw() -> str:
	tail = path("M700,700 Q800,690 830,610 Q860,600 860,640 Q850,700 800,720 Q850,740 850,790 Q820,800 790,760 Q760,730 700,740 Z", BODY)
	tusk = (path("M480,360 L560,170 L530,365 Z", TUSK)
		+ path("M492,330 L530,318 M504,290 L538,272 M515,250 L545,232 M526,212 L551,198", None, "#c9b78a", 7))
	body = path("M250,560 Q240,380 500,360 Q760,370 760,580 Q760,780 500,790 Q250,780 250,560 Z", BODY)
	belly = ellipse(500, 650, 170, 120, BELLY, None)
	spots = (circle(330, 470, 12, SPOT, None) + circle(690, 450, 14, SPOT, None) + circle(660, 500, 8, SPOT, None)
		+ circle(360, 520, 8, SPOT, None) + circle(420, 420, 9, SPOT, None) + circle(600, 410, 10, SPOT, None))
	flippers = (path("M320,700 Q250,760 270,800 Q330,790 370,730 Z", BODY)
		+ path("M680,700 Q750,760 730,800 Q670,790 630,730 Z", BODY))
	# Headphones: navy band over the top, big lavender cups on each side.
	headband = path("M285,520 Q290,320 500,315 Q710,320 715,520", None, INK, 54) \
		+ path("M285,520 Q290,320 500,315 Q710,320 715,520", None, NAVY, 36)
	cups = (rect(225, 450, 90, 150, LAV, INK, 10, 40) + rect(250, 470, 40, 110, "#d9ccfa", None, 0, 20)
		+ rect(685, 450, 90, 150, LAV, INK, 10, 40) + rect(710, 470, 40, 110, "#d9ccfa", None, 0, 20))
	face = (closed_eye(430, 540, 50) + closed_eye(570, 540, 50) + smile(500, 590, 50)
		+ blush(400, 585) + blush(600, 585))
	bubbles = bubble(220, 330, 24) + bubble(270, 260, 14) + bubble(810, 330, 20) + bubble(780, 260, 12) + bubble(200, 760, 16)
	water = path("M190,860 Q350,820 500,860 Q650,900 830,850", None, "#ffffff", 14)
	return group(bubbles, water, tail, flippers, body, belly, spots, tusk, headband, cups, face)
