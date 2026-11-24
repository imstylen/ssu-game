"""Cane-Tapping Kiwi: blind, navigating confidently with a long white cane."""
from art_lib import INK, blush, circle, ellipse, eye, group, path, smile

STYLE = "peach"

FEATHER = "#8b5e3c"
FEATHER_LIGHT = "#a8774f"
BEAK = "#f1d3a6"
LEG = "#f0b080"
RED = "#e0484f"


def stroke2(d, color, w):
	return path(d, None, INK, w + 18) + path(d, None, color, w)


def foot(x, y, flip=1):
	d = f"M{x},{y} L{x - 40 * flip},{y + 14} M{x},{y} L{x},{y + 22} M{x},{y} L{x + 40 * flip},{y + 14}"
	return path(d, None, INK, 22) + path(d, None, LEG, 10)


def draw() -> str:
	legs = stroke2("M400,740 L380,850", LEG, 22) + stroke2("M520,740 L545,850", LEG, 22)
	feet = foot(380, 856) + foot(545, 856)
	body = ellipse(460, 590, 230, 190, FEATHER)
	texture = "".join(path(f"M{x},{y} q14,18 28,0", None, "#6c4429", 7) for x, y in [
		(330, 560), (380, 650), (450, 700), (520, 640), (300, 640), (420, 590), (560, 720), (360, 720)])
	head = circle(620, 440, 110, FEATHER_LIGHT)
	beak = path("M690,470 Q790,520 840,610 Q845,625 830,625 Q770,560 680,505 Z", BEAK)
	nostril = circle(832, 614, 5, INK, None)
	face = eye(625, 430, 28) + smile(650, 485, 34) + blush(590, 480, 24, 13)
	wing = ellipse(560, 600, 46, 34, FEATHER_LIGHT, rotate=-30)
	# Long white cane with a red lower section and a rolling tip.
	cane = stroke2("M560,600 L790,860", "#ffffff", 16) + path("M708,768 L790,860", None, RED, 16)
	grip = stroke2("M545,584 L575,618", "#3a3a4a", 22)
	tip = circle(796, 868, 16, "#3a3a4a", INK, 6)
	ripples = path("M745,900 Q796,925 847,900", None, "#e38350", 9) + path("M720,918 Q796,955 872,918", None, "#e38350", 7)
	return group(ripples, legs, feet, body, texture, head, beak, nostril, face, cane, grip, tip, wing)
