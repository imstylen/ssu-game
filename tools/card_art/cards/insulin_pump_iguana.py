"""Insulin-Pump Iguana: a green iguana on a warm rock with pump, sensor and snack box."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _group3_helpers import tube  # noqa: E402
from art_lib import INK, blush, circle, ellipse, eye, group, path, polygon, rect, smile

STYLE = "mint"

GREEN = "#7cc45a"
DARK = "#4f9a3c"
LIGHT = "#c8eb9a"


def draw() -> str:
	rock = (path("M200,890 C185,800 260,760 360,772 C440,740 600,742 690,772 C790,760 852,812 842,890 Z", "#cdb89a")
		+ path("M300,800 Q360,785 420,795", None, "#ffffff", 9, extra='opacity="0.6"'))
	tail = tube("M590,770 C720,800 820,760 818,676 C816,610 750,602 736,648", GREEN, 48)
	tail_bands = (path("M690,770 L700,804", None, DARK, 10) + path("M770,742 L800,768", None, DARK, 10)
		+ path("M800,690 L836,690", None, DARK, 10))
	spikes = "".join(polygon([(x - 20, 300), (x, 222 + abs(x - 470) * 0.25), (x + 20, 300)], DARK, INK, 8)
		for x in (390, 430, 470, 510, 550))
	back_spikes = "".join(polygon([(x, y), (x + 40, y - 18), (x + 30, y + 26)], DARK, INK, 8)
		for x, y in ((590, 520), (600, 580), (600, 640)))
	body = ellipse(470, 625, 140, 170, GREEN)
	belly = ellipse(470, 665, 85, 118, LIGHT, None)
	feet = ellipse(400, 785, 52, 28, GREEN) + ellipse(545, 785, 52, 28, GREEN)
	toes = "".join(path(f"M{x},800 L{x},812", None, INK, 7) for x in (380, 400, 420, 525, 545, 565))
	dewlap = path("M420,480 C425,570 480,595 525,545 C530,515 515,495 505,488 Z", "#a6d86e")
	head = ellipse(470, 390, 150, 118, GREEN)
	snout = ellipse(470, 448, 92, 52, LIGHT, None)
	shields = circle(342, 428, 22, "#e9f7c8") + circle(598, 428, 22, "#e9f7c8")
	face = (eye(412, 372, 27) + eye(528, 372, 27) + ellipse(450, 432, 6, 4, "#2e2236", None)
		+ ellipse(490, 432, 6, 4, "#2e2236", None) + smile(470, 460, 52)
		+ blush(385, 450, 24, 12) + blush(555, 450, 24, 12))
	# Arm with CGM sensor
	left_arm = ellipse(338, 610, 44, 82, GREEN, rotate=18)
	sensor = circle(330, 580, 24, "#ffffff") + circle(330, 580, 9, "#9fb3c8", None)
	# Belt and insulin pump
	belt = path("M343,684 Q470,706 597,684 L592,716 Q470,738 348,716 Z", "#ff9f5a")
	pump = (rect(372, 676, 74, 96, "#8fd3ee", INK, 9, 16) + rect(386, 692, 46, 30, "#f1fbff", INK, 6, 6)
		+ circle(409, 746, 9, "#ffffff", INK, 5))
	pump_tube = path("M446,700 C480,690 505,712 520,740", None, INK, 6) + circle(522, 744, 13, "#ffffff", INK, 6)
	# Snack box in the right hand
	box = (rect(560, 520, 150, 104, "#ffa64d", INK, 10, 16) + rect(560, 520, 150, 30, "#ffcf6b", INK, 10, 12)
		+ circle(605, 588, 16, "#f2575b", INK, 6) + path("M605,572 Q610,560 618,558", None, INK, 6)
		+ rect(640, 574, 44, 26, "#fff3c4", INK, 6, 8))
	right_hand = circle(574, 600, 34, GREEN)
	return group(rock, tail, tail_bands, back_spikes, body, belly, feet, toes, belt, pump, pump_tube, left_arm, sensor,
		spikes, dewlap, head, snout, shields, face, box, right_hand)
