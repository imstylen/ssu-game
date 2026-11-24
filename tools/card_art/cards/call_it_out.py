"""Call It Out: a megaphone blasting an exclamation burst that cracks a brick wall."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, circle, ellipse, group, line, path, polygon, rect  # noqa: E402
from _group4_helpers import head, limb, paw  # noqa: E402

STYLE = "berry"

BRICK = "#c4bccc"
BRICK_DARK = "#a59cb0"
BERRY = "#e8578f"
FUR = "#c89b6d"


def _wall() -> str:
	x0, y0, x1, y1 = 600, 220, 845, 850
	clip = f'<clipPath id="callwall"><rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" rx="18"/></clipPath>'
	bricks = rect(x0, y0, x1 - x0, y1 - y0, BRICK, None)
	rows = 9
	h = (y1 - y0) / rows
	for row in range(rows):
		y = y0 + row * h
		if row:
			bricks += line(x0, round(y, 1), x1, round(y, 1), INK, 7)
		off = 0 if row % 2 == 0 else 60
		for x in range(x0 + off + 120, x1, 120):
			bricks += line(x, round(y, 1), x, round(y + h, 1), INK, 7)
		if row % 3 == 1:
			bricks += rect(x0 + off + 12, round(y + 10, 1), 90, 14, BRICK_DARK, None, 0, 7)
	crack = path("M600,480 L650,460 L630,410 L690,380 L670,330 L720,290 M650,460 L700,500 L680,560 L740,590 M630,410 L585,370",
		None, INK, 10)
	wall = clip + f'<g clip-path="url(#callwall)">{bricks}{crack}</g>' + rect(x0, y0, x1 - x0, y1 - y0, None, INK, 12, 18)
	chunks = (rect(560, 250, 60, 36, BRICK, INK, 8, 6, rotate=-25) + rect(812, 160, 50, 30, BRICK, INK, 8, 6, rotate=20)
		+ rect(565, 790, 46, 28, BRICK, INK, 8, 6, rotate=15))
	return wall + chunks


def _burst(cx, cy) -> str:
	pts = []
	for i in range(22):
		r = 135 if i % 2 == 0 else 88
		a = math.pi * i / 11 - math.pi / 2
		pts.append((round(cx + r * math.cos(a), 1), round(cy + r * math.sin(a), 1)))
	burst = polygon(pts, "#ffd84a", INK, 10)
	bang = rect(cx - 17, cy - 72, 34, 92, INK, None, 0, 17) + circle(cx, cy + 52, 20, INK, None)
	return burst + bang


def _megaphone() -> str:
	mouth = rect(210, 520, 54, 80, "#ffd84a", INK, 10, 14)
	cone = polygon([(258, 520), (470, 410), (470, 710), (258, 600)], BERRY, INK, 12)
	stripe = polygon([(330, 484), (372, 462), (372, 659), (330, 637)], "#ffffff", None)
	bell = ellipse(470, 560, 44, 152, "#ff9cc2", INK, 12) + ellipse(478, 560, 22, 112, "#c23b72", None)
	handle = rect(320, 590, 46, 120, "#4b3159", INK, 8, 16, rotate=12)
	return group(handle, mouth, cone, stripe, bell, transform="translate(20 -60) rotate(-10 340 560)")


def _fox() -> str:
	fur, inner = "#f08a4b", "#fff1e0"
	tail = path("M215,880 q-60,-5 -50,-75 q40,30 75,45 Z", fur) + path("M171,822 q-6,-12 -6,-17 q16,12 26,18 Z", "#fff1e0", None)
	body = ellipse(280, 855, 88, 50, fur) + ellipse(280, 868, 50, 30, inner, None)
	face = head(268, 770, 70, "fox", fur, inner) + ellipse(268, 806, 15, 13, "#c94f6d", "#2e2236", 6)
	arm = limb(338, 845, 372, 665, fur, 36) + paw(373, 652, 26, fur, toes=False)
	return tail + body + face + arm


def draw() -> str:
	sound = path("M560,300 q30,-30 70,-30", None, INK, 12) + path("M565,665 q30,30 70,30", None, INK, 12)
	return group(_wall(), _megaphone(), _fox(), _burst(585, 482), sound)
