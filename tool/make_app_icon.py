"""Writes every size in AppIcon.appiconset from the squirrel icon master.

Source: design/app-icon/app-icon-master.png (1024x1024, no transparency, as
the App Store requires). Run from the repo root after changing the master:

    python tool/make_app_icon.py

Requires Pillow. Also refreshes site/icon.png for the public pages.
"""

import json
from pathlib import Path

from PIL import Image

MASTER = Path("design/app-icon/app-icon-master.png")
ICONSET = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
SITE_ICON = Path("site/icon.png")


def main() -> None:
    master = Image.open(MASTER).convert("RGB")  # iOS icons must not have alpha
    assert master.size == (1024, 1024), f"master must be 1024x1024, got {master.size}"
    contents = json.loads((ICONSET / "Contents.json").read_text())
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        px = round(points * scale)
        master.resize((px, px), Image.LANCZOS).save(ICONSET / image["filename"])
        print(f"{image['filename']}: {px}px")
    master.resize((180, 180), Image.LANCZOS).save(SITE_ICON, optimize=True)
    print(f"{SITE_ICON}: 180px")


if __name__ == "__main__":
    main()
