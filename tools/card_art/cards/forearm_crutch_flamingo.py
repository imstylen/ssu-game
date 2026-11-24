"""Forearm-Crutch Flamingo: striding confidently on two purple forearm crutches."""
from art_lib import INK, blush, circle, ellipse, eye, group, path, smile

STYLE = "berry"

PINK = "#f78fb3"
PINK_DARK = "#e46b98"
CRUTCH = "#9b6fd6"
LEG = "#f27aa5"


def stroke2(d, color, w):
	return path(d, None, INK, w + 18) + path(d, None, color, w)


def crutch_and_wing(shoulder, cuff, foot, wing_color):
	"""Forearm crutch from cuff to foot, with a feathered wing reaching through the cuff to the grip."""
	(sx, sy), (cx, cy), (fx, fy) = shoulder, cuff, foot
	gx, gy = cx + (fx - cx) * 0.2, cy + (fy - cy) * 0.2
	shaft = stroke2(f"M{cx},{cy - 20} L{fx},{fy}", CRUTCH, 18)
	tip = ellipse(fx, fy + 4, 22, 13, INK, None)
	# Tapered wing: wide at the shoulder, narrowing to the wing tip at the grip.
	wing = path(f"M{sx - 45},{sy - 10} Q{(sx + gx) / 2 - 30},{sy} {gx - 18},{gy} Q{gx},{gy + 22} {gx + 18},{gy} "
		f"Q{(sx + gx) / 2 + 30},{sy + 40} {sx + 45},{sy + 10} Q{sx},{sy - 50} {sx - 45},{sy - 10} Z", wing_color)
	cuff_ring = ellipse(cx, cy, 34, 16, CRUTCH, INK, 9)
	grip = stroke2(f"M{gx - 34},{gy + 6} L{gx + 34},{gy + 6}", "#5b3f8c", 14)
	return shaft + tip + grip + wing + cuff_ring


def draw() -> str:
	back = crutch_and_wing((620, 520), (690, 590), (780, 885), PINK_DARK)
	leg_back = stroke2("M540,640 L610,760 L580,880", LEG, 16) + ellipse(600, 884, 40, 14, LEG, INK, 8)
	leg_front = stroke2("M480,640 L470,880", LEG, 16) + ellipse(450, 884, 40, 14, LEG, INK, 8)
	tail = path("M670,520 L760,500 L720,570 Z", PINK_DARK)
	body = ellipse(530, 560, 175, 112, PINK, rotate=-10)
	feathers = path("M580,560 Q620,600 670,580", None, INK, 7) + path("M540,600 Q580,630 630,620", None, INK, 7)
	neck = stroke2("M420,520 C350,460 360,360 430,330 C480,310 490,260 450,230", PINK, 52)
	head = circle(440, 225, 76, PINK)
	beak = path("M378,215 Q318,215 300,262 Q296,300 322,306 Q332,272 380,262 Z", "#fff4f8") \
		+ path("M300,262 Q296,300 322,306 Q322,284 306,266 Z", INK, None)
	face = eye(450, 212, 24) + blush(488, 250, 20, 11) + smile(430, 262, 26)
	front = crutch_and_wing((450, 520), (350, 590), (270, 885), PINK_DARK)
	return group(back, tail, leg_back, leg_front, body, feathers, neck, head, beak, face, front)
