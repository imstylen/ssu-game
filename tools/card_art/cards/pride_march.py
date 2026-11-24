"""Pride March: a parade of animal allies carrying the Disability Pride flag."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, circle, ellipse, group, heart, line, path, rect  # noqa: E402
from _group4_helpers import confetti, head, limb, paw, wheelchair_back, wheelchair_front  # noqa: E402

STYLE = "berry"

CHARCOAL = "#595959"
BAND = ["#cf7280", "#eddb76", "#f4f4f4", "#7bc2e0", "#3bb07d"]  # red, gold, white, blue, green


def _flag() -> str:
	shape = "M232,200 Q372,165 512,200 T792,200 L792,490 Q652,525 512,490 T232,490 Z"
	ux, uy = 0.885, 0.466  # top-left -> bottom-right diagonal
	px, py = -uy, ux
	cx, cy = 512, 345
	stripes = ""
	for k, color in zip(range(-2, 3), BAND):
		ox, oy = cx + px * k * 34, cy + py * k * 34
		stripes += line(round(ox - ux * 500, 1), round(oy - uy * 500, 1), round(ox + ux * 500, 1), round(oy + uy * 500, 1), color, 35)
	stripes = stripes.replace('stroke-linecap="round"', 'stroke-linecap="butt"')
	clip = f'<clipPath id="prideflag"><path d="{shape}"/></clipPath>'
	flag = clip + f'<g clip-path="url(#prideflag)">{path(shape, CHARCOAL, None)}{stripes}</g>' + path(shape, None, INK, 12)
	poles = (rect(218, 175, 22, 640, "#c98d5a", INK, 8, 10) + rect(784, 175, 22, 640, "#c98d5a", INK, 8, 10)
		+ circle(229, 168, 20, "#ffd84a", INK, 8) + circle(795, 168, 20, "#ffd84a", INK, 8))
	return poles + flag


def _wheelchair_bear(x) -> str:
	fur, inner = "#b07a50", "#f3d9b8"
	wx, wy, r = x, 822, 56
	body = ellipse(x, 762, 56, 58, fur) + ellipse(x + 44, 790, 40, 22, fur)
	arm = limb(x - 30, 745, 240, 712, fur, 40) + paw(236, 708, 28, fur, toes=False)
	return (wheelchair_back(wx, wy, r, 1) + body + wheelchair_front(wx, wy, r, 1) + arm
		+ head(x, 668, 60, "bear", fur, inner, happy=True))


def _cane_bunny(x) -> str:
	fur, inner = "#e9e4f0", "#ffc9da"
	body = ellipse(x, 790, 50, 66, fur) + ellipse(x - 26, 860, 30, 18, fur) + ellipse(x + 26, 860, 30, 18, fur)
	cane = line(x + 52, 770, x + 78, 875, INK, 22) + line(x + 52, 770, x + 78, 875, "#ffffff", 10) \
		+ line(x + 72, 850, x + 78, 875, "#e3456b", 10)
	hand = paw(x + 50, 772, 22, fur, toes=False)
	return body + cane + hand + head(x, 695, 58, "bunny", fur, inner, happy=False, look=(0, -2))


def _headphone_cat(x) -> str:
	fur, inner = "#f6b26b", "#ffe2c2"
	body = ellipse(x, 790, 50, 66, fur) + ellipse(x - 26, 860, 30, 18, fur) + ellipse(x + 26, 860, 30, 18, fur)
	sign = heart(x, 792, 34, "#ff7a9c")
	hand = paw(x - 34, 800, 20, fur, toes=False) + paw(x + 34, 800, 20, fur, toes=False)
	face = head(x, 695, 58, "cat", fur, inner, happy=True)
	phones = path(f"M{x - 62},{695} Q{x - 62},{620} {x},{620} Q{x + 62},{620} {x + 62},{695}", None, INK, 22) \
		+ path(f"M{x - 62},{695} Q{x - 62},{620} {x},{620} Q{x + 62},{620} {x + 62},{695}", None, "#966cc9", 10) \
		+ ellipse(x - 62, 700, 18, 30, "#966cc9") + ellipse(x + 62, 700, 18, 30, "#966cc9")
	return body + face + phones + sign + hand


def _pup(x) -> str:
	fur, inner = "#f1d3a8", "#fff3e0"
	body = ellipse(x, 790, 52, 66, fur) + ellipse(x - 26, 860, 30, 18, fur)
	blade = path(f"M{x + 18},{835} q4,30 30,38 h-30", None, INK, 16) + path(f"M{x + 18},{835} q4,30 30,38 h-30", None, "#b8c3d6", 7)
	arm = limb(x + 30, 790, 790, 770, fur, 40) + paw(795, 768, 28, fur, toes=False)
	return body + blade + arm + head(x, 695, 58, "dog", fur, inner, happy=False, ear_color="#a8774f")


def draw() -> str:
	bits = [(300, 545, "r", 20), (420, 160, "c", 0), (620, 150, "r", -30), (700, 545, "s", 10), (860, 300, "r", 60),
		(175, 380, "s", -60), (520, 560, "c", 0), (860, 560, "c", 0), (170, 600, "r", 30)]
	return group(_flag(), _wheelchair_bear(300), _cane_bunny(450), _headphone_cat(595), _pup(735),
		confetti(bits, BAND[:2] + BAND[3:] + ["#ff86b0"]))
