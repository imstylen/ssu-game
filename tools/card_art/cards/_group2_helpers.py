"""Shared helpers for the group-2 placeholder cards (not a card module)."""
from art_lib import INK, circle, path


def limb(d: str, fill: str, width: float = 70, outline: float = 10) -> str:
	"""A thick rounded limb along path ``d``: ink stroke underneath, fill stroke on top."""
	return (path(d, None, INK, width + outline * 2)
		+ path(d, None, fill, width))


def band(d: str, fill: str, width: float = 80, outline: float = 8) -> str:
	"""A short band (brace, armband) drawn along a sub-segment of a limb."""
	return (path(d, None, INK, width + outline * 2).replace('stroke-linecap="round"', 'stroke-linecap="butt"')
		+ path(d, None, fill, width).replace('stroke-linecap="round"', 'stroke-linecap="butt"'))


def check(x: float, y: float, s: float = 1.0, color: str = "#2fa37f", width: float = 9) -> str:
	"""A little tick mark with its top-left near (x, y)."""
	return path(f"M{x},{y + 14 * s} L{x + 10 * s},{y + 26 * s} L{x + 30 * s},{y}", None, color, width)


def bubble(cx: float, cy: float, r: float) -> str:
	return circle(cx, cy, r, "#ffffff", INK, 6, extra='fill-opacity="0.85"') + circle(cx - r * 0.35, cy - r * 0.35, r * 0.25, "#ffffff", None)
