"""Reference example for art agents: a cheerful otter using a cane. Not a real card."""
from art_lib import INK, blush, circle, ellipse, eye, group, heart, path, rect, smile

STYLE = "sky"

FUR = "#a8774f"
BELLY = "#f3d9b8"


def draw() -> str:
	body = ellipse(500, 640, 170, 220, FUR)
	belly = ellipse(500, 680, 105, 150, BELLY, None)
	tail = path("M640,780 Q800,820 820,700 Q760,760 640,730 Z", FUR)
	head = circle(500, 380, 165, FUR)
	muzzle = ellipse(500, 440, 90, 62, BELLY, None)
	ears = circle(370, 260, 40, FUR) + circle(630, 260, 40, FUR)
	face = eye(440, 370) + eye(560, 370) + ellipse(500, 420, 26, 18, "#2e2236", None) + smile(500, 450, 46) \
		+ blush(395, 430) + blush(605, 430)
	cane = path("M700,520 Q700,450 760,450 Q810,450 810,500", None, "#6ea9dc", 22) + rect(689, 515, 22, 380, "#6ea9dc", INK, 8, 10)
	paw = circle(700, 600, 38, FUR)
	feet = ellipse(420, 860, 70, 34, FUR) + ellipse(580, 860, 70, 34, FUR)
	return group(tail, ears, body, belly, feet, cane, paw, head, muzzle, face, heart(300, 560, 40))
