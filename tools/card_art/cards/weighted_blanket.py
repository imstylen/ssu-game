"""Weighted Blanket: a chunky quilted blanket with stitched weight pockets and a snug sleepy bear."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, closed_eye, ellipse, group, heart, path, smile  # noqa: E402
from _group5_helpers import clip  # noqa: E402

STYLE = "lavender"

LAV = "#b49ce6"
LAV_LIGHT = "#cdb9f3"
BERRY = "#e27aa8"
CREAM = "#fff3df"
BEAR = "#c99a74"
BEAR_LIGHT = "#ecd0b3"


def draw() -> str:
	pillow = path("M300,520 Q290,430 380,420 L640,420 Q730,430 720,520 Q730,600 640,610 L380,610 Q290,600 300,520 Z", CREAM)

	# Sleepy bear peeking out on the pillow.
	bx, by = 510, 470
	ears = circle(bx - 75, by - 70, 34, BEAR) + circle(bx + 75, by - 70, 34, BEAR)
	head = circle(bx, by, 100, BEAR)
	muzzle = ellipse(bx, by + 35, 42, 30, BEAR_LIGHT, None)
	face = (closed_eye(bx - 40, by - 5, 32) + closed_eye(bx + 40, by - 5, 32) + ellipse(bx, by + 22, 14, 10, "#2e2236", None)
		+ smile(bx, by + 40, 26) + blush(bx - 66, by + 26, 18, 10) + blush(bx + 66, by + 26, 18, 10))

	blanket_d = ("M200,860 C185,720 215,600 300,555 C380,520 460,545 512,545 C570,545 650,515 730,555 "
		"C815,600 845,720 830,860 Z")
	pockets = ""
	for row in range(5):
		for col in range(8):
			x, y = 170 + col * 90 + (45 if row % 2 else 0), 520 + row * 90
			pockets += path(f"M{x + 8},{y + 45} Q{x + 8},{y + 8} {x + 45},{y + 8} Q{x + 82},{y + 8} {x + 82},{y + 45} "
				f"Q{x + 82},{y + 82} {x + 45},{y + 82} Q{x + 8},{y + 82} {x + 8},{y + 45} Z",
				LAV_LIGHT if (row + col) % 2 else LAV, None)
	stitches = ""
	for k in range(6):
		x = 170 + k * 90 + 45
		stitches += path(f"M{x},500 L{x},880", None, CREAM, 5).replace("/>", ' stroke-dasharray="14 12"/>')
	for k in range(5):
		y = 520 + k * 90
		stitches += path(f"M160,{y} L870,{y}", None, CREAM, 5).replace("/>", ' stroke-dasharray="14 12"/>')
	quilt = clip("wb_blanket", blanket_d, path(blanket_d, LAV, None), pockets, stitches)
	outline = path(blanket_d, None)
	trim = path("M200,850 L830,850", None, BERRY, 22) + path("M188,862 L842,862", None, INK, 10)
	cuff = path("M300,560 C380,525 460,552 512,552 C570,552 650,522 730,560", None, BERRY, 24)

	zz = path("M660,320 L700,320 L660,360 L700,360", None, "#8a6cc8", 10) + path("M720,270 L745,270 L720,295 L745,295", None, "#8a6cc8", 8)
	moon = path("M300,300 A50,50 0 1 0 300,390 A40,40 0 1 1 300,300 Z", "#ffe38a")
	return group(pillow, ears, head, muzzle, face, quilt, cuff, outline, trim,
		heart(512, 720, 40, BERRY, INK, 7), zz, moon)
