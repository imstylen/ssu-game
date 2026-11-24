"""Shared helpers for placeholder card art.

Every card is a module in ``tools/card_art/cards/<card_id>.py`` exposing:

    STYLE = "mint"            # berry | lavender | mint | peach | sky
    def draw() -> str:        # SVG markup for the subject, in a 1024x1024 space

``build.py`` wraps the subject with the shared pastel background, sparkles and
sticker outline, writes ``tools/card_art/svg/<id>.svg`` and renders the PNG to
``cards/definitions/<id>/<id>.png``.
"""
from __future__ import annotations

import io
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART_DIR = Path(__file__).resolve().parent
SIZE = 1024
INK = "#4b3159"  # shared dark outline colour (matches card title colour)

# Background gradient stops (top, bottom) and accent colours per card style.
STYLES: dict[str, dict[str, str]] = {
	"berry": {"top": "#ffe3ef", "bottom": "#f7c6dc", "accent": "#d96a99", "deco": "#ffffff"},
	"lavender": {"top": "#efe6ff", "bottom": "#d9c8f2", "accent": "#966cc9", "deco": "#ffffff"},
	"mint": {"top": "#e3fff3", "bottom": "#bfeedd", "accent": "#45b998", "deco": "#ffffff"},
	"peach": {"top": "#fff0e3", "bottom": "#ffd2b8", "accent": "#e38350", "deco": "#ffffff"},
	"sky": {"top": "#e6f4ff", "bottom": "#c3e0f7", "accent": "#6ea9dc", "deco": "#ffffff"},
}


# ---------------------------------------------------------------- primitives

def attrs(fill: str | None = None, stroke: str | None = INK, width: float = 10, extra: str = "") -> str:
	parts = [f'fill="{fill or "none"}"']
	if stroke:
		parts.append(f'stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"')
	if extra:
		parts.append(extra)
	return " ".join(parts)


def circle(cx, cy, r, fill=None, stroke=INK, width=10, extra=""):
	return f'<circle cx="{cx}" cy="{cy}" r="{r}" {attrs(fill, stroke, width, extra)}/>'


def ellipse(cx, cy, rx, ry, fill=None, stroke=INK, width=10, extra="", rotate: float = 0):
	t = f' transform="rotate({rotate} {cx} {cy})"' if rotate else ""
	return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" {attrs(fill, stroke, width, extra)}{t}/>'


def rect(x, y, w, h, fill=None, stroke=INK, width=10, r=0, extra="", rotate: float = 0):
	t = f' transform="rotate({rotate} {x + w / 2} {y + h / 2})"' if rotate else ""
	return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" {attrs(fill, stroke, width, extra)}{t}/>'


def path(d, fill=None, stroke=INK, width=10, extra=""):
	return f'<path d="{d}" {attrs(fill, stroke, width, extra)}/>'


def line(x1, y1, x2, y2, stroke=INK, width=10):
	return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" {attrs(None, stroke, width)}/>'


def polygon(points, fill=None, stroke=INK, width=10):
	pts = " ".join(f"{x},{y}" for x, y in points)
	return f'<polygon points="{pts}" {attrs(fill, stroke, width)}/>'


