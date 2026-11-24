"""Tripod Tiger: a proud three-legged tiger standing steady in a protective stance."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _group3_helpers import tube  # noqa: E402
from art_lib import INK, blush, circle, ellipse, eye, group, heart, path, polygon, smile

STYLE = "berry"

ORANGE = "#f7983f"
CREAM = "#fff1dd"
STRIPE = "#3d2a3a"
GRASS = "#7ccf8a"


def draw() -> str:
	grass = "".join(path(f"M{x},900 Q{x + lean},720 {x + lean * 2},{h}", None, GRASS, 22)
		for x, lean, h in ((210, -10, 640), (250, 10, 600), (780, -12, 610), (820, 8, 650), (740, 14, 690)))
	tail = tube("M680,600 C780,560 820,470 790,380 C775,340 820,320 830,360", ORANGE, 40)
	tail_stripes = path("M812,470 L846,478", None, STRIPE, 10) + path("M800,410 L834,404", None, STRIPE, 10)
	# Hind legs behind, wide stance
	hind = (path("M310,640 L300,850 L380,850 L392,660 Z", ORANGE) + ellipse(340, 858, 56, 28, ORANGE)
		+ path("M690,640 L700,850 L620,850 L608,660 Z", ORANGE) + ellipse(660, 858, 56, 28, ORANGE))
	body = ellipse(500, 620, 220, 150, ORANGE)
	body_stripes = "".join(path(d, None, STRIPE, 12) for d in (
		"M300,560 Q330,600 310,640", "M330,520 Q370,560 350,600",
		"M700,560 Q670,600 690,640", "M670,520 Q630,560 650,600",
	))
	chest = ellipse(500, 650, 110, 120, CREAM, None)
	# The single, centred front leg: planted and strong
	front = path("M450,640 L440,870 L560,870 L550,640 Z", ORANGE) + ellipse(500, 876, 78, 34, ORANGE)
	toes = path("M470,866 L470,890 M500,866 L500,892 M530,866 L530,890", None, INK, 7)
	front_stripes = path("M448,730 L480,736", None, STRIPE, 10) + path("M552,770 L520,776", None, STRIPE, 10)
	ears = (circle(375, 265, 52, ORANGE) + circle(375, 268, 26, "#ff9fb8", None)
		+ circle(625, 265, 52, ORANGE) + circle(625, 268, 26, "#ff9fb8", None))
	head = ellipse(500, 400, 175, 150, ORANGE)
	head_stripes = (path("M500,258 L500,300 M465,262 L470,296 M535,262 L530,296", None, STRIPE, 11)
		+ path("M332,390 L372,398 M336,430 L372,428", None, STRIPE, 10)
		+ path("M668,390 L628,398 M664,430 L628,428", None, STRIPE, 10))
	muzzle = ellipse(460, 465, 58, 44, CREAM, None) + ellipse(540, 465, 58, 44, CREAM, None)
	brows = path("M400,350 Q425,340 450,352", None, INK, 9) + path("M600,350 Q575,340 550,352", None, INK, 9)
	face = (eye(425, 395, 28) + eye(575, 395, 28) + polygon([(482, 440), (518, 440), (500, 460)], "#ff7f9e", INK, 7)
		+ smile(500, 472, 64, open_mouth=True) + blush(385, 450, 28, 14) + blush(615, 450, 28, 14))
	return group(grass, tail, tail_stripes, hind, body, body_stripes, chest, front, toes, front_stripes,
		ears, head, head_stripes, muzzle, brows, face, heart(500, 640, 34))
