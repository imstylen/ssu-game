"""Oxygen Owl: a wise owl with a portable-oxygen backpack and cannula, giving a pep talk."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _group3_helpers import tube  # noqa: E402
from art_lib import INK, blush, circle, ellipse, eye, group, path, polygon, rect, smile, star

STYLE = "lavender"

BROWN = "#a0714f"
DARK = "#7a5238"
CREAM = "#f4e0c2"
DISC = "#ecd3b0"
TUBE = "#a9dcf7"


def draw() -> str:
	moon = path("M800,160 A60,60 0 1,0 860,250 A48,48 0 1,1 800,160 Z", "#fff3b8")
	stars = star(230, 230, 30) + star(845, 470, 20)
	tank = (rect(232, 360, 84, 250, "#8cc8f0", INK, 10, 34, rotate=-12)
		+ rect(254, 318, 40, 50, "#d0d7e3", INK, 9, 8, rotate=-12)
		+ rect(246, 430, 64, 18, "#ffffff", None, 0, 6, rotate=-12, extra='opacity="0.5"'))
	branch = rect(220, 820, 580, 46, "#9c6b45", INK, 10, 23) + ellipse(760, 815, 50, 22, "#7fcf9a", rotate=-20)
	body = ellipse(500, 590, 195, 240, BROWN)
	belly = ellipse(500, 650, 128, 160, CREAM, None)
	scallops = "".join(path(f"M{x - 18},{y} Q{x},{y + 18} {x + 18},{y}", None, "#c9a27a", 7)
		for x, y in ((460, 600), (540, 600), (420, 660), (500, 660), (580, 660), (460, 720), (540, 720)))
	tufts = polygon([(345, 400), (360, 290), (420, 370)], BROWN) + polygon([(655, 400), (640, 290), (580, 370)], BROWN)
	head_top = ellipse(500, 440, 175, 130, BROWN)
	discs = circle(432, 445, 82, DISC) + circle(568, 445, 82, DISC)
	face = eye(432, 445, 40) + eye(568, 445, 40) + blush(392, 512, 24, 12) + blush(608, 512, 24, 12)
	beak = polygon([(478, 492), (522, 492), (500, 536)], "#ffb547", INK, 8)
	strap = tube("M318,470 Q380,470 392,560", "#b48ee0", 22, 6)
	cannula = (tube("M470,506 C420,520 372,520 346,500 C318,478 300,420 288,350", TUBE, 8, 4)
		+ tube("M530,506 C580,520 628,520 654,500", TUBE, 8, 4)
		+ ellipse(500, 500, 34, 12, TUBE, INK, 5))
	left_wing = path("M320,520 C270,600 280,720 340,780 C370,700 380,620 360,540 Z", DARK)
	# Raised wing for the pep talk
	right_wing = path("M660,560 C720,500 770,420 760,320 C740,300 720,320 712,340 C700,320 680,320 672,344 "
		"C660,330 640,340 640,360 C640,420 630,480 610,520 Z", DARK)
	motion = path("M790,330 Q815,360 800,395", None, INK, 8) + path("M770,280 Q800,270 815,290", None, INK, 8)
	feet = "".join(ellipse(x, 830, 18, 26, "#ffb547") for x in (440, 470, 530, 560))
	return group(moon, stars, tank, branch, left_wing, body, belly, scallops, tufts, head_top, discs, face, beak,
		cannula, strap, right_wing, motion, feet, smile(500, 552, 30))
