"""Draws the knowitwhere app icon and writes every size in AppIcon.appiconset.

An orange map pin holding a small storage box, on the app's cream background.
Run from the repo root:  python tool/make_app_icon.py
Requires Pillow.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw

CREAM = (0xFB, 0xF8, 0xF2)
ORANGE = (0xF4, 0x63, 0x2A)
INK = (0x1F, 0x1B, 0x18)

ICONSET = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
MASTER = 4096  # drawn large, then downsampled for smooth edges


def draw_master() -> Image.Image:
    s = MASTER
    img = Image.new("RGB", (s, s), CREAM)
    d = ImageDraw.Draw(img)

    # Pin: a circle head plus a triangle whose sides are tangent to it, so
    # the outline is smooth where they meet.
    cx, cy, r = s * 0.5, s * 0.42, s * 0.27
    tip_y = s * 0.86
    dist = tip_y - cy
    tx, ty = r * (1 - (r / dist) ** 2) ** 0.5, r * r / dist
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ORANGE)
    d.polygon([(cx - tx, cy + ty), (cx + tx, cy + ty), (cx, tip_y)], fill=ORANGE)

    # Cream disc inside the pin head.
    inner = r * 0.62
    d.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], fill=CREAM)

    # Storage box: body, lid and a label slot.
    bw, bh = inner * 1.2, inner * 0.86
    top = cy - bh * 0.35
    lid_h = bh * 0.3
    radius = s * 0.012
    d.rounded_rectangle(
        [cx - bw / 2, top + lid_h * 0.55, cx + bw / 2, top + bh],
        radius=radius,
        fill=INK,
    )
    d.rounded_rectangle(
        [cx - bw * 0.58, top, cx + bw * 0.58, top + lid_h],
        radius=radius,
        fill=INK,
    )
    slot_w, slot_h = bw * 0.36, bh * 0.1
    slot_y = top + lid_h + (bh - lid_h) * 0.32
    d.rounded_rectangle(
        [cx - slot_w / 2, slot_y, cx + slot_w / 2, slot_y + slot_h],
        radius=slot_h / 2,
        fill=CREAM,
    )
    return img


def main() -> None:
    master = draw_master()
    contents = json.loads((ICONSET / "Contents.json").read_text())
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        px = round(points * scale)
        master.resize((px, px), Image.LANCZOS).save(ICONSET / image["filename"])
        print(f"{image['filename']}: {px}px")


if __name__ == "__main__":
    main()
