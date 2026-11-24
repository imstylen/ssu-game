"""Buddy-Bird Capybara: a relaxed capybara in a warm spring with a support bird on its head."""
from art_lib import INK, blush, circle, closed_eye, ellipse, eye, group, heart, path, polygon, smile

STYLE = "mint"

FUR = "#c79a6b"
DARK = "#a77a4e"
WATER = "#9fe3d6"
BIRD = "#ffe27a"


def draw() -> str:
	steam = "".join(path(d, None, "#ffffff", 14) for d in (
		"M240,560 C200,500 280,470 240,410 C210,370 250,330 240,300",
		"M790,560 C830,500 750,470 790,410 C820,370 780,330 790,300",
	))
	body = ellipse(500, 690, 225, 170, FUR)
	ears = ellipse(375, 300, 34, 28, DARK) + ellipse(625, 300, 34, 28, DARK)
	head = path("M340,330 C340,270 420,250 500,250 C580,250 660,270 660,330 L670,470 C670,540 600,570 500,570 "
		"C400,570 330,540 330,470 Z", FUR)
	muzzle = ellipse(500, 495, 120, 72, DARK)
	nose = ellipse(470, 470, 12, 8, "#2e2236", None) + ellipse(530, 470, 12, 8, "#2e2236", None)
	face = (closed_eye(420, 390, 46) + closed_eye(580, 390, 46) + smile(500, 510, 54)
		+ blush(395, 440, 28, 14) + blush(605, 440, 28, 14))
	# Water with wavy surface covering the lower body
	water = path("M200,700 Q250,675 300,700 T400,700 T500,700 T600,700 T700,700 T810,700 L830,800 "
		"C780,900 240,900 190,800 Z", WATER)
	ripples = (path("M300,760 Q340,745 380,760", None, "#ffffff", 9)
		+ path("M600,790 Q640,775 680,790", None, "#ffffff", 9))
	yuzu = circle(720, 730, 36, "#ffc23a") + path("M716,696 Q726,684 738,688", None, "#5cc28a", 8)
	paws = ellipse(420, 705, 40, 22, FUR) + ellipse(580, 705, 40, 22, FUR)
	# Little support bird on top of the head
	bird_tail = polygon([(452, 220), (420, 205), (430, 238)], "#f5b942")
	bird = ellipse(500, 215, 52, 44, BIRD)
	bird_wing = path("M480,215 Q500,250 530,222", None, INK, 8)
	bird_face = (eye(512, 200, 11) + polygon([(536, 206), (558, 214), (536, 222)], "#ff9a3c", INK, 6)
		+ blush(500, 222, 10, 6))
	bird_feet = path("M490,256 L488,266 M510,256 L512,266", None, INK, 7)
	buddy = group(bird_tail, bird_feet, bird, bird_wing, bird_face,
		transform="translate(500,262) scale(1.45) translate(-500,-262)")
	return group(steam, body, ears, head, muzzle, nose, face, water, ripples, paws, yuzu,
		buddy, heart(640, 160, 26, "#ff9fb8"))
