"""Sun-Seeking Lemur: basking in a light-therapy lamp as part of a daily routine."""
from art_lib import INK, blush, circle, ellipse, eye, group, path, rect, smile

STYLE = "peach"

GREY = "#b3adb5"
GREY_DARK = "#8d8691"
WHITE = "#f7f4f2"
BLACK = "#3a3340"
GLOW = "#fff3a6"


def ringed_tail(d):
	return (f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="66" stroke-linecap="round"/>'
		f'<path d="{d}" fill="none" stroke="{WHITE}" stroke-width="46" stroke-linecap="round"/>'
		f'<path d="{d}" fill="none" stroke="{BLACK}" stroke-width="46" stroke-dasharray="34 34"/>')


def draw() -> str:
	tail = ringed_tail("M470,800 C620,830 660,720 600,640 C540,560 520,420 560,300 C580,240 560,200 530,190")
	# Light-therapy lamp: glowing panel on a stand.
	rays = "".join(path(f"M{x1},{y1} L{x2},{y2}", None, "#ffcf4d", 14) for x1, y1, x2, y2 in [
		(640, 360, 600, 330), (630, 450, 585, 450), (640, 540, 600, 570)])
	stand = path("M760,600 L760,850", None, INK, 26) + path("M760,600 L760,850", None, "#ffffff", 12) \
		+ ellipse(760, 860, 70, 22, "#ffffff")
	lamp = rect(660, 300, 200, 300, "#ffffff", INK, 12, r=28) + rect(684, 324, 152, 252, GLOW, None, r=18) \
		+ circle(760, 450, 50, "#ffe36b", None)
	legs = ellipse(380, 830, 130, 46, GREY) + ellipse(470, 850, 100, 40, GREY_DARK)
	body = ellipse(420, 640, 150, 180, GREY)
	belly = ellipse(420, 680, 95, 125, WHITE, None)
	arm_l = path("M320,560 Q240,470 220,380", None, INK, 58) + path("M320,560 Q240,470 220,380", None, GREY, 40)
	arm_r = path("M520,560 Q590,480 600,400", None, INK, 58) + path("M520,560 Q590,480 600,400", None, GREY, 40)
	hands = circle(218, 370, 30, BLACK) + circle(602, 390, 30, BLACK)
	ears = circle(320, 250, 40, GREY) + circle(520, 250, 40, GREY) + circle(320, 250, 20, WHITE, None) \
		+ circle(520, 250, 20, WHITE, None)
	head = circle(420, 350, 120, GREY)
	mask = ellipse(420, 390, 95, 85, WHITE, None)
	patches = ellipse(375, 345, 42, 46, BLACK, None, rotate=20) + ellipse(465, 345, 42, 46, BLACK, None, rotate=-20)
	eyes = circle(375, 345, 30, "#ffb84d", None) + circle(465, 345, 30, "#ffb84d", None) \
		+ eye(375, 348, 20) + eye(465, 348, 20)
	snout = path("M400,400 L440,400 L420,425 Z", BLACK, INK, 6)
	face = smile(420, 438, 40) + blush(345, 420, 22, 12) + blush(495, 420, 22, 12)
	return group(rays, stand, lamp, tail, legs, body, belly, arm_l, arm_r, hands, ears, head, mask, patches, eyes,
		snout, face)
