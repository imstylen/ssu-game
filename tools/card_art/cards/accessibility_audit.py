"""Accessibility Audit: clipboard checklist with an access symbol, big checkmark and tape measure on a blueprint."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, circle, group, line, path, rect  # noqa: E402

STYLE = "mint"

NAVY = "#2f4a7a"
BLUEPRINT = "#4f86c6"
YELLOW = "#ffd84a"
GREEN = "#3fbf8f"


def _blueprint() -> str:
	x0, y0, w, h = 190, 230, 640, 600
	grid = ""
	for x in range(x0 + 40, x0 + w, 40):
		grid += line(x, y0, x, y0 + h, "#a9cdf2", 3)
	for y in range(y0 + 40, y0 + h, 40):
		grid += line(x0, y, x0 + w, y, "#a9cdf2", 3)
	clip = f'<clipPath id="auditbp"><rect x="{x0}" y="{y0}" width="{w}" height="{h}" rx="18"/></clipPath>'
	body = rect(x0, y0, w, h, BLUEPRINT, None) + grid + path("M260,760 h140 v-90 h120", None, "#ffffff", 8)
	return group(clip + f'<g clip-path="url(#auditbp)">{body}</g>' + rect(x0, y0, w, h, None, INK, 10, 18),
		transform="rotate(7 510 530)")


def _access_icon(x0, y0, s) -> str:
	icon = rect(x0, y0, s, s, "#3f7fd6", INK, 8, 16)
	c = "#ffffff"
	w = s * 0.08
	icon += circle(x0 + s * 0.52, y0 + s * 0.2, s * 0.09, c, None)
	icon += path(f"M{x0 + s * 0.5},{y0 + s * 0.34} L{x0 + s * 0.48},{y0 + s * 0.58} L{x0 + s * 0.68},{y0 + s * 0.58} L{x0 + s * 0.78},{y0 + s * 0.8}",
		None, c, w)
	icon += line(x0 + s * 0.49, y0 + s * 0.44, x0 + s * 0.66, y0 + s * 0.44, c, w)
	icon += path(f"M{x0 + s * 0.33},{y0 + s * 0.48} A{s * 0.22},{s * 0.22} 0 1 0 {x0 + s * 0.66},{y0 + s * 0.78}", None, c, w)
	return icon


def _clipboard() -> str:
	board = rect(270, 210, 420, 640, "#c98d5a", INK, 12, 30)
	paper = rect(298, 270, 364, 552, "#ffffff", INK, 8, 12)
	clip = rect(400, 180, 160, 80, "#b8c3d6", INK, 10, 18) + rect(445, 160, 70, 40, "#b8c3d6", INK, 8, 14) + circle(480, 178, 9, INK, None)
	header = _access_icon(326, 296, 110) + rect(456, 312, 170, 22, NAVY, None, 0, 11) + rect(456, 360, 120, 22, "#a8b4c8", None, 0, 11)
	rows = ""
	for i in range(4):
		y = 450 + i * 88
		rows += rect(330, y, 52, 52, "#ffffff", INK, 7, 10)
		rows += rect(402, y + 15, 220 - (i % 2) * 60, 22, "#a8b4c8", None, 0, 11)
		if i < 3:
			rows += path(f"M{338},{y + 26} l14,16 l24,-34", None, GREEN, 11)
	return group(board, paper, clip, header, rows, transform="rotate(-4 480 530)")


def _tape() -> str:
	tape = rect(270, 832, 340, 44, YELLOW, INK, 8, 6)
	for i, x in enumerate(range(300, 600, 30)):
		tape += line(x, 834, x, 852 if i % 2 else 862, INK, 5)
	tape += rect(598, 822, 26, 64, "#b8c3d6", INK, 7, 6)
	case = circle(255, 820, 92, "#ff8fb1", INK, 12) + circle(255, 820, 46, YELLOW, INK, 9) + circle(255, 820, 14, INK, None)
	return tape + case


def draw() -> str:
	check = path("M560,640 L650,740 L830,470", None, INK, 74) + path("M560,640 L650,740 L830,470", None, YELLOW, 48)
	return group(_blueprint(), _clipboard(), _tape(), check)
