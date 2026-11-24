"""Invite a Friend: an open envelope with a heart seal and a step-free doorway invitation."""
from art_lib import INK, circle, group, heart, path, polygon, rect

STYLE = "mint"

CREAM = "#fff6e3"
CREAM_DARK = "#f3dfbd"
MINT = "#7fd6b3"
BERRY = "#e0679a"
LIGHT = "#ffe9a3"


def draw() -> str:
	back = rect(250, 500, 540, 360, CREAM_DARK, INK, 10, 24)
	flap = polygon([(250, 510), (520, 330), (790, 510)], CREAM_DARK)

	# Invitation card with a step-free doorway drawing.
	card = rect(325, 215, 390, 470, "#ffffff", INK, 10, 22)
	door_frame = path("M430,560 L430,360 Q430,290 520,290 Q610,290 610,360 L610,560 Z", MINT)
	door_light = path("M455,560 L455,370 Q455,318 520,318 Q585,318 585,370 L585,560 Z", LIGHT, INK, 7)
	door_panel = polygon([(585, 370), (650, 345), (650, 585), (585, 560)], BERRY, INK, 7)
	knob = circle(636, 470, 8, "#ffffff", None)
	ground = path("M360,560 L680,560", None, INK, 8)
	path_mat = path("M455,560 L585,560 L620,600 L420,600 Z", "#bfeedd", INK, 6)
	inside_heart = heart(520, 440, 34, "#ff8fb1", INK, 6)

	front = path("M250,520 L520,705 L790,520 L790,836 Q790,860 766,860 L274,860 Q250,860 250,836 Z", CREAM)
	fold_l = path("M250,860 L470,690", None, CREAM_DARK, 8)
	fold_r = path("M790,860 L570,690", None, CREAM_DARK, 8)
	seal = circle(520, 712, 62, BERRY) + heart(520, 712, 34, "#ffd6e5", INK, 6)

	floaters = heart(262, 330, 38, "#ff8fb1") + heart(790, 300, 30, MINT)
	return group(back, flap, card, ground, path_mat, door_frame, door_light, inside_heart, door_panel, knob,
		front, fold_l, fold_r, seal, floaters)
