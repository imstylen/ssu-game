"""Build a Ramp: a wooden ramp up to an open door with an access sign and a hammer."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, circle, group, heart, line, path, polygon, rect  # noqa: E402
from _group5_helpers import access_symbol  # noqa: E402

STYLE = "peach"

WOOD = "#e2a868"
WOOD_DARK = "#b97a42"
BLOCK = "#f6c7a5"
SKY = "#6ea9dc"
LIGHT = "#ffe9a3"
DOOR = "#8fc6ee"


def draw() -> str:
	# Raised porch block with the door.
	block = rect(560, 520, 270, 340, BLOCK, INK, 10, 18)
	block_line = line(560, 690, 830, 690, "#e3a882", 8)
	frame = rect(600, 225, 200, 300, WOOD_DARK, INK, 10, 16)
	opening = rect(625, 250, 150, 270, LIGHT, INK, 8, 10)
	door_panel = polygon([(625, 250), (575, 280), (575, 545), (625, 520)], DOOR, INK, 8)
	knob = circle(590, 410, 8, "#ffffff", None)
	glow = heart(700, 370, 34, "#ff9fb8", INK, 6)
	sign = rect(625, 575, 140, 140, SKY, INK, 10, 20) + access_symbol(695, 650, 110)

	# Ramp wedge with plank seams and a handrail.
	x0, y0, x1, y1 = 185, 860, 560, 530
	wedge = polygon([(x0, y0), (x1, y1), (x1, y0)], WOOD)
	top_board = polygon([(x0, y0), (x1, y1), (x1, y1 + 30), (x0 + 34, y0)], WOOD_DARK)
	seams = ""
	for t in (0.25, 0.5, 0.75):
		sx, sy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
		seams += line(sx, sy, sx + 8, sy + 26, INK, 6)
	posts = ""
	rail_pts = []
	for t in (0.2, 0.55, 0.9):
		px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
		posts += rect(px - 9, py - 110, 18, 112, WOOD_DARK, INK, 7, 6)
		rail_pts.append((px, py - 105))
	rail = path(f"M{rail_pts[0][0] - 30},{rail_pts[0][1] + 26} L{rail_pts[-1][0] + 20},{rail_pts[-1][1] - 18}",
		None, INK, 26) + path(f"M{rail_pts[0][0] - 30},{rail_pts[0][1] + 26} L{rail_pts[-1][0] + 20},{rail_pts[-1][1] - 18}",
		None, WOOD_DARK, 12)

	# Hammer resting against the ramp.
	ang = -30
	hammer = group(
		rect(395, 700, 26, 170, "#f5d27a", INK, 8, 10),
		rect(350, 670, 116, 48, "#9aa7b4", INK, 9, 10),
		transform=f"rotate({ang} 408 780)")

	return group(block, block_line, frame, opening, glow, door_panel, knob, sign, wedge, top_board, seams, posts,
		rail, hammer)
