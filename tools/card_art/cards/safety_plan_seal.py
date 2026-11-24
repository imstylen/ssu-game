"""Safety-Plan Seal: grey seal sitting up on an ice floe, proudly holding a seizure-plan clipboard,
medical-ID band on the waving flipper."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, ellipse, eye, group, heart, path, rect, smile, text  # noqa: E402
from _group2_helpers import check  # noqa: E402

STYLE = "mint"

GREY = "#a7b1bd"
LIGHT = "#dfe5ea"
SPOT = "#7f8b99"
RED = "#e8505b"
ICE = "#eef8ff"


def draw() -> str:
	floe = (path("M200,830 L250,790 L780,786 L840,830 L820,895 L215,898 Z", "#bfe3f5")
		+ path("M200,830 L250,790 L780,786 L840,830 Z", ICE, INK, 8))
	tail = path("M600,800 Q700,760 780,800 Q740,830 700,830 Q760,860 740,880 Q660,860 600,840 Z", GREY)
	body = path("M330,820 Q270,640 340,470 Q400,360 500,360 Q600,360 650,470 Q720,640 660,820 Z", GREY)
	belly = ellipse(495, 650, 120, 165, LIGHT, None)
	spots = (circle(370, 560, 14, SPOT, None) + circle(352, 610, 9, SPOT, None)
		+ circle(640, 560, 12, SPOT, None) + circle(655, 700, 10, SPOT, None))
	head = ellipse(495, 345, 160, 140, GREY)
	muzzle = ellipse(495, 405, 82, 54, LIGHT, None)
	face = (eye(435, 330, 30) + eye(555, 330, 30)
		+ ellipse(495, 382, 24, 16, "#2e2236", None)
		+ smile(495, 412, 52, open_mouth=True)
		+ blush(400, 395) + blush(590, 395)
		+ circle(455, 410, 4, SPOT, None) + circle(440, 420, 4, SPOT, None)
		+ circle(535, 410, 4, SPOT, None) + circle(550, 420, 4, SPOT, None))

	# Waving flipper (viewer's left) with red medical-ID band.
	wave_flipper = path("M345,520 Q250,470 235,370 Q290,380 330,430 Q370,470 380,520 Z", GREY)
	id_band = (path("M262,428 Q296,415 318,440", None, INK, 46).replace('stroke-linecap="round"', 'stroke-linecap="butt"')
		+ path("M262,428 Q296,415 318,440", None, RED, 30).replace('stroke-linecap="round"', 'stroke-linecap="butt"')
		+ circle(290, 426, 15, "#ffffff", INK, 5)
		+ rect(286, 416, 8, 20, RED, None) + rect(280, 422, 20, 8, RED, None))

	# Clipboard held against the chest by the other flipper.
	board = rect(540, 470, 230, 300, "#c8955a", INK, 10, 18, rotate=6)
	paper = rect(560, 505, 190, 245, "#ffffff", INK, 6, 8, rotate=6)
	clip = rect(610, 455, 90, 40, "#b8c0c8", INK, 8, 10, rotate=6)
	header = rect(575, 520, 160, 34, RED, None, 0, 6, rotate=6)
	lines = ""
	for i in range(3):
		y = 580 + i * 52
		x = 588 - i * 5
		lines += (rect(x, y, 30, 30, "#ffffff", INK, 5, 6, rotate=6)
			+ check(x + 2, y - 4, 1.0, "#2fa37f", 8)
			+ path(f"M{x + 45},{y + 18} L{x + 140},{y + 28}", None, "#c9c3d1", 9))
	clipboard = group(board, paper, clip, header, text(655, 547, "PLAN", 26, "#ffffff"), lines)
	hold_flipper = path("M505,600 Q585,600 615,645 Q620,685 580,695 Q530,690 505,660 Z", GREY)

	return group(floe, tail, body, belly, spots, wave_flipper, id_band, head, muzzle, face,
		clipboard, hold_flipper, heart(300, 250, 30, "#ff7a9c"))
