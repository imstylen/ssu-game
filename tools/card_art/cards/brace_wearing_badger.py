"""Brace-Wearing Badger: badger in lavender knee and wrist braces, holding out a rolled-up plan scroll."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, ellipse, eye, group, path, rect, smile, star  # noqa: E402
from _group2_helpers import band, limb  # noqa: E402

STYLE = "lavender"

GREY = "#9a96a6"
DARK = "#3b3645"
WHITE = "#f7f4ee"
CREAM = "#f3e6cc"
BRACE = "#b48ee6"
STRAP = "#7d5bb5"


def draw() -> str:
	mound = path("M200,880 Q230,800 330,800 L690,800 Q800,800 830,880 Z", "#c9a77f")
	# legs with a knee brace on the viewer's left leg
	legs = (limb("M420,700 L405,840", DARK, 80) + limb("M590,700 L605,840", DARK, 80)
		+ ellipse(395, 856, 62, 30, DARK) + ellipse(615, 856, 62, 30, DARK))
	knee = band("M411,758 L405,808", BRACE, 92) + path("M368,783 L450,783", None, STRAP, 10) + circle(409, 783, 13, "#ffffff", INK, 5)
	body = ellipse(505, 610, 170, 190, GREY)
	belly = ellipse(505, 650, 100, 130, CREAM, None)
	# arm on the left resting on the belly
	arm_l = limb("M370,560 Q350,650 420,690", DARK, 66)
	# arm on the right holding out the scroll, with a wrist brace
	arm_r = limb("M630,560 Q700,600 730,520", DARK, 66)
	wrist = band("M712,566 L726,534", BRACE, 80) + path("M690,548 L752,560", None, STRAP, 9)
	scroll = (rect(650, 395, 190, 90, "#fff6dc", INK, 10, 12, rotate=-12)
		+ ellipse(660, 456, 26, 50, "#ffe9b0", INK, 10, rotate=-12)
		+ ellipse(838, 418, 26, 50, "#ffe9b0", INK, 10, rotate=-12)
		+ path("M690,430 L800,407 M695,452 L780,435", None, "#c9b48a", 8)
		+ rect(735, 410, 22, 92, "#ff7a9c", INK, 6, 4, rotate=-12))
	paw_r = circle(730, 500, 36, DARK)
	ears = (circle(350, 285, 30, DARK) + circle(660, 285, 30, DARK)
		+ path("M326,272 Q345,250 372,262", None, WHITE, 8) + path("M684,272 Q665,250 638,262", None, WHITE, 8))
	head_d = "M335,330 Q335,215 505,212 Q675,215 675,330 Q670,440 505,492 Q340,440 335,330 Z"
	head = path(head_d, WHITE)
	left = "M372,245 Q400,222 432,226 Q470,330 484,445 Q470,458 455,448 Q392,350 372,245 Z"
	right = "M638,245 Q610,222 578,226 Q540,330 526,445 Q540,458 555,448 Q618,350 638,245 Z"
	stripes = path(left, DARK, None) + path(right, DARK, None)
	head_line = path(head_d, None)
	eyes = circle(430, 345, 31, WHITE, None) + circle(580, 345, 31, WHITE, None) + eye(430, 345, 24) + eye(580, 345, 24)
	face = (ellipse(505, 440, 30, 20, "#2e2236", None) + smile(505, 462, 40, open_mouth=True)
		+ blush(392, 410, 22, 11) + blush(618, 410, 22, 11))
	return group(mound, legs, knee, body, belly, arm_l, arm_r, wrist, scroll, paw_r, ears, head, stripes, head_line,
		eyes, face, star(260, 520, 34, "#ffd95a"))
