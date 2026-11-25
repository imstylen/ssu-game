"""Render placeholder projectile art.

Usage (from the repository root):
    python tools/projectile_art/build.py                    # render every projectile
    python tools/projectile_art/build.py power_star red_tape
    python tools/projectile_art/build.py --sheet sheet.png  # also write a contact sheet on light and dark tiles

Each projectile is a ``draw_<id>()`` function below that returns subject SVG in a
256x256 space centred on (128, 128). Directional projectiles point toward +X so the
game can rotate them to face their heading. SVG sources go to
tools/projectile_art/svg/<id>.svg; transparent PNGs go to battle/projectiles/art/<id>.png.
"""
from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path

ART_DIR = Path(__file__).resolve().parent
ROOT = ART_DIR.parents[1]
sys.path.insert(0, str(ROOT / "tools" / "card_art"))
from art_lib import INK, circle, ellipse, heart, path, rect, sparkle, star  # noqa: E402

VIEW = 256
OUTPUT_SIZE = 128
OUT_DIR = ROOT / "battle" / "projectiles" / "art"


# ------------------------------------------------------------- projectiles

def draw_power_star() -> str:
	"""Default ally attack: a cheerful gold star."""
	return "".join([
		star(128, 132, 96, fill="#F4B942", width=9, inner=0.5),
		star(128, 132, 58, fill="#FFD95A", stroke=None, inner=0.5),
		circle(110, 128, 7, fill=INK, stroke=None),
		circle(146, 128, 7, fill=INK, stroke=None),
		path("M114,148 Q128,160 142,148", width=6),
		sparkle(100, 92, 12),
	])


def draw_kind_spark() -> str:
	"""Card-effect damage: a teal four-point spark."""
	return "".join([
		path(_spark_d(128, 128, 100, 0.22), fill="#48CFAE", width=9),
		path(_spark_d(128, 128, 54, 0.22), fill="#D6F8ED", stroke=None),
		circle(128, 128, 14, fill="#FFFFFF", stroke=None),
	])


def draw_helping_heart() -> str:
	"""Healing: a mint heart with a white plus."""
	return "".join([
		heart(128, 132, 88, fill="#6FD69B", width=9),
		rect(118, 96, 20, 60, fill="#FFFFFF", stroke=None, r=6),
		rect(98, 116, 60, 20, fill="#FFFFFF", stroke=None, r=6),
	])


def draw_red_tape() -> str:
	"""Default enemy attack: a curling strip of red tape, pointing toward +X."""
	ribbon = ("M20,132 C60,70 100,170 140,112 C168,74 196,84 220,98 L206,150 "
		"C188,138 176,134 160,156 C118,220 72,128 40,188 Z")
	return "".join([
		path(ribbon, fill="#D9547F", width=9),
		path("M44,150 C76,112 104,182 136,140", stroke="#A52E57", width=8),
		path("M160,116 C178,100 196,108 210,118", stroke="#A52E57", width=8),
		path("M206,150 L220,98 L244,132 Z", fill="#A52E57", width=8),
	])


def draw_barrier_brick() -> str:
	"""Heavy enemy attack: a cracked barrier brick."""
	return "".join([
		rect(42, 70, 172, 116, fill="#B9788E", width=9, r=14),
		rect(56, 84, 144, 22, fill="#CF97A9", stroke=None, r=8),
		path("M42,128 L214,128", stroke="#7D4A5F", width=7),
		path("M100,70 L100,128 M156,128 L156,186", stroke="#7D4A5F", width=7),
		path("M168,78 L150,104 L166,114 L148,140", stroke=INK, width=6),
		ellipse(92, 158, 9, 6, fill="#7D4A5F", stroke=None),
	])


PROJECTILES = {
	"power_star": draw_power_star,
	"kind_spark": draw_kind_spark,
	"helping_heart": draw_helping_heart,
	"red_tape": draw_red_tape,
	"barrier_brick": draw_barrier_brick,
}


# ----------------------------------------------------------------- helpers

