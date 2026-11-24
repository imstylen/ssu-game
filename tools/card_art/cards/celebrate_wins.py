"""Celebrate Wins: a party popper bursting confetti over a smiling star trophy."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, ellipse, eye, group, polygon, rect, smile, star  # noqa: E402
from _group4_helpers import confetti  # noqa: E402

STYLE = "peach"

GOLD = "#ffcc3f"
GOLD_DARK = "#e8a92a"
BERRY = "#e8578f"


def _popper() -> str:
	tip = (240, 860)
	ax, ay = 0.669, -0.743
	px, py = 0.743, 0.669
	cx, cy = 435, 643
	r = 80

	def edge(t, s):
		bx, by = tip[0] + (cx - tip[0]) * t, tip[1] + (cy - tip[1]) * t
		return (round(bx + px * r * t * s, 1), round(by + py * r * t * s, 1))

	cone = polygon([tip, edge(1, 1), edge(1, -1)], BERRY, INK, 12)
	stripes = ""
	for t0, t1 in ((0.32, 0.48), (0.66, 0.82)):
		stripes += polygon([edge(t0, 1), edge(t1, 1), edge(t1, -1), edge(t0, -1)], "#ffffff", None)
	rim = ellipse(cx, cy, r + 6, 30, GOLD, INK, 10, rotate=42)
	return cone + stripes + rim


def _trophy() -> str:
	base = rect(540, 790, 240, 60, BERRY, INK, 10, 14) + rect(575, 735, 170, 62, "#ff9cc2", INK, 10, 12)
	base += rect(625, 752, 70, 26, GOLD, INK, 6, 8)
	stem = polygon([(635, 600), (685, 600), (700, 738), (620, 738)], GOLD_DARK, INK, 10)
	body = star(660, 460, 178, GOLD, INK, 12, inner=0.5) + star(660, 470, 110, "#ffe27a", None, 0, inner=0.5)
	face = eye(625, 462, 18) + eye(695, 462, 18) + smile(660, 500, 46, open_mouth=True) + blush(598, 500, 20, 11) + blush(722, 500, 20, 11)
	return base + stem + body + face


def draw() -> str:
	bits = [(480, 560, "r", 30), (520, 470, "c", 0), (440, 520, "s", -50), (560, 300, "r", -20), (470, 380, "s", -40),
		(400, 430, "c", 0), (620, 230, "s", 10), (760, 225, "r", 45), (840, 320, "c", 0), (360, 330, "r", 70),
		(500, 250, "c", 0), (850, 560, "s", 60), (300, 520, "r", -30), (700, 190, "c", 0), (420, 270, "s", 20),
		(220, 650, "c", 0)]
	streamers = ('<path d="M470,600 C520,520 430,480 500,400 C560,330 500,280 580,220" fill="none" stroke="#4b3159" '
		'stroke-width="24" stroke-linecap="round"/><path d="M470,600 C520,520 430,480 500,400 C560,330 500,280 580,220" '
		'fill="none" stroke="#7fdcc0" stroke-width="12" stroke-linecap="round"/>')
	return group(_trophy(), streamers, _popper(), confetti(bits, ["#ff86b0", "#ffd84a", "#7fdcc0", "#8cc8f5", "#b79cf0", "#ffb870"]))
