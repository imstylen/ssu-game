"""Quiet Room: a dim cozy nook with a beanbag, a soft lamp and a sleepy moon sign."""
from art_lib import INK, blush, circle, closed_eye, ellipse, group, path, polygon, rect, smile, sparkle

STYLE = "lavender"

NAVY = "#3f3d74"
NAVY_LIGHT = "#55529a"
LAV = "#b9a2ea"
LAV_DARK = "#9a7fd6"
YELLOW = "#ffe38a"
CAT = "#f7c79a"


def draw() -> str:
	alcove = path("M215,860 L215,470 A300,300 0 0 1 815,470 L815,860 Z", NAVY)
	inner = path("M255,860 L255,480 A260,260 0 0 1 775,480 L775,860 Z", NAVY_LIGHT, None)
	stars = (sparkle(330, 520, 16) + sparkle(700, 330, 14) + sparkle(390, 380, 11) + sparkle(745, 520, 10)
		+ circle(620, 300, 5, "#ffffff", None) + circle(300, 640, 5, "#ffffff", None))
	rug = ellipse(500, 850, 250, 32, "#f5b8d3")

	# Hanging crescent moon sign.
	strings = path("M470,215 L480,300", None, INK, 6) + path("M570,215 L560,300", None, INK, 6)
	moon = path("M560,290 A85,85 0 1 0 560,440 A70,70 0 1 1 560,290 Z", YELLOW)
	moon_face = closed_eye(486, 360, 26) + blush(478, 392, 16, 9)

	# Floor lamp with a warm glow.
	glow = circle(690, 475, 105, "#6f6bb8", None) + circle(690, 475, 72, "#8a84cc", None)
	lamp = (rect(682, 520, 16, 300, "#d9cdf5", INK, 7, 6) + ellipse(690, 828, 52, 18, "#d9cdf5")
		+ polygon([(640, 520), (740, 520), (715, 430), (665, 430)], YELLOW))

	# Beanbag with a sleepy cat wearing headphones.
	bag = path("M265,830 C250,700 330,620 430,640 C470,650 520,650 560,630 C640,600 660,740 640,830 Z", LAV)
	bag_shade = path("M300,812 C320,770 360,760 420,780", None, LAV_DARK, 8)
	cat_body = ellipse(455, 640, 90, 62, CAT)
	tail = path("M535,660 Q600,640 585,600", None, INK, 26) + path("M535,660 Q600,640 585,600", None, CAT, 12)
	ears = polygon([(395, 560), (405, 495), (445, 545)], CAT) + polygon([(505, 545), (540, 495), (545, 565)], CAT)
	head = circle(470, 575, 72, CAT)
	phones_band = path("M398,560 Q470,470 542,560", None, INK, 26) + path("M398,560 Q470,470 542,560", None, "#ff9fc0", 12)
	phones = ellipse(400, 580, 22, 34, "#ff9fc0") + ellipse(540, 580, 22, 34, "#ff9fc0")
	face = (closed_eye(445, 580, 30) + closed_eye(498, 580, 30) + smile(471, 605, 26) + blush(432, 608, 15, 8)
		+ blush(510, 608, 15, 8))
	zz = path("M560,470 L590,470 L560,500 L590,500", None, "#ffffff", 7) + path("M600,420 L620,420 L600,440 L620,440", None, "#ffffff", 6)

	return group(alcove, inner, stars, rug, glow, lamp, bag, bag_shade, tail, cat_body, ears, head, face,
		phones_band, phones, zz, strings, moon, moon_face)