def _spark_d(cx: float, cy: float, s: float, waist: float) -> str:
	w = s * waist
	return (f"M{cx},{cy - s} Q{cx + w},{cy - w} {cx + s},{cy} Q{cx + w},{cy + w} {cx},{cy + s} "
		f"Q{cx - w},{cy + w} {cx - s},{cy} Q{cx - w},{cy - w} {cx},{cy - s} Z")


def compose(subject_svg: str) -> str:
	"""Wrap the subject with a white sticker outline so it reads on any background."""
	return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{OUTPUT_SIZE}" height="{OUTPUT_SIZE}" '
		f'viewBox="0 0 {VIEW} {VIEW}">'
		'<defs><filter id="sticker" x="-20%" y="-20%" width="140%" height="140%">'
		'<feMorphology in="SourceAlpha" operator="dilate" radius="7" result="fat"/>'
		'<feFlood flood-color="#ffffff"/><feComposite in2="fat" operator="in" result="outline"/>'
		'<feMerge><feMergeNode in="outline"/><feMergeNode in="SourceGraphic"/></feMerge>'
		"</filter></defs>"
		f'<g filter="url(#sticker)">{subject_svg}</g></svg>')


def render_png(svg: str, out_path: Path) -> None:
	from PIL import Image

	try:
		import resvg_py
	except ImportError as error:
		raise SystemExit("Install resvg-py (pip install resvg-py) or render the SVG with Godot's "
			"Image.load_svg_from_string.") from error
	image = Image.open(io.BytesIO(bytes(resvg_py.svg_to_bytes(svg_string=svg)))).convert("RGBA")
	if image.size != (OUTPUT_SIZE, OUTPUT_SIZE):
		image = image.resize((OUTPUT_SIZE, OUTPUT_SIZE))
	out_path.parent.mkdir(parents=True, exist_ok=True)
	image.save(out_path)


def build(projectile_id: str) -> Path:
	svg = compose(PROJECTILES[projectile_id]())
	svg_path = ART_DIR / "svg" / f"{projectile_id}.svg"
	svg_path.parent.mkdir(parents=True, exist_ok=True)
	svg_path.write_text(svg, encoding="utf-8", newline="\n")
	png_path = OUT_DIR / f"{projectile_id}.png"
	render_png(svg, png_path)
	return png_path


def contact_sheet(items: list[tuple[str, Path]], out_path: Path, tile: int = 160) -> None:
	"""One row per background (light battle surface, dark ink) so contrast is easy to judge."""
	from PIL import Image, ImageDraw

	backgrounds = [(255, 244, 250), (75, 49, 90)]
	label_h = 26
	sheet = Image.new("RGB", (len(items) * tile, len(backgrounds) * tile + label_h), "white")
	draw = ImageDraw.Draw(sheet)
	for column, (projectile_id, png) in enumerate(items):
		sprite = Image.open(png).convert("RGBA")
		for row, colour in enumerate(backgrounds):
			cell = Image.new("RGBA", (tile, tile), colour + (255,))
			offset = (tile - sprite.width) // 2
			cell.alpha_composite(sprite, (offset, offset))
			sheet.paste(cell.convert("RGB"), (column * tile, row * tile))
		draw.text((column * tile + 8, len(backgrounds) * tile + 7), projectile_id, fill=(60, 40, 80))
	out_path.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(out_path)


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("ids", nargs="*", metavar="id")
	parser.add_argument("--sheet", type=Path)
	args = parser.parse_args()
	unknown = [projectile_id for projectile_id in args.ids if projectile_id not in PROJECTILES]
	if unknown:
		parser.error(f"unknown projectile(s) {unknown}; choose from {list(PROJECTILES)}")
	built = []
	for projectile_id in args.ids or list(PROJECTILES):
		png = build(projectile_id)
		built.append((projectile_id, png))
		print(f"rendered {projectile_id} -> {png}")
	if args.sheet:
		contact_sheet(built, args.sheet)
		print(f"contact sheet -> {args.sheet}")


if __name__ == "__main__":
	main()
