# Placeholder card art

Flat-vector SVG placeholders, authored in Python and rendered to 1024×1024 PNG.

## Requirements

- Python 3.11+
- `pip install resvg-py pillow`

If `resvg-py` isn't available, render `svg/<id>.svg` with Godot's `Image.load_svg_from_string` and `save_png`.

## Layout

- `art_lib.py`: shared primitives (circle, ellipse, path, eye, blush, smile, heart, star, sparkle). It also provides `compose()`, which adds the pastel style background, decorations, and the white sticker outline around the subject.
- `cards/<card_id>.py`: one module per card. Each defines `STYLE` (berry, lavender, mint, peach or sky) and `draw() -> str`, which returns the subject SVG in a 1024×1024 space. Keep the subject roughly within x 180–850 and y 180–900, leaving room for the outline. `_example_otter.py` is a reference and isn't a card.
- `svg/<id>.svg`: generated full SVGs.
- `build.py`: renders the cards.

## Commands (from the repository root)

```powershell
python tools/card_art/build.py id1 id2                       # writes cards/definitions/<id>/<id>.png
python tools/card_art/build.py --out preview_dir id1         # preview elsewhere
python tools/card_art/build.py --sheet sheet.png id1 id2     # plus a labelled contact sheet
```

These are placeholders, so readability matters more than polish. Draw the animal and its assistive device or accommodation with big, simple shapes, warm expressions and the shared ink outline (`INK`).
