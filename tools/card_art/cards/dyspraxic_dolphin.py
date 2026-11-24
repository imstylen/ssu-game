"""Dyspraxic Dolphin: smiling dolphin mid-leap holding a waterproof step-by-step picture card."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, eye, group, path, rect, star, text  # noqa: E402
from _group2_helpers import bubble  # noqa: E402

STYLE = "sky"

BLUE = "#7cb8e8"
BELLY = "#e4f3fd"
TEAL = "#3fb3b0"
CORAL = "#ff8a73"


def _dolphin() -> str:
	"""Dolphin drawn horizontally, head to the right, centred near (0, 0)."""
	fin = path("M-40,-100 Q0,-190 60,-205 Q40,-150 70,-105 Z", BLUE)
	flukes = path("M-250,0 Q-320,-85 -385,-80 Q-335,-20 -345,5 Q-335,35 -385,85 Q-320,85 -250,15 Z", BLUE)
	body = path("M-270,-5 C-150,-100 80,-160 220,-80 Q285,-50 300,-12 L372,-2 Q385,14 365,26 L290,34 "
		"Q150,115 -50,75 Q-180,45 -270,15 Z", BLUE)
	belly = path("M-180,40 Q0,90 160,55 Q230,40 290,34 L365,26 Q300,60 200,82 Q50,110 -60,85 Q-150,70 -180,40 Z", BELLY, None)
	face = (eye(220, -40, 30) + path("M285,18 Q325,48 362,26", None, "#2e2236", 8)
		+ blush(250, 15, 22, 11))
	return group(fin, flukes, body, belly, face)


def _card() -> str:
	card = rect(540, 540, 270, 170, "#ffffff", INK, 10, 20, rotate=-8)
	edge = rect(554, 554, 242, 142, None, TEAL, 8, 14, rotate=-8)
	frames = ""
	for i, (fill, sym) in enumerate([(CORAL, "1"), ("#ffd95a", "2"), ("#8fd6a8", "3")]):
		cx = 605 + i * 72
		cy = 640 - i * 10
		frames += rect(cx - 28, cy - 45, 56, 72, fill, INK, 6, 10, rotate=-8) + text(cx, cy + 6, sym, 40)
	arrows = path("M633,610 L647,608 M705,600 L719,598", None, INK, 6)
	return group(card, edge, frames, arrows)


def draw() -> str:
	dolphin = group(_dolphin(), transform="translate(500 470) rotate(-28) scale(0.85)")
	flipper = path("M590,480 Q650,500 665,575 Q630,580 600,540 Q585,510 590,480 Z", BLUE)
	wave = (path("M180,900 Q190,780 300,770 Q380,765 400,820 Q360,800 345,830 Q420,850 520,810 "
		"Q650,760 760,800 Q840,830 850,900 Z", TEAL)
		+ path("M300,770 Q380,765 400,820 Q360,800 345,830", "#ffffff", INK, 8)
		+ path("M230,870 Q400,860 520,880 M600,860 Q700,845 800,870", None, "#a9e3e0", 10))
	bubbles = bubble(240, 640, 24) + bubble(280, 570, 14) + bubble(830, 520, 18) + bubble(800, 460, 11)
	return group(bubbles, dolphin, _card(), flipper, wave, star(250, 300, 32, "#ffd95a"))
