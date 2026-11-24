"""Tourette's Toucan: a beaming toucan with a rainbow beak, wings spread wide in welcome."""
from art_lib import INK, blush, circle, ellipse, eye, group, heart, path, rect

STYLE = "peach"

BLACK = "#3d3650"
SHINE = "#5b5274"
CHEST = "#fff0c4"
LEAF = "#5cc28a"

UPPER = "M500,318 C590,248 770,250 838,330 C800,368 650,382 510,386 Z"
LOWER = "M510,386 C630,386 770,376 828,346 C790,412 630,434 512,418 Z"

WING = [(370, 500), (300, 440), (220, 420), (180, 440), (200, 470), (190, 500), (215, 515), (195, 540),
	(215, 570), (245, 575), (240, 610), (280, 630), (310, 615), (340, 610), (370, 590), (390, 580)]


def _leaf(cx, cy, rot):
	d = (f"M{cx},{cy} C{cx - 60},{cy - 70} {cx - 20},{cy - 150} {cx + 60},{cy - 170} "
		f"C{cx + 70},{cy - 90} {cx + 50},{cy - 30} {cx},{cy} Z")
	vein = path(f"M{cx},{cy} Q{cx + 10},{cy - 80} {cx + 55},{cy - 160}", None, "#3f9a6a", 7)
	return group(path(d, LEAF), vein, transform=f"rotate({rot} {cx} {cy})")


def _wing(mirror: bool) -> str:
	def mx(v):
		return 960 - v if mirror else v
	m = [(mx(px), py) for px, py in WING]
	d = f"M{m[0][0]},{m[0][1]} "
	for i in range(1, 16, 3):
		d += f"C{m[i][0]},{m[i][1]} {m[i + 1][0]},{m[i + 1][1]} {m[i + 2][0]},{m[i + 2][1]} "
	d += "Z"
	shine = "".join(path(f"M{mx(330)},{y} L{mx(tx)},{ty}", None, SHINE, 8)
		for (tx, ty), y in zip([(230, 455), (240, 530), (270, 590)], (500, 540, 580)))
	return path(d, BLACK) + shine


def _beak() -> str:
	clip = f'<clipPath id="tt_beak"><path d="{UPPER}"/><path d="{LOWER}"/></clipPath>'
	bands = [("#b9e35c", 480, 580), ("#ffd84d", 580, 660), ("#ff9a3c", 660, 740), ("#f2575b", 740, 860)]
	fills = "".join(f'<rect x="{x0}" y="230" width="{x1 - x0}" height="220" fill="{c}"/>' for c, x0, x1 in bands)
	return (f"<defs>{clip}</defs>" + f'<g clip-path="url(#tt_beak)">{fills}</g>'
		+ path(UPPER, None, INK, 10) + path(LOWER, None, INK, 10)
		+ path("M560,300 Q640,280 720,292", None, "#ffffff", 8, extra='opacity="0.6"'))


def draw() -> str:
	leaves = _leaf(250, 860, -30) + _leaf(760, 880, 25)
	branch = rect(250, 800, 500, 44, "#b07a4f", INK, 10, 22)
	tail = path("M440,760 L430,905 L480,885 L530,905 L520,760 Z", BLACK)
	wings = _wing(False) + _wing(True)
	body = ellipse(480, 600, 150, 200, BLACK)
	chest = ellipse(482, 535, 100, 150, CHEST, None)
	feet = ellipse(430, 800, 34, 20, "#7fa8dc") + ellipse(530, 800, 34, 20, "#7fa8dc")
	head = circle(450, 335, 125, BLACK)
	rings = circle(392, 318, 38, "#8ad7ea", None) + circle(468, 312, 38, "#8ad7ea", None)
	face = eye(392, 318, 26) + eye(468, 312, 26) + blush(368, 372, 26, 14)
	# Friendly "pop" marks for tics: part of Toucan's energy.
	pops = (path("M318,230 L292,206", None, "#ff9a3c", 10) + path("M346,214 L338,182", None, "#ff9a3c", 10)
		+ path("M300,262 L268,254", None, "#ff9a3c", 10))
	confetti = (rect(640, 180, 26, 14, "#b9e35c", INK, 6, 3, rotate=30)
		+ rect(220, 330, 24, 14, "#f2575b", INK, 6, 3, rotate=-25)
		+ rect(760, 470, 24, 14, "#ffd84d", INK, 6, 3, rotate=15))
	return group(leaves, tail, branch, wings, body, feet, head, chest, rings, face, _beak(), pops, confetti,
		heart(640, 520, 30))
