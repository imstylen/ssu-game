"""Spoon Theory: a happy jar of spoons with three set aside on an open weekly planner."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, eye, group, heart, line, path, rect, smile  # noqa: E402
from _group5_helpers import spoon  # noqa: E402

STYLE = "mint"

MINT = "#7fd6b3"
PAGE = "#fffaf0"
PEACH = "#ffb38a"
SILVER = "#dbe3ec"


def draw() -> str:
	# Open planner.
	cover = path("M185,640 L515,665 L845,640 L845,880 L515,900 L185,880 Z", MINT)
	left = path("M205,625 Q360,610 512,650 L512,875 Q360,840 205,860 Z", PAGE, INK, 8)
	right = path("M512,650 Q664,610 825,625 L825,860 Q664,840 512,875 Z", PAGE, INK, 8)
	grid = ""
	for k in range(1, 4):
		x = 512 + k * 78
		grid += line(x, 640 - k * 4, x, 850 - k * 3, "#c9e8dc", 5)
		xl = 512 - k * 78
		grid += line(xl, 640 - k * 4, xl, 850 - k * 3, "#c9e8dc", 5)
	grid += line(225, 700, 495, 715, "#c9e8dc", 5) + line(530, 715, 805, 700, "#c9e8dc", 5)
	tabs = rect(560, 600, 46, 40, PEACH, INK, 6, 8) + rect(630, 596, 46, 40, "#ff9fc0", INK, 6, 8)

	# Jar full of spoons, with a face.
	jar_spoons = "".join(spoon(cx, 440, a, 290, SILVER, 7) for cx, a in
		((262, -20), (312, -7), (378, 7), (428, 20)))
	jar = path("M240,420 L450,420 L450,440 Q470,450 470,480 L470,760 Q470,800 430,800 L260,800 Q220,800 220,760 "
		"L220,480 Q220,450 240,440 Z", "#d7f3f6", INK, 10).replace("/>", ' fill-opacity="0.72"/>')
	rim = rect(228, 400, 234, 40, "#bde7ec", INK, 9, 14)
	shine = path("M250,500 L250,700", None, "#ffffff", 14)
	jar_face = eye(305, 640, 18) + eye(385, 640, 18) + smile(345, 668, 34) + blush(280, 672, 16, 9) + blush(410, 672, 16, 9)

	# Three spoons set aside on the planner page.
	aside = (spoon(624, 690, 62, 230, SILVER, 7) + spoon(650, 740, 62, 230, SILVER, 7)
		+ spoon(676, 790, 62, 230, SILVER, 7))
	return group(cover, left, right, grid, tabs, jar_spoons, jar, rim, shine, jar_face, aside,
		heart(760, 520, 36, PEACH), heart(560, 470, 24, "#ff9fc0"))
