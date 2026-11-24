"""Stuttering Starling: sings at its own pace while friends lean in to listen."""
from art_lib import INK, blush, circle, closed_eye, ellipse, group, path, polygon, star

STYLE = "sky"

NAVY = "#2f3f75"
NAVY_LIGHT = "#4a62a8"
GOLD = "#ffd95a"
BEAK = "#ffc443"


def note(x, y, s=1.0, color="#ffffff"):
	return (ellipse(x, y, 20 * s, 15 * s, color, INK, 7, rotate=-20)
		+ path(f"M{x + 17 * s},{y - 4 * s} L{x + 17 * s},{y - 62 * s} Q{x + 40 * s},{y - 50 * s} {x + 44 * s},{y - 30 * s}",
			None, INK, 7))


def friend(x, y, lean, color):
	d = 1 if lean > 0 else -1
	body = ellipse(x, y, 52, 46, color, INK, 8, rotate=lean)
	hx = x + lean * 1.6
	head = circle(hx, y - 50, 30, color, INK, 8)
	beak = polygon([(hx + 24 * d, y - 54), (hx + 48 * d, y - 46), (hx + 24 * d, y - 40)], BEAK, INK, 6)
	e = circle(hx + 8 * d, y - 56, 7, "#2e2236", None)
	return body + head + beak + e


def draw() -> str:
	wire = path("M175,770 Q512,800 850,770", None, INK, 10)
	friends = friend(255, 720, 24, "#8fb7e8") + friend(770, 720, -24, "#9bd0c4")
	tail = polygon([(470, 700), (410, 830), (500, 800), (560, 840), (540, 700)], NAVY)
	body = ellipse(510, 590, 165, 175, NAVY)
	belly = ellipse(560, 630, 105, 125, NAVY_LIGHT, None)
	wing = path("M380,520 Q470,490 530,560 Q520,680 430,750 Q350,650 380,520 Z", "#26335f") \
		+ path("M400,560 Q440,640 430,720", None, "#8fd0ff", 8)
	head = circle(500, 410, 120, NAVY)
	speckles = "".join(star(x, y, 14, GOLD, None, 0, points=4, inner=0.4) for x, y in [
		(580, 560), (620, 650), (560, 700), (530, 620), (450, 600), (440, 680), (420, 360), (470, 320),
		(560, 330), (600, 600)])
	beak_top = polygon([(585, 380), (690, 360), (600, 418)], BEAK, INK, 8)
	beak_bot = polygon([(596, 428), (672, 438), (592, 456)], BEAK, INK, 8)
	face = closed_eye(520, 400, 50) + blush(540, 450, 24, 13)
	feet = path("M470,760 L460,790 M490,760 L495,792 M550,760 L545,792 M570,760 L580,790", None, "#e89a3c", 10)
	trail = (circle(700, 330, 10, INK, None) + circle(735, 300, 10, INK, None) + circle(770, 270, 10, INK, None)
		+ note(745, 220, 1.0, GOLD) + note(820, 330, 0.8, "#ffffff") + note(660, 220, 0.75, "#8fd0ff"))
	return group(wire, friends, tail, body, belly, wing, feet, head, speckles, beak_bot, beak_top, face, trail)
