"""Worry-Wise Pangolin: pangolin in soft armour-plate scales holding a long ticked checklist."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, ellipse, eye, group, path, rect, smile  # noqa: E402
from _group2_helpers import check, limb  # noqa: E402

STYLE = "mint"

OLIVE = "#a7a35a"
OLIVE_DARK = "#86823f"
CREAM = "#f6ead0"


def _scale(cx: float, cy: float, s: float = 1.0, fill: str = OLIVE) -> str:
	"""One soft armour plate: rounded top, gentle point at the bottom."""
	w, h = 34 * s, 40 * s
	return path(f"M{cx - w},{cy - h * 0.4} Q{cx - w},{cy - h} {cx},{cy - h} Q{cx + w},{cy - h} {cx + w},{cy - h * 0.4} "
		f"Q{cx + w * 0.8},{cy + h * 0.6} {cx},{cy + h * 0.8} Q{cx - w * 0.8},{cy + h * 0.6} {cx - w},{cy - h * 0.4} Z",
		fill, INK, 7)


def draw() -> str:
	tail = ""
	for i, (x, y, s) in enumerate([(300, 850, 1.25), (240, 810, 1.15), (205, 745, 1.0), (205, 680, 0.9), (230, 625, 0.8)]):
		tail = _scale(x, y, s, OLIVE_DARK if i % 2 else OLIVE) + tail
	feet = ellipse(400, 860, 60, 30, CREAM) + ellipse(560, 860, 60, 30, CREAM)
	body = ellipse(470, 640, 175, 220, OLIVE)
	# overlapping plates on the back/sides, rows from bottom to top so upper rows overlap lower ones
	plates = ""
	for row, (y, xs) in enumerate([(800, [360, 430, 510, 580]), (730, [320, 390, 550, 620]),
			(660, [315, 625]), (590, [330, 610]), (520, [360, 580])]):
		for x in xs:
			plates += _scale(x, y, 1.05, OLIVE_DARK if (row + xs.index(x)) % 2 else OLIVE)
	belly = ellipse(470, 665, 95, 140, CREAM)
	cap = ""
	head = ellipse(470, 350, 150, 130, CREAM)
	for x, y, s in [(360, 290, 0.9), (420, 265, 1.0), (520, 265, 1.0), (580, 290, 0.9), (470, 255, 1.05)]:
		cap += _scale(x, y, s, OLIVE)
	snout = ellipse(470, 400, 32, 44, "#fbf3e2") + ellipse(470, 428, 16, 11, "#e98aa0", None)
	face = (eye(410, 340, 25) + eye(530, 340, 25) + path("M452,458 Q470,470 488,458", None, "#2e2236", 6)
		+ blush(380, 392, 24, 12) + blush(560, 392, 24, 12))
	# Long checklist held in front, unrolling downward.
	paper = path("M600,380 L800,380 L800,800 Q770,830 740,800 Q710,770 680,800 Q650,830 620,800 L600,800 Z", "#ffffff")
	roll = rect(585, 355, 230, 42, "#e6f7ee", INK, 9, 20)
	items = ""
	for i in range(6):
		y = 420 + i * 60
		items += rect(632, y, 34, 34, "#ffffff", INK, 6, 7)
		if i < 5:
			items += check(634, y - 2, 1.05, "#2fa37f", 9)
		items += path(f"M682,{y + 18} L{775 - (i % 2) * 25},{y + 18}", None, "#c9c3d1", 9)
	arms = limb("M360,530 Q320,600 380,650", CREAM, 54) + limb("M570,540 Q585,520 585,505", CREAM, 54)
	paws = circle(390, 655, 30, CREAM) + circle(588, 500, 30, CREAM)
	return group(tail, feet, body, plates, belly, paper, roll, items, arms, paws, head, cap, snout, face)
