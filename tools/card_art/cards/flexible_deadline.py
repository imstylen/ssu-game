"""Flexible Deadline: a calendar date stretching like elastic beside a smiling alarm clock."""
from art_lib import INK, blush, circle, ellipse, eye, group, heart, line, path, rect, smile

STYLE = "mint"

BERRY = "#e0679a"
MINT = "#8fdcbc"
MINT_LIGHT = "#d4f5e7"
CLOCK = "#7fd6b3"


def draw() -> str:
	cal = rect(195, 230, 430, 470, "#ffffff", INK, 10, 26)
	header = path("M205,240 Q205,240 221,240 L599,240 Q615,240 615,256 L615,330 L205,330 Z", BERRY, None)
	header_line = line(195, 330, 625, 330, INK, 9)
	rings = (rect(290, 195, 26, 70, "#d9e2ea", INK, 8, 13) + rect(505, 195, 26, 70, "#d9e2ea", INK, 8, 13))
	cells = ""
	for row in range(3):
		for col in range(4):
			if row == 1 and col == 3:
				continue
			x, y = 230 + col * 97, 360 + row * 108
			cells += rect(x, y, 72, 72, MINT_LIGHT, INK, 6, 14)
	# The stretchy date: cell at row 1 col 3 pulled out to the right like taffy.
	y = 468
	stretch = path(f"M521,{y} Q600,{y} 660,{y + 18} Q720,{y} 800,{y} Q836,{y} 836,{y + 36} "
		f"Q836,{y + 72} 800,{y + 72} Q720,{y + 72} 660,{y + 54} Q600,{y + 72} 521,{y + 72} "
		f"Q513,{y + 72} 513,{y + 64} L513,{y + 8} Q513,{y} 521,{y} Z", BERRY, INK, 7)
	star_dot = heart(790, y + 38, 20, "#ffffff", INK, 5)
	motion = path(f"M850,{y + 10} L880,{y}", None, INK, 6) + path(f"M852,{y + 62} L882,{y + 72}", None, INK, 6)

	# Smiling alarm clock.
	cx, cy, r = 640, 740, 120
	bells = (circle(cx - 85, cy - 105, 36, "#ffd95a") + circle(cx + 85, cy - 105, 36, "#ffd95a")
		+ rect(cx - 12, cy - 150, 24, 30, "#ffd95a", INK, 7, 8))
	legs = path(f"M{cx - 70},{cy + 100} L{cx - 95},{cy + 135}", None, INK, 14) \
		+ path(f"M{cx + 70},{cy + 100} L{cx + 95},{cy + 135}", None, INK, 14)
	body = circle(cx, cy, r, CLOCK)
	face_bg = circle(cx, cy, r - 26, "#ffffff", INK, 7)
	hands = path(f"M{cx},{cy - 60} L{cx},{cy - 10}", None, INK, 9) + path(f"M{cx},{cy - 10} L{cx + 40},{cy - 30}", None, INK, 9)
	ticks = "".join(circle(cx + dx, cy + dy, 6, INK, None) for dx, dy in ((0, -78), (78, 0), (-78, 0)))
	face = (eye(cx - 34, cy + 18, 15) + eye(cx + 34, cy + 18, 15) + smile(cx, cy + 46, 34, open_mouth=True)
		+ blush(cx - 58, cy + 44, 14, 8) + blush(cx + 58, cy + 44, 14, 8))
	return group(cal, header, header_line, rings, cells, stretch, star_dot, motion, legs, bells, body,
		face_bg, ticks, hands, face)
