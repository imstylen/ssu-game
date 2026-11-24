"""Tablet-Talking Tapir: nonspeaking, communicating fluently with an AAC tablet."""
from art_lib import INK, blush, circle, ellipse, eye, group, heart, path, rect, smile, star

STYLE = "lavender"

DARK = "#4a4a5c"
HEAD = "#5c5c72"
LIGHT = "#f4f1f8"
TABLET = "#ffd95a"


def symbol(kind, x, y):
	if kind == "circle":
		return circle(x, y, 20, "#5fc3b0", INK, 5)
	if kind == "heart":
		return heart(x, y - 2, 18, "#ff7a9c", INK, 5)
	if kind == "star":
		return star(x, y, 24, "#ffb84d", INK, 5)
	if kind == "square":
		return rect(x - 18, y - 18, 36, 36, "#a07ad8", INK, 5, r=6)
	if kind == "tri":
		return path(f"M{x},{y - 20} L{x + 20},{y + 16} L{x - 20},{y + 16} Z", "#6ea9dc", INK, 5)
	return circle(x, y, 20, "#ff9f6e", INK, 5)


def draw() -> str:
	body = ellipse(540, 650, 210, 215, DARK)
	saddle = path("M380,560 Q540,500 700,560 Q730,660 700,760 Q540,800 390,760 Q350,660 380,560 Z", LIGHT, None)
	back_legs = ellipse(400, 850, 80, 40, DARK) + ellipse(680, 850, 80, 40, DARK)
	# Rounded ears with the tapir's white rims.
	ears = ellipse(420, 262, 44, 56, LIGHT, rotate=-15) + ellipse(560, 270, 44, 56, LIGHT, rotate=20) \
		+ ellipse(420, 270, 28, 40, HEAD, None, rotate=-15) + ellipse(560, 278, 28, 40, HEAD, None, rotate=20)
	head = ellipse(470, 380, 140, 115, HEAD)
	# Short, flexible trunk-like snout curling down on the left.
	snout = path("M362,335 Q285,325 268,390 Q258,440 290,448 Q318,452 320,418 Q326,398 352,410 Z", HEAD)
	snout_tip = ellipse(292, 446, 26, 14, "#c9b8e6", INK, 7, rotate=-10)
	snout_lines = path("M300,366 q8,12 0,24", None, INK, 6) + path("M324,366 q8,12 0,24", None, INK, 6)
	rings = circle(450, 360, 36, LIGHT, None) + circle(540, 365, 36, LIGHT, None)
	face = eye(450, 360, 25) + eye(540, 365, 25) + smile(395, 448, 34) + blush(565, 425, 24, 13)
	# Tablet with a picture-symbol grid.
	tablet = rect(450, 540, 260, 200, TABLET, INK, 12, r=26, rotate=-6) \
		+ rect(472, 560, 216, 160, "#ffffff", INK, 6, r=14, rotate=-6)
	cells = [(510, 600), (580, 595), (650, 590), (515, 670), (585, 665), (655, 660)]
	kinds = ["circle", "heart", "star", "square", "tri", "dot"]
	symbols = "".join(symbol(k, x, y) for (x, y), k in zip(cells, kinds))
	tap_arm = path("M745,640 Q700,600 668,606", None, INK, 44) + path("M745,640 Q700,600 668,606", None, DARK, 28)
	paw_tap = tap_arm + ellipse(662, 606, 24, 20, DARK, INK, 8, rotate=-30) + ellipse(468, 730, 40, 32, DARK)
	tap_marks = path("M632,572 l-12,-14", None, INK, 6) + path("M626,594 l-20,-2", None, INK, 6)
	bubble = path("M660,180 Q660,130 710,130 L810,130 Q860,130 860,180 L860,260 Q860,310 810,310 L740,310 "
		"L700,360 L710,310 Q660,310 660,260 Z", "#ffffff") + heart(760, 228, 34, "#ff7a9c", INK, 7)
	return group(back_legs, body, saddle, bubble, tablet, symbols, paw_tap, tap_marks, ears, head, snout, snout_lines,
		snout_tip, rings, face)
