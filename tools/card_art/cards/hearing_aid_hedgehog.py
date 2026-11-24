"""Hearing-Aid Hedgehog: hard of hearing, wearing bright behind-the-ear hearing aids."""
from art_lib import INK, blush, circle, ellipse, eye, group, path, smile, star

STYLE = "sky"

SPINES = "#8a5a3b"
SPINE_TIP = "#a8754f"
FACE = "#f6e3c4"
AID = "#4fa3e0"


def hearing_aid(x, y, flip=1):
	# Bean-shaped behind-the-ear body plus a curved tube into the ear.
	bean = ellipse(x, y, 26, 48, AID, INK, 8, rotate=-20 * flip)
	tube = path(f"M{x - 4 * flip},{y - 44} Q{x - 40 * flip},{y - 70} {x - 52 * flip},{y - 30}", None, INK, 8)
	dot = circle(x + 4 * flip, y + 14, 8, "#ffd95a", None)
	return tube + bean + dot


def sound_arcs(x, y, flip=1):
	out = ""
	for i, r in enumerate((50, 85, 120)):
		out += path(f"M{x + flip * r * 0.5},{y - r * 0.87} A{r},{r} 0 0 {1 if flip > 0 else 0} {x + flip * r * 0.5},{y + r * 0.87}",
			None, "#6ea9dc", 14 - i * 2)
	return out


def draw() -> str:
	spines = star(510, 560, 300, SPINES, INK, 10, points=18, inner=0.8)
	inner_spines = star(510, 565, 250, SPINE_TIP, None, 0, points=18, inner=0.82)
	face = ellipse(510, 620, 175, 195, FACE)
	ears = circle(360, 420, 42, FACE) + circle(660, 420, 42, FACE) + circle(360, 420, 18, "#f2b8a8", None) \
		+ circle(660, 420, 18, "#f2b8a8", None)
	aids = hearing_aid(318, 470, 1) + hearing_aid(702, 470, -1)
	face_bits = eye(450, 590, 30) + eye(570, 590, 30) + ellipse(510, 650, 24, 17, "#2e2236", None) \
		+ smile(510, 676, 50) + blush(405, 665) + blush(615, 665)
	paw_raised = ellipse(740, 600, 42, 58, FACE, rotate=25)
	paw_down = ellipse(345, 760, 40, 50, FACE, rotate=-15)
	feet = ellipse(430, 830, 62, 32, FACE) + ellipse(590, 830, 62, 32, FACE)
	arcs = sound_arcs(790, 340, 1)
	return group(arcs, spines, inner_spines, feet, face, ears, aids, face_bits, paw_down, paw_raised)
