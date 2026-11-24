"""Service Dog Help: a golden service dog in a sky-blue vest guiding a friend who holds the harness."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, blush, circle, ellipse, eye, group, heart, path, rect, smile  # noqa: E402
from _group5_helpers import clip  # noqa: E402

STYLE = "sky"

GOLD = "#f2b75e"
GOLD_DARK = "#d4913a"
CREAM = "#fff1d6"
VEST = "#6fb8ec"
NAVY = "#3b4f7a"
BUNNY = "#f4eefb"
BUNNY_IN = "#ffc6d6"


def _dog() -> str:
	body_d = "M285,700 C285,560 350,500 430,500 C510,500 575,560 575,700 C575,820 520,870 430,870 C340,870 285,820 285,700 Z"
	body = path(body_d, GOLD)
	chest = ellipse(430, 640, 70, 95, CREAM, None)
	vest = clip("sdh_body", body_d,
		rect(270, 600, 320, 130, VEST, None),
		path("M270,600 L590,600", None, INK, 8), path("M270,730 L590,730", None, INK, 8))
	patch = rect(385, 625, 90, 80, "#ffffff", INK, 7, 14) + heart(430, 665, 22, "#ff7a9c", INK, 5)
	body_outline = path(body_d, None)
	legs = rect(360, 760, 50, 110, GOLD, INK, 9, 24) + rect(450, 760, 50, 110, GOLD, INK, 9, 24)
	paws = ellipse(385, 862, 42, 24, GOLD) + ellipse(475, 862, 42, 24, GOLD)
	tail = path("M290,800 Q200,790 205,700 Q240,770 300,770 Z", GOLD)
	ears = (ellipse(312, 400, 50, 95, GOLD_DARK, rotate=18) + ellipse(548, 400, 50, 95, GOLD_DARK, rotate=-18))
	head = circle(430, 380, 130, GOLD)
	muzzle = ellipse(430, 440, 72, 52, CREAM, None)
	face = (eye(385, 365, 24, (3, 0)) + eye(485, 365, 24, (3, 0)) + ellipse(430, 418, 22, 15, "#2e2236", None)
		+ smile(430, 446, 44, open_mouth=True) + blush(352, 425, 24, 13) + blush(508, 425, 24, 13))
	return group(tail, body, chest, vest, patch, body_outline, legs, paws, ears, head, muzzle, face)


def _handle() -> str:
	d = "M548,650 L615,585 L690,625"
	return path(d, None, INK, 30) + path(d, None, NAVY, 16)


def _bunny() -> str:
	cx = 720
	ears = (ellipse(cx - 35, 360, 26, 80, BUNNY, rotate=-10) + ellipse(cx - 35, 368, 12, 58, BUNNY_IN, None, rotate=-10)
		+ ellipse(cx + 38, 360, 26, 80, BUNNY, rotate=12) + ellipse(cx + 38, 368, 12, 58, BUNNY_IN, None, rotate=12))
	body = ellipse(cx, 740, 95, 125, BUNNY)
	belly = ellipse(cx, 765, 55, 80, "#ffffff", None)
	feet = ellipse(cx - 45, 860, 45, 22, BUNNY) + ellipse(cx + 45, 860, 45, 22, BUNNY)
	head = circle(cx, 500, 88, BUNNY)
	# Round dark glasses: the bunny is blind / low vision.
	glasses = (circle(cx - 33, 490, 30, "#3a3350", INK, 7) + circle(cx + 33, 490, 30, "#3a3350", INK, 7)
		+ path(f"M{cx - 4},488 L{cx + 4},488", None, INK, 7)
		+ circle(cx - 43, 480, 8, "#ffffff", None) + circle(cx + 23, 480, 8, "#ffffff", None))
	face = (ellipse(cx, 530, 10, 7, "#e88aa5", None) + smile(cx, 542, 34, open_mouth=True)
		+ blush(cx - 55, 535, 18, 10) + blush(cx + 55, 535, 18, 10))
	arm_d = f"M{cx - 50},720 Q{cx - 45},660 {cx - 30},630"
	arm = path(arm_d, None, INK, 44) + path(arm_d, None, BUNNY, 28)
	paw = circle(690, 625, 26, BUNNY)
	return group(ears, body, belly, feet, head, glasses, face, arm), paw


def draw() -> str:
	bunny, paw = _bunny()
	return group(_dog(), bunny, _handle(), paw, heart(565, 270, 34, "#ff7a9c"))
