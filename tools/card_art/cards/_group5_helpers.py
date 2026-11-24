"""Shared helpers for group-5 one-shot cards (not a card; build.py skips underscore modules)."""
import math

from art_lib import INK, circle, ellipse, group, path, rect


def access_symbol(cx: float, cy: float, s: float, color: str = "#ffffff") -> str:
	"""Simplified international symbol of access (person in a wheelchair), roughly s wide."""
	w = s * 0.09
	head = circle(cx - s * 0.02, cy - s * 0.4, s * 0.1, color, None)
	body = path(f"M{cx - s * 0.06},{cy - s * 0.24} L{cx - s * 0.04},{cy + s * 0.06} L{cx + s * 0.2},{cy + s * 0.06} "
		f"L{cx + s * 0.3},{cy + s * 0.34}", None, color, w)
	arm = path(f"M{cx - s * 0.05},{cy - s * 0.1} L{cx + s * 0.14},{cy - s * 0.1}", None, color, w)
	wx, wy, r = cx - s * 0.04, cy + s * 0.16, s * 0.26
	a0, a1 = math.radians(-100), math.radians(170)
	x0, y0 = wx + r * math.cos(a0), wy + r * math.sin(a0)
	x1, y1 = wx + r * math.cos(a1), wy + r * math.sin(a1)
	wheel = path(f"M{x0:.1f},{y0:.1f} A{r},{r} 0 1 0 {x1:.1f},{y1:.1f}", None, color, w)
	return group(head, body, arm, wheel)


def spoon(cx: float, cy: float, angle: float, length: float = 260, fill: str = "#d9e2ea", width: float = 8) -> str:
	"""Spoon centred on (cx, cy), bowl pointing up when angle == 0."""
	bowl_ry = length * 0.17
	bowl_rx = length * 0.11
	handle_w = length * 0.07
	top = cy - length / 2
	handle = rect(cx - handle_w / 2, top + bowl_ry * 1.5, handle_w, length - bowl_ry * 1.5, fill, INK, width, handle_w / 2)
	bowl = ellipse(cx, top + bowl_ry, bowl_rx, bowl_ry, fill, INK, width)
	shine = ellipse(cx - bowl_rx * 0.35, top + bowl_ry * 0.8, bowl_rx * 0.25, bowl_ry * 0.45, "#ffffff", None)
	return group(handle, bowl, shine, transform=f"rotate({angle} {cx} {cy})")


def clip(clip_id: str, shape_d: str, *children: str) -> str:
	return (f'<defs><clipPath id="{clip_id}"><path d="{shape_d}"/></clipPath></defs>'
		f'<g clip-path="url(#{clip_id})">' + "".join(children) + "</g>")
