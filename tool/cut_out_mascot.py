"""Cuts the mascot out of its baked-in checkerboard background.

The source PNG has no alpha channel: the "transparency" checkerboard is part
of the pixels. Light, unsaturated pixels connected to the image border are
treated as background; the edge is then feathered and fringe colours are
pulled from the interior so it sits cleanly on dark backgrounds too.

Run from the repo root:  python tool/cut_out_mascot.py
"""

from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

SOURCE = Path("design/mascot-source.png")
OUT = Path("assets/images/mascot.png")
OUT_WIDTH = 800


def is_background(rgb) -> bool:
    r, g, b = rgb
    return min(r, g, b) > 205 and max(r, g, b) - min(r, g, b) < 22


def background_mask(img: Image.Image) -> Image.Image:
    """Flood-fills background-coloured pixels reachable from the border."""
    w, h = img.size
    px = img.load()
    seen = bytearray(w * h)
    queue = deque()
    for x in range(w):
        queue.extend([(x, 0), (x, h - 1)])
    for y in range(h):
        queue.extend([(0, y), (w - 1, y)])
    while queue:
        x, y = queue.popleft()
        i = y * w + x
        if seen[i] or not is_background(px[x, y]):
            continue
        seen[i] = 1
        if x > 0:
            queue.append((x - 1, y))
        if x < w - 1:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y < h - 1:
            queue.append((x, y + 1))
    return Image.frombytes("L", (w, h), bytes(255 if s else 0 for s in seen))


def main() -> None:
    img = Image.open(SOURCE).convert("RGB")
    bg = background_mask(img)

    # Foreground alpha: shrink by ~2px to drop the light fringe, then feather.
    alpha = ImageChops.invert(bg).filter(ImageFilter.MinFilter(5))
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))

    # Decontaminate: replace edge colours with colours from slightly inside.
    inner = img.filter(ImageFilter.MinFilter(1))
    spread = img.copy()
    for _ in range(4):
        spread = spread.filter(ImageFilter.MinFilter(3))
    edge_band = ImageChops.subtract(
        ImageChops.invert(bg).filter(ImageFilter.MinFilter(1)),
        ImageChops.invert(bg).filter(ImageFilter.MinFilter(9)),
    )
    rgb = Image.composite(spread, inner, edge_band)

    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    out = out.crop(out.getbbox())
    ratio = OUT_WIDTH / out.width
    out = out.resize((OUT_WIDTH, round(out.height * ratio)), Image.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT, optimize=True)
    print(f"{OUT}: {out.size}, {OUT.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
