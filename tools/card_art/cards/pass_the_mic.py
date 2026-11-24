"""Pass the Mic: a bear steps aside and hands a golden microphone to a bunny in the spotlight."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from art_lib import INK, circle, ellipse, group, heart, line, path, polygon, star  # noqa: E402
from _group4_helpers import head, limb, paw, wheelchair_back, wheelchair_front  # noqa: E402

STYLE = "lavender"

GOLD = "#ffcc3f"
CHARCOAL = "#3a3340"


def _spotlight() -> str:
	beam = polygon([(600, 165), (700, 165), (860, 860), (440, 860)], "#fff6c4", None).replace("/>", ' opacity="0.85"/>')
	lamp = path("M585,180 h130 l-20,-40 h-90 Z", CHARCOAL, INK, 8)
	floor = ellipse(512, 868, 330, 40, "#c9a6f0", INK, 10)
	return floor + beam + lamp


def _mic(cx, cy) -> str:
	hx, hy = cx - 18, cy + 150
	handle = line(cx, cy, hx, hy, INK, 50) + line(cx, cy, hx, hy, CHARCOAL, 32)
	collar = line(cx - 1, cy + 38, cx - 4, cy + 62, INK, 62) + line(cx - 1, cy + 38, cx - 4, cy + 62, "#d9a62a", 44)
	head_ = circle(cx, cy, 52, GOLD, INK, 11)
	grid = ""
	for d in (-30, -10, 10, 30):
		grid += line(cx + d, cy - 52, cx + d, cy + 52, "#d9a62a", 5) + line(cx - 52, cy + d, cx + 52, cy + d, "#d9a62a", 5)
	clip = f'<clipPath id="micgrill"><circle cx="{cx}" cy="{cy}" r="46"/></clipPath>'
	shine = path(f"M{cx - 30},{cy - 20} q8,-18 26,-24", None, "#ffffff", 9)
	return handle + collar + head_ + clip + f'<g clip-path="url(#micgrill)">{grid}</g>' + circle(cx, cy, 52, None, INK, 11) + shine


def _bear() -> str:
	fur, inner = "#b07a50", "#f3d9b8"
	body = ellipse(320, 770, 92, 108, fur) + ellipse(320, 790, 56, 70, inner, None)
	feet = ellipse(275, 868, 44, 22, fur) + ellipse(365, 868, 44, 22, fur)
	other_arm = limb(250, 720, 228, 800, fur, 46) + paw(226, 806, 28, fur, toes=False)
	face = head(320, 560, 98, "bear", fur, inner, look=(6, 0))
	return other_arm + body + feet + face


def _bunny() -> str:
	fur, inner = "#f2eefa", "#ffc9da"
	wx, wy, r = 690, 790, 76
	body = ellipse(690, 700, 78, 86, fur) + ellipse(640, 760, 52, 28, fur)
	face = head(700, 520, 92, "bunny", fur, inner, happy=True)
	return wheelchair_back(wx, wy, r, -1, "#45b998") + body + wheelchair_front(wx, wy, r, -1, "#45b998") + face


def draw() -> str:
	mx, my = 505, 430
	giver = limb(385, 700, 470, 600, "#b07a50", 46)
	taker = limb(630, 660, 540, 548, "#f2eefa", 44)
	notes = path("M790,330 v-70 l46,-14 v70", None, INK, 10) + circle(780, 332, 15, INK, None) + circle(826, 318, 15, INK, None)
	return group(_spotlight(), _bear(), _bunny(), giver, taker, _mic(mx, my),
		paw(487, 590, 32, "#b07a50", angle=-40), paw(530, 540, 30, "#f2eefa", angle=-150),
		heart(230, 330, 38, "#ff86b0"), star(410, 230, 32, "#ffd84a"), notes)
