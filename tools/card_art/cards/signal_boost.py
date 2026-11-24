"""Signal Boost: a radio tower with a heart on top broadcasting ever-bigger waves."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, circle, ellipse, eye, group, heart, line, path, smile, blush  # noqa: E402
from _group4_helpers import arc  # noqa: E402

STYLE = "peach"

BERRY = "#d9578d"
TOWER = "#7a5a8c"


def _beam(x1, y1, x2, y2, w=16) -> str:
	return line(x1, y1, x2, y2, INK, w + 14) + line(x1, y1, x2, y2, "#f6a3c4", w)


def _tower() -> str:
	top, base_y = (512, 450), 860
	lx, rx = 410, 614
	out = ""
	# cross braces
	levels = [450, 560, 670, 770, 860]
	def x_at(y, side):
		t = (y - top[1]) / (base_y - top[1])
		return round(top[0] + (lx - top[0] if side < 0 else rx - top[0]) * t, 1)
	for a, b in zip(levels, levels[1:]):
		out += _beam(x_at(a, -1), a, x_at(b, 1), b, 12) + _beam(x_at(a, 1), a, x_at(b, -1), b, 12)
	for y in levels[1:-1]:
		out += _beam(x_at(y, -1), y, x_at(y, 1), y, 12)
	out += _beam(top[0], top[1], lx, base_y, 22) + _beam(top[0], top[1], rx, base_y, 22)
	out += ellipse(512, 868, 150, 26, "#ffcf9e", INK, 10)
	return out


def _waves(cx, cy) -> str:
	out = ""
	for i, (r, w) in enumerate(((150, 16), (225, 22), (300, 28))):
		color = ["#ffffff", "#ffb7cf", BERRY][i]
		out += arc(cx, cy, r, -40, 40, color, w) + arc(cx, cy, r, 140, 220, color, w)
	return out


def _heart_face(cx, cy) -> str:
	h = heart(cx, cy, 92, "#ff6f9c", INK, 12)
	face = eye(cx - 32, cy - 2, 13) + eye(cx + 32, cy - 2, 13) + smile(cx, cy + 22, 30) + blush(cx - 55, cy + 20, 14, 8, "#ffc2d4") \
		+ blush(cx + 55, cy + 20, 14, 8, "#ffc2d4")
	return h + face


def draw() -> str:
	cx, cy = 512, 380
	small_hearts = heart(512, 205, 30, "#ff8fb1") + heart(250, 680, 26, "#ffb870") + heart(775, 690, 26, "#ff8fb1")
	return group(_waves(cx, cy), _tower(), _heart_face(cx, cy), small_hearts)