def text(x, y, value, size=60, fill=INK, weight="bold", anchor="middle"):
	return (f'<text x="{x}" y="{y}" font-family="Arial, sans-serif" font-size="{size}" '
		f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{value}</text>')


def group(*children: str, transform: str = "") -> str:
	t = f' transform="{transform}"' if transform else ""
	return f"<g{t}>" + "".join(children) + "</g>"


# ------------------------------------------------------------- face pieces

def eye(cx, cy, r=26, look=(0, 0)):
	"""Big cute eye with highlight."""
	dx, dy = look
	return (circle(cx, cy, r, "#2e2236", None)
		+ circle(cx - r * 0.35 + dx, cy - r * 0.35 + dy, r * 0.38, "#ffffff", None)
		+ circle(cx + r * 0.35 + dx, cy + r * 0.3 + dy, r * 0.16, "#ffffff", None))


def closed_eye(cx, cy, w=40):
	return path(f"M{cx - w / 2},{cy} Q{cx},{cy + w * 0.6} {cx + w / 2},{cy}", None, "#2e2236", 9)


def blush(cx, cy, rx=30, ry=16, color="#ff9fb8"):
	return ellipse(cx, cy, rx, ry, color, None, extra='opacity="0.7"')


def smile(cx, cy, w=50, open_mouth=False):
	if open_mouth:
		return path(f"M{cx - w / 2},{cy} Q{cx},{cy + w * 0.9} {cx + w / 2},{cy} Z", "#c94f6d", "#2e2236", 8)
	return path(f"M{cx - w / 2},{cy} Q{cx},{cy + w * 0.6} {cx + w / 2},{cy}", None, "#2e2236", 8)


# ------------------------------------------------------------ decorations

def star(cx, cy, r, fill="#ffd95a", stroke=INK, width=8, points=5, inner=0.45):
	pts = []
	for i in range(points * 2):
		rad = r if i % 2 == 0 else r * inner
		a = math.pi / points * i - math.pi / 2
		pts.append((round(cx + rad * math.cos(a), 1), round(cy + rad * math.sin(a), 1)))
	return polygon(pts, fill, stroke, width)


def heart(cx, cy, s, fill="#ff7a9c", stroke=INK, width=8):
	d = (f"M{cx},{cy + s * 0.9} C{cx - s * 1.4},{cy} {cx - s * 0.8},{cy - s * 1.1} {cx},{cy - s * 0.35} "
		f"C{cx + s * 0.8},{cy - s * 1.1} {cx + s * 1.4},{cy} {cx},{cy + s * 0.9} Z")
	return path(d, fill, stroke, width)


def sparkle(cx, cy, s, fill="#ffffff"):
	d = (f"M{cx},{cy - s} Q{cx + s * 0.18},{cy - s * 0.18} {cx + s},{cy} "
		f"Q{cx + s * 0.18},{cy + s * 0.18} {cx},{cy + s} Q{cx - s * 0.18},{cy + s * 0.18} {cx - s},{cy} "
		f"Q{cx - s * 0.18},{cy - s * 0.18} {cx},{cy - s} Z")
	return path(d, fill, None)


def _background(style: str, seed: str) -> str:
	pal = STYLES[style]
	rng = random.Random(seed)
	parts = [
		"<defs>",
		f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{pal["top"]}"/>'
		f'<stop offset="1" stop-color="{pal["bottom"]}"/></linearGradient>',
		'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff" stop-opacity="0.75"/>'
		'<stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>',
		# Sticker outline: dilate the subject's alpha and flood it white, then draw the subject on top.
		'<filter id="sticker" x="-20%" y="-20%" width="140%" height="140%">'
		'<feMorphology in="SourceAlpha" operator="dilate" radius="16" result="fat"/>'
		'<feFlood flood-color="#ffffff"/><feComposite in2="fat" operator="in" result="outline"/>'
		'<feOffset in="fat" dx="0" dy="10" result="shadowOff"/>'
		'<feFlood flood-color="#4b3159" flood-opacity="0.18"/><feComposite in2="shadowOff" operator="in" result="shadow"/>'
		'<feMerge><feMergeNode in="shadow"/><feMergeNode in="outline"/><feMergeNode in="SourceGraphic"/></feMerge>'
		"</filter>",
		"</defs>",
		f'<rect width="{SIZE}" height="{SIZE}" fill="url(#bg)"/>',
		f'<circle cx="512" cy="540" r="440" fill="url(#glow)"/>',
	]
	for _ in range(14):
		x, y = rng.uniform(40, 984), rng.uniform(40, 984)
		kind = rng.random()
		if kind < 0.5:
			parts.append(sparkle(x, y, rng.uniform(10, 24), pal["deco"]))
		elif kind < 0.75:
			parts.append(circle(x, y, rng.uniform(5, 11), pal["accent"], None, extra='opacity="0.45"'))
		else:
			parts.append(heart(x, y, rng.uniform(12, 20), pal["accent"], None).replace("/>", ' opacity="0.4"/>'))
	return "".join(parts)


def compose(style: str, subject_svg: str, seed: str) -> str:
	if style not in STYLES:
		raise ValueError(f"Unknown style {style!r}")
	return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">'
		+ _background(style, seed)
		+ f'<g filter="url(#sticker)">{subject_svg}</g>'
		+ "</svg>")


def render_png(svg: str, out_path: Path) -> None:
	from PIL import Image

	try:
		import resvg_py
		data = bytes(resvg_py.svg_to_bytes(svg_string=svg))
	except ImportError as error:  # pragma: no cover - fallback documented in README
		raise SystemExit("Install resvg-py (pip install resvg-py) or render the SVG with Godot's "
			"Image.load_svg_from_string.") from error
	image = Image.open(io.BytesIO(data)).convert("RGB")
	if image.size != (SIZE, SIZE):
		image = image.resize((SIZE, SIZE))
	out_path.parent.mkdir(parents=True, exist_ok=True)
	image.save(out_path)
