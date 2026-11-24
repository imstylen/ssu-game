"""Render placeholder card art.

Usage (from the repository root):
    python tools/card_art/build.py                 # render every card module
    python tools/card_art/build.py id1 id2         # render selected cards
    python tools/card_art/build.py --sheet out.png id1 id2   # also write a labelled contact sheet

Each card module lives at tools/card_art/cards/<card_id>.py (see art_lib.py).
SVG sources go to tools/card_art/svg/<id>.svg; PNGs go to cards/definitions/<id>/<id>.png.
Pass --out DIR to write PNGs to DIR/<id>.png instead (handy for previews).
"""
from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import art_lib  # noqa: E402


def load_module(card_id: str):
	path = art_lib.ART_DIR / "cards" / f"{card_id}.py"
	spec = importlib.util.spec_from_file_location(f"card_art_{card_id}", path)
	module = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(module)
	return module


def build(card_id: str, out_dir: Path | None) -> Path:
	module = load_module(card_id)
	svg = art_lib.compose(module.STYLE, module.draw(), card_id)
	svg_path = art_lib.ART_DIR / "svg" / f"{card_id}.svg"
	svg_path.parent.mkdir(parents=True, exist_ok=True)
	svg_path.write_text(svg, encoding="utf-8", newline="\n")
	png_path = (out_dir / f"{card_id}.png") if out_dir else art_lib.ROOT / "cards" / "definitions" / card_id / f"{card_id}.png"
	art_lib.render_png(svg, png_path)
	return png_path


def contact_sheet(items: list[tuple[str, Path]], out_path: Path, tile: int = 320, columns: int = 4) -> None:
	from PIL import Image, ImageDraw

	rows = (len(items) + columns - 1) // columns
	label_h = 34
	sheet = Image.new("RGB", (columns * tile, rows * (tile + label_h)), "white")
	draw = ImageDraw.Draw(sheet)
	for index, (card_id, png) in enumerate(items):
		x, y = (index % columns) * tile, (index // columns) * (tile + label_h)
		sheet.paste(Image.open(png).convert("RGB").resize((tile, tile)), (x, y))
		draw.text((x + 8, y + tile + 8), card_id, fill=(60, 40, 80))
	out_path.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(out_path)


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("ids", nargs="*")
	parser.add_argument("--sheet", type=Path)
	parser.add_argument("--out", type=Path)
	args = parser.parse_args()
	ids = args.ids or sorted(p.stem for p in (art_lib.ART_DIR / "cards").glob("*.py") if not p.stem.startswith("_"))
	built = []
	for card_id in ids:
		png = build(card_id, args.out)
		built.append((card_id, png))
		print(f"rendered {card_id} -> {png}")
	if args.sheet:
		contact_sheet(built, args.sheet)
		print(f"contact sheet -> {args.sheet}")


if __name__ == "__main__":
	main()
