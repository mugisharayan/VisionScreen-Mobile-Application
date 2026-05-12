#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]

BRAND_DEEP = (19, 78, 74, 255)
BRAND = (13, 148, 136, 255)
BRAND_LIGHT = (204, 251, 241, 255)
WHITE = (255, 255, 255, 255)
WHITE_SOFT = (255, 255, 255, 140)
TRANSPARENT = (0, 0, 0, 0)


def _circle_bounds(cx: float, cy: float, radius: float) -> tuple[float, float, float, float]:
    return (cx - radius, cy - radius, cx + radius, cy + radius)


def draw_eye_mark(
    image: Image.Image,
    mark_size: int,
    *,
    monochrome: bool = False,
    halo: bool = False,
) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    cx = image.width / 2
    cy = image.height / 2
    radius = mark_size / 2
    outer_radius = radius * 0.74
    iris_radius = outer_radius * 0.63
    pupil_radius = outer_radius * 0.29

    if halo:
        halo_width = max(2, round(mark_size * 0.055))
        draw.ellipse(
            _circle_bounds(cx, cy, radius * 0.92),
            outline=(BRAND_LIGHT[0], BRAND_LIGHT[1], BRAND_LIGHT[2], 90),
            width=halo_width,
        )

    if monochrome:
        draw.ellipse(_circle_bounds(cx, cy, outer_radius), fill=WHITE)
        draw.ellipse(_circle_bounds(cx, cy, iris_radius), fill=TRANSPARENT)
        draw.ellipse(_circle_bounds(cx, cy, pupil_radius), fill=WHITE)
        return

    draw.ellipse(_circle_bounds(cx, cy, outer_radius), fill=BRAND)
    draw.ellipse(_circle_bounds(cx, cy, iris_radius), fill=BRAND_LIGHT)
    draw.ellipse(_circle_bounds(cx, cy, pupil_radius), fill=BRAND_DEEP)

    highlight_radius = outer_radius * 0.085
    draw.ellipse(
        _circle_bounds(
            cx - outer_radius * 0.18,
            cy - outer_radius * 0.17,
            highlight_radius,
        ),
        fill=WHITE,
    )
    draw.ellipse(
        _circle_bounds(
            cx + outer_radius * 0.11,
            cy + outer_radius * 0.12,
            outer_radius * 0.035,
        ),
        fill=WHITE_SOFT,
    )


def make_square_icon(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), BRAND_DEEP)
    draw_eye_mark(image, round(size * 0.58))
    return image


def make_foreground(size: int, *, monochrome: bool = False) -> Image.Image:
    image = Image.new("RGBA", (size, size), TRANSPARENT)
    draw_eye_mark(image, round(size * 0.60), monochrome=monochrome)
    return image


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG")


def generate_android_icons() -> None:
    mipmap_sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    for density, size in mipmap_sizes.items():
        path = ROOT / "android/app/src/main/res" / f"mipmap-{density}" / "ic_launcher.png"
        save_png(make_square_icon(size), path)

    drawable_dir = ROOT / "android/app/src/main/res/drawable-nodpi"
    save_png(make_foreground(432), drawable_dir / "ic_launcher_foreground.png")
    save_png(
        make_foreground(432, monochrome=True),
        drawable_dir / "ic_launcher_monochrome.png",
    )


def generate_ios_icons() -> None:
    appicon_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    with (appicon_dir / "Contents.json").open() as handle:
        contents = json.load(handle)

    for image_entry in contents["images"]:
        filename = image_entry.get("filename")
        if not filename:
            continue

        point_size = float(image_entry["size"].split("x")[0])
        scale = int(image_entry["scale"].replace("x", ""))
        pixel_size = round(point_size * scale)
        save_png(make_square_icon(pixel_size), appicon_dir / filename)


def main() -> None:
    generate_android_icons()
    generate_ios_icons()
    print("Generated Android and iOS brand icons.")


if __name__ == "__main__":
    main()
