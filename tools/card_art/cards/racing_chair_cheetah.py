"""Racing-Chair Cheetah: a cheetah leaning into a sleek three-wheeled racing wheelchair."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _group3_helpers import tube  # noqa: E402
from art_lib import INK, blush, circle, ellipse, eye, group, path, rect, smile, star

STYLE = "peach"

GOLD = "#f5c35c"
CREAM = "#fff2d6"
SPOT = "#5a3f3a"
CHAR = "#3f3a4a"
FRAME = "#ff7a59"
BAND = "#6ea9dc"

HUB = (360, 690)


def draw() -> str:
	hx, hy = HUB
	track = (path("M180,880 Q512,820 850,868 L850,912 Q512,866 180,922 Z", "#e88a6a")
		+ path("M200,896 Q512,846 840,888", None, "#ffffff", 6))
	speed = "".join(path(f"M{x1},{y} L{x2},{y}", None, INK, 10) for x1, x2, y in
		((180, 250, 560), (182, 230, 640), (190, 260, 360)))
	# Tail streaming out behind, with dark rings and tip
	tail = tube("M400,470 C340,420 300,460 250,420 C220,396 220,360 240,340", GOLD, 26)
	tail_rings = (path("M290,440 L300,470", None, SPOT, 8) + path("M250,408 L230,430", None, SPOT, 8)
		+ circle(240, 340, 16, SPOT))
	# Long boom to the single front wheel
	frame = tube(f"M{hx + 60},{hy + 40} L800,808", FRAME, 20)
	front_wheel = circle(805, 812, 48, CHAR) + circle(805, 812, 18, "#d0d7e3")
	# Torso stretched forward over the knees, racing-bib on the side
	body = ellipse(500, 500, 165, 82, GOLD, rotate=-12)
	spots = "".join(circle(x, y, 10, SPOT, None) for x, y in ((420, 500), (460, 470), (520, 450), (560, 480), (480, 525)))
	bib = rect(500, 475, 70, 56, "#ffffff", INK, 7, 8, rotate=-12) + star(535, 503, 18, "#ffd95a", INK, 5)
	# Bucket seat / cage where the cheetah kneels
	cage = path("M420,560 L600,560 Q630,560 620,600 L590,660 Q580,680 550,680 L440,680 Z", "#ffd2b8")
	cage_bar = path("M455,575 L455,670 M505,575 L505,670 M555,575 L550,670", None, "#e3a98a", 8)
	rear_wheel = (circle(hx, hy, 165, CHAR) + circle(hx, hy, 140, "#ffe9d8", INK, 8)
		+ circle(hx, hy, 116, None, FRAME, 14) + circle(hx, hy, 24, "#d0d7e3")
		+ path(f"M{hx - 80},{hy - 80} A112,112 0 0,1 {hx + 40},{hy - 106}", None, "#ffffff", 10, extra='opacity="0.8"'))
	# Arm pushing the rim at the front of the wheel
	arm = tube("M600,470 C610,540 540,600 470,612", GOLD, 38)
	glove = circle(468, 614, 30, BAND)
	ears = circle(620, 330, 30, GOLD) + circle(750, 318, 30, GOLD)
	head = circle(690, 405, 108, GOLD)
	head_spots = "".join(circle(x, y, 7, SPOT, None) for x, y in ((655, 320), (685, 312), (715, 318)))
	muzzle = ellipse(706, 452, 56, 38, CREAM, None)
	tears = path("M650,410 Q658,448 672,465", None, SPOT, 8) + path("M752,402 Q756,438 742,460", None, SPOT, 8)
	headband = path("M590,372 Q685,322 786,360", None, BAND, 22) + path("M590,372 Q685,322 786,360", None, INK, 4)
	face = (eye(650, 398, 24) + eye(748, 394, 24) + ellipse(706, 442, 13, 9, "#2e2236", None)
		+ smile(706, 460, 44, open_mouth=True) + blush(622, 448, 20, 10) + blush(778, 444, 20, 10))
	return group(track, speed, tail, tail_rings, frame, front_wheel, body, spots, bib, cage, cage_bar, rear_wheel,
		arm, glove, ears, head, head_spots, muzzle, tears, headband, face)
