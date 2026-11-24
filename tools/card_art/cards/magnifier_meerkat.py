"""Magnifier Meerkat: low vision, keeping lookout with a handheld magnifier."""
from art_lib import INK, blush, circle, ellipse, eye, group, path, smile

STYLE = "sky"

FUR = "#d9b27c"
BELLY = "#f4e1bd"
PATCH = "#7a5538"
SAND = "#f0cf8f"


def draw() -> str:
	dune = path("M200,900 Q330,800 500,830 Q690,800 830,900 Z", SAND)
	tail = path("M560,800 Q700,820 760,720 Q775,690 750,690 Q710,770 580,760 Z", FUR)
	body = ellipse(500, 620, 140, 225, FUR)
	belly = ellipse(500, 660, 85, 165, BELLY, None)
	feet = ellipse(430, 840, 60, 28, FUR) + ellipse(570, 840, 60, 28, FUR)
	ears = circle(405, 300, 26, PATCH) + circle(595, 300, 26, PATCH)
	head = ellipse(500, 330, 110, 118, FUR)
	muzzle = ellipse(500, 400, 60, 46, BELLY, None)
	patches = ellipse(450, 320, 36, 42, PATCH, None, rotate=15) + ellipse(550, 320, 36, 42, PATCH, None, rotate=-15)
	face = eye(450, 322, 24) + eye(550, 322, 24) + ellipse(500, 385, 18, 12, "#2e2236", None) \
		+ smile(500, 405, 34) + blush(420, 380, 22, 12)
	arm_left = ellipse(420, 540, 34, 60, FUR, rotate=20)
	# Magnifier held up to the viewer-right eye: the lens shows that eye enlarged.
	handle = path("M630,420 L690,530", None, INK, 40) + path("M630,420 L690,530", None, "#4a62a8", 24)
	lens_ring = circle(565, 330, 86, "#6ea9dc", INK, 10)
	lens = circle(565, 330, 66, "#e6f5ff", INK, 6)
	big_eye = circle(558, 330, 52, PATCH, None) + eye(558, 330, 38)
	glint = path("M520,290 Q535,272 556,268", None, "#ffffff", 10)
	paw = ellipse(680, 520, 36, 30, FUR, rotate=-30)
	arm = path("M600,500 Q650,540 680,520", None, INK, 46) + path("M600,500 Q650,540 680,520", None, FUR, 30)
	return group(dune, tail, feet, body, belly, arm_left, arm, ears, head, muzzle, patches, face,
		handle, lens_ring, lens, big_eye, glint, paw)
