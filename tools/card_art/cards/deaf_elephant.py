"""Deaf Elephant: a sturdy elephant stomping vibration lines and signing with a curled trunk."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _group3_helpers import tube  # noqa: E402
from art_lib import INK, blush, ellipse, eye, group, path, smile

STYLE = "sky"

GREY = "#a9b6cc"
DARK = "#8796b0"
PINK = "#ffc2cf"
GROUND = "#f2dfb4"
RUMBLE = "#4f8fd0"
NAIL = "#fff6e6"


def _leg(x, top, bottom, w, fill):
	"""A sturdy leg with a rounded foot and three toenails along the bottom edge."""
	leg = path(f"M{x - w / 2},{top} L{x - w / 2},{bottom - 20} Q{x - w / 2},{bottom} {x - w / 2 + 20},{bottom} "
		f"L{x + w / 2 - 20},{bottom} Q{x + w / 2},{bottom} {x + w / 2},{bottom - 20} L{x + w / 2},{top} Z", fill)
	nails = "".join(path(f"M{nx - 12},{bottom} Q{nx - 12},{bottom - 16} {nx},{bottom - 16} Q{nx + 12},{bottom - 16} "
		f"{nx + 12},{bottom} Z", NAIL, INK, 5) for nx in (x - w / 2 + 22, x, x + w / 2 - 22))
	return leg + nails


def draw() -> str:
	ground = ellipse(512, 868, 330, 46, GROUND)
	rumble = "".join(path(f"M{380 - w},{870 + d} Q380,{892 + d} {380 + w},{870 + d}", None, RUMBLE, 9)
		for w, d in ((70, -4), (120, 14)))
	impact = (path("M300,790 L268,770", None, RUMBLE, 9) + path("M292,826 L254,828", None, RUMBLE, 9)
		+ path("M462,790 L494,770", None, RUMBLE, 9))
	body = ellipse(520, 650, 220, 180, GREY)
	tail = path("M735,640 Q780,660 790,700", None, INK, 9) + ellipse(793, 712, 12, 16, DARK, INK, 6)
	back_leg = _leg(668, 700, 862, 84, DARK)
	# Front legs: left one lifted mid-stomp, right one planted
	legs = _leg(380, 680, 785, 92, GREY) + _leg(565, 700, 872, 92, GREY)
	ears = (ellipse(310, 400, 130, 150, GREY, rotate=-10) + ellipse(320, 405, 85, 105, PINK, None, rotate=-10)
		+ ellipse(710, 400, 130, 150, GREY, rotate=10) + ellipse(700, 405, 85, 105, PINK, None, rotate=10))
	head = ellipse(510, 390, 150, 145, GREY)
	face = (eye(450, 375, 28) + eye(570, 375, 28) + blush(418, 432, 28, 14) + blush(602, 432, 28, 14)
		+ smile(470, 478, 34))
	# Trunk sweeps out to the side and curls up in a signing shape
	trunk = tube("M520,450 C530,540 610,580 680,540 C740,505 760,440 740,400 C725,372 692,380 700,410", GREY, 54, 9)
	trunk_lines = path("M560,555 L572,530 M610,572 L612,545 M705,520 L728,538", None, DARK, 7)
	sign_marks = (path("M790,380 Q815,410 805,445", None, INK, 9) + path("M760,330 Q795,325 815,345", None, INK, 9))
	return group(ground, rumble, impact, back_leg, tail, body, legs, ears, head, face, trunk, trunk_lines, sign_marks)
