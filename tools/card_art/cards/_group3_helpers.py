"""Shared helpers for group-3 placeholder cards (not a card; build.py skips underscore files)."""
from art_lib import INK, path


def tube(d: str, color: str, width: float, outline: float = 8) -> str:
	"""A stroked path with an ink outline, handy for trunks, tails, tubing and frames."""
	return path(d, None, INK, width + outline * 2) + path(d, None, color, width)
