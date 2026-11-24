"""Walker Wombat: stocky wombat behind a teal rollator walker with a basket, determined grin."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, ellipse, eye, group, path, rect, smile  # noqa: E402
from _group2_helpers import limb  # noqa: E402

STYLE = "peach"

FUR = "#8b6a4e"
MUZZLE = "#b89474"
TEAL = "#2fa79b"
WICKER = "#e8c38a"
LEAF = "#9ccfa9"


def _wheel(cx: float, cy: float, r: float) -> str:
	return circle(cx, cy, r, "#4b4453") + circle(cx, cy, r * 0.42, "#d9d4dd", INK, 6)


def draw() -> str:
	leaves = (path("M210,330 Q240,250 320,240 Q300,320 210,330 Z", LEAF) + path("M215,325 L310,248", None, INK, 6)
		+ path("M810,360 Q790,280 720,260 Q730,340 810,360 Z", LEAF) + path("M805,355 L725,265", None, INK, 6))
	feet = ellipse(410, 850, 70, 34, FUR) + ellipse(600, 850, 70, 34, FUR)
	body = ellipse(505, 620, 205, 230, FUR)
	belly = ellipse(505, 650, 130, 160, MUZZLE, None)
	ears = (path("M345,290 Q330,220 365,205 Q400,215 405,260 Z", FUR) + path("M665,290 Q680,220 645,205 Q610,215 605,260 Z", FUR)
		+ path("M358,260 Q355,228 370,222 Q388,232 388,258 Z", "#d9a98a", None)
		+ path("M652,260 Q655,228 640,222 Q622,232 622,258 Z", "#d9a98a", None))
	head = ellipse(505, 365, 195, 135, FUR)
	muzzle = ellipse(505, 420, 115, 62, MUZZLE, None)
	brows = path("M392,300 Q420,288 448,304", None, INK, 9) + path("M618,300 Q590,288 562,304", None, INK, 9)
	face = (eye(420, 340, 23) + eye(590, 340, 23)
		+ ellipse(505, 392, 66, 36, "#3d2b2b", None) + ellipse(482, 382, 14, 8, "#7a6060", None)
		+ smile(505, 435, 70, open_mouth=True) + blush(385, 405) + blush(625, 405))
	# Rollator: handles at the top, frame down to wheels, basket in the middle.
	frame = (limb("M300,520 L265,830", TEAL, 26, 8) + limb("M710,520 L745,830", TEAL, 26, 8)
		+ limb("M300,520 L710,520", TEAL, 22, 8)
		+ limb("M282,690 L728,690", TEAL, 20, 8))
	grips = limb("M255,515 L320,515", "#4b4453", 34, 8) + limb("M690,515 L755,515", "#4b4453", 34, 8)
	basket = rect(340, 600, 330, 130, WICKER, INK, 10, 20)
	weave = "".join(path(f"M{x},608 L{x},722", None, "#c99a5c", 6) for x in range(380, 650, 40)) \
		+ path("M348,665 L662,665", None, "#c99a5c", 6)
	snack = circle(420, 590, 30, "#9ccf6a") + path("M420,560 Q430,540 445,545", None, INK, 6)
	wheels = _wheel(265, 840, 45) + _wheel(745, 840, 45)
	paws = circle(295, 500, 36, FUR) + circle(715, 500, 36, FUR)
	arms = limb("M360,520 Q320,520 300,505", FUR, 60) + limb("M650,520 Q690,520 710,505", FUR, 60)
	return group(leaves, feet, body, belly, ears, head, muzzle, brows, face, arms,
		frame, snack, basket, weave, wheels, grips, paws)
