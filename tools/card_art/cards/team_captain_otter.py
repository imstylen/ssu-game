"""Team-Captain Otter: otter with Down syndrome (gentle almond eyes, wide warm smile) wearing a
captain armband, paws raised in a team cheer."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, ellipse, group, path, rect, star, text  # noqa: E402
from _group2_helpers import band, limb  # noqa: E402

STYLE = "berry"

FUR = "#9a6a45"
CREAM = "#f3dcc0"
BERRY = "#c94f86"
GOLD = "#ffcf4a"


def _almond_eye(cx: float, cy: float, tilt: float) -> str:
	"""Gently upturned almond eye with highlights."""
	return (ellipse(cx, cy, 27, 20, "#2e2236", None, rotate=tilt)
		+ circle(cx - 8, cy - 6, 8, "#ffffff", None) + circle(cx + 9, cy + 5, 4, "#ffffff", None))


def _pennant(x: float, y: float, color: str) -> str:
	return path(f"M{x - 30},{y} L{x + 30},{y} L{x},{y + 60} Z", color, INK, 7)


def draw() -> str:
	flags = (path("M190,200 Q510,250 840,200", None, INK, 6)
		+ _pennant(240, 210, GOLD) + _pennant(330, 222, BERRY) + _pennant(420, 230, GOLD)
		+ _pennant(600, 230, GOLD) + _pennant(690, 222, BERRY) + _pennant(780, 210, GOLD))
	river = path("M190,880 Q350,840 500,880 Q650,915 840,870", None, "#8ec9ea", 22)
	tail = path("M610,800 Q780,830 830,700 Q800,690 780,730 Q730,775 620,740 Z", FUR)
	feet = ellipse(420, 858, 68, 32, FUR) + ellipse(590, 858, 68, 32, FUR)
	body = ellipse(505, 650, 165, 205, FUR)
	jersey = path("M360,560 Q505,500 650,560 L665,720 Q505,770 345,720 Z", BERRY)
	number = star(505, 640, 46, GOLD, INK, 7)
	arm_l = limb("M380,560 Q300,480 300,370", FUR, 64)
	arm_r = limb("M630,560 Q710,480 710,370", FUR, 64)
	armband = band("M681,491 Q690,472 697,453", GOLD, 78)
	badge = circle(689, 472, 22, BERRY, INK, 6) + text(689, 483, "C", 30, "#ffffff")
	paws = circle(300, 350, 40, FUR) + circle(710, 350, 40, FUR)
	ears = circle(362, 380, 26, FUR) + circle(648, 380, 26, FUR) + circle(362, 380, 12, "#d9a98a", None) + circle(648, 380, 12, "#d9a98a", None)
	head = ellipse(505, 420, 160, 125, FUR)
	muzzle = (ellipse(505, 488, 100, 52, CREAM, None)
		+ circle(470, 462, 42, CREAM, None) + circle(540, 462, 42, CREAM, None))
	whiskers = "".join(circle(x, y, 4, "#b08a6a", None) for x, y in [(450, 455), (440, 470), (460, 472), (560, 455), (570, 470), (550, 472)])
	face = (_almond_eye(445, 410, -12) + _almond_eye(565, 410, 12)
		+ whiskers + ellipse(505, 445, 24, 16, "#2e2236", None)
		+ path("M445,478 Q505,535 565,478 Z", "#c94f6d", "#2e2236", 8)
		+ path("M480,505 Q505,520 530,505", None, "#ff9fb8", 8)
		+ blush(410, 470, 26, 13) + blush(600, 470, 26, 13))
	return group(flags, river, tail, feet, body, jersey, number, arm_l, arm_r, armband, badge, paws, ears, head, muzzle, face)
