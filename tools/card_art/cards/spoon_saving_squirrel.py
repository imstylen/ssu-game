"""Spoon-Saving Squirrel: paces energy with spoon theory, hugging a big wooden spoon."""
from art_lib import INK, blush, circle, ellipse, eye, group, path, polygon, rect, smile

STYLE = "mint"

FUR = "#d9773a"
CREAM = "#f8e3c4"
WOOD = "#e6b779"
WOOD_DARK = "#c48f4f"
BAG = "#6fcfb0"


def spoon(x1, y1, x2, y2, bowl_rx, bowl_ry, angle, width=30):
	handle = path(f"M{x1},{y1} L{x2},{y2}", None, INK, width + 18) + path(f"M{x1},{y1} L{x2},{y2}", None, WOOD, width)
	bowl = ellipse(x2, y2, bowl_rx, bowl_ry, WOOD, INK, 10, rotate=angle)
	inner = ellipse(x2, y2 - 4, bowl_rx * 0.62, bowl_ry * 0.66, WOOD_DARK, None, rotate=angle)
	return handle + bowl + inner


def draw() -> str:
	tail = path("M560,820 C720,860 840,720 800,560 C770,450 690,420 700,320 C710,240 800,230 790,170 "
		"C740,120 620,160 610,280 C600,370 650,450 610,540 C580,610 530,680 560,820 Z", FUR)
	tail_hi = path("M650,700 C740,680 760,580 730,500 C705,440 650,400 660,320", None, "#f0a066", 18)
	bag = rect(640, 690, 170, 150, BAG, INK, 10, r=30) + path("M650,720 Q725,780 800,720", None, INK, 8)
	bag_spoons = (path("M690,690 L670,600", None, INK, 22) + path("M690,690 L670,600", None, WOOD, 10)
		+ ellipse(668, 585, 22, 30, WOOD, INK, 8, rotate=-12)
		+ path("M750,690 L770,610", None, INK, 22) + path("M750,690 L770,610", None, WOOD, 10)
		+ ellipse(772, 595, 22, 30, WOOD, INK, 8, rotate=12))
	strap = path("M660,700 Q560,560 520,470", None, "#3e9c80", 14)
	body = ellipse(470, 640, 165, 205, FUR)
	belly = ellipse(470, 670, 105, 150, CREAM, None)
	feet = ellipse(390, 850, 70, 34, FUR) + ellipse(560, 850, 70, 34, FUR)
	big_spoon = spoon(600, 860, 300, 340, 72, 96, -30)
	paws = ellipse(395, 585, 44, 36, FUR, rotate=-30) + ellipse(520, 640, 44, 36, FUR, rotate=-30)
	ears = polygon([(375, 300), (360, 190), (440, 260)], FUR) + polygon([(585, 300), (600, 190), (520, 260)], FUR) \
		+ polygon([(382, 280), (372, 215), (420, 262)], "#f2b8a8", None, 0) \
		+ polygon([(578, 280), (588, 215), (540, 262)], "#f2b8a8", None, 0)
	head = circle(480, 390, 135, FUR)
	muzzle = ellipse(480, 445, 82, 58, CREAM, None)
	face = eye(428, 380, 28) + eye(532, 380, 28) + ellipse(480, 428, 20, 14, "#2e2236", None) \
		+ smile(480, 450, 40) + blush(392, 440) + blush(568, 440)
	return group(tail, tail_hi, bag_spoons, bag, body, belly, strap, feet, big_spoon, paws, ears, head, muzzle, face)
