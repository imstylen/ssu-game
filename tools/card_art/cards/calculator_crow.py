"""Calculator Crow: glossy crow perched on a branch, wing tapping a big chunky calculator."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, ellipse, eye, group, path, rect, text  # noqa: E402

STYLE = "lavender"

BLACK = "#33395a"
GLOSS = "#5a6694"
LEMON = "#ffe066"
LAV = "#c9b2f0"


def _calculator() -> str:
	body = rect(560, 440, 240, 330, LEMON, INK, 10, 30)
	screen = rect(590, 470, 180, 70, "#d9f0d0", INK, 8, 12) + text(755, 523, "1+2=3", 40, INK, anchor="end")
	keys = ""
	for row in range(4):
		for col in range(3):
			x = 592 + col * 62
			y = 562 + row * 50
			fill = LAV if col < 2 else "#ff9fb8"
			keys += rect(x, y, 50, 38, fill, INK, 6, 10)
	return group(body, screen, keys)


def draw() -> str:
	branch = (path("M180,820 Q500,790 850,815", None, INK, 64) + path("M180,820 Q500,790 850,815", None, "#a0714c", 44)
		+ path("M300,808 Q290,760 250,740 Q300,745 315,790", "#8fd6a8", INK, 7)
		+ path("M800,812 Q830,770 860,770 Q850,805 815,820", "#8fd6a8", INK, 7))
	tail = path("M300,720 L240,880 L285,870 L300,900 L330,868 L360,885 L370,760 Z", BLACK)
	body = ellipse(410, 600, 160, 190, BLACK)
	gloss = path("M310,520 Q330,450 400,430", None, GLOSS, 16)
	belly = ellipse(420, 650, 90, 115, "#454d73", None)
	feet = path("M370,770 L360,805 M390,772 L392,808 M460,772 L455,806 M480,770 L490,804", None, "#e6a547", 12)
	tuft = path("M380,215 Q395,170 420,205 Q440,165 455,215", BLACK)
	head = circle(415, 330, 130, BLACK)
	head_gloss = path("M330,280 Q350,230 400,215", None, GLOSS, 14)
	eyes = circle(365, 325, 36, "#ffffff", None) + circle(470, 325, 36, "#ffffff", None) + eye(368, 327, 27) + eye(470, 327, 27)
	beak = path("M384,372 Q418,358 452,372 L424,436 Q418,444 412,436 Z", "#6e6a86")
	face = beak + blush(320, 385, 22, 11) + blush(515, 385, 22, 11)
	calc = _calculator()
	wing = path("M470,500 Q560,470 620,540 L660,575 Q668,592 650,595 L625,590 L640,612 Q640,628 622,624 "
		"L595,610 L600,630 Q592,645 575,632 Q520,620 480,600 Q440,560 470,500 Z", GLOSS)
	numbers = (text(250, 280, "7", 72, "#966cc9") + text(820, 360, "4", 64, "#966cc9")
		+ text(230, 520, "+", 72, "#966cc9") + text(830, 240, "9", 56, "#e3b51f"))
	return group(numbers, tail, branch, body, gloss, belly, feet, tuft, head, head_gloss, eyes, face, calc, wing)
