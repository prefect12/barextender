#!/usr/bin/env python3
"""Generate Barextender's original macOS app icon at every size in its asset catalog."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "Ice/Assets.xcassets/AppIcon.appiconset"
SIZE = 1024


def create_master() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    pixels = image.load()
    top = (15, 21, 37)
    bottom = (31, 43, 68)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        color = tuple(round(a * (1 - t) + b * t) for a, b in zip(top, bottom))
        for x in range(SIZE):
            pixels[x, y] = (*color, 255)

    # Soft cool light keeps the mark legible on both dark and light desktops.
    glow = Image.new("RGBA", image.size)
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((100, 70, 780, 650), fill=(43, 111, 255, 48))
    glow_draw.ellipse((440, 400, 1040, 1020), fill=(40, 197, 208, 28))
    image = Image.alpha_composite(image, glow.filter(ImageFilter.GaussianBlur(115)))

    mask = Image.new("L", image.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=222, fill=255)
    image.putalpha(mask)

    # A compact status bar with one highlighted item.
    shadow = Image.new("RGBA", image.size)
    ImageDraw.Draw(shadow).rounded_rectangle((138, 222, 886, 424), radius=62, fill=(0, 0, 0, 155))
    image = Image.alpha_composite(image, shadow.filter(ImageFilter.GaussianBlur(24)))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((134, 210, 890, 414), radius=62, fill=(25, 36, 57, 255), outline=(88, 108, 143, 205), width=5)

    # Small app/status marks.
    draw.rounded_rectangle((194, 282, 294, 348), radius=21, fill=(37, 190, 202, 255))
    draw.ellipse((224, 298, 264, 338), fill=(224, 251, 255, 255))
    draw.rounded_rectangle((324, 282, 424, 348), radius=21, fill=(115, 103, 250, 255))
    draw.rounded_rectangle((454, 282, 554, 348), radius=21, fill=(237, 153, 83, 255))
    draw.ellipse((484, 298, 524, 338), fill=(255, 226, 194, 255))
    draw.rounded_rectangle((584, 282, 684, 348), radius=21, fill=(75, 190, 137, 255))
    draw.rounded_rectangle((714, 282, 814, 348), radius=21, fill=(47, 62, 86, 255))

    # Downward chevron connects the visible row to the organized drawer.
    draw.line((468, 455, 512, 493, 556, 455), fill=(87, 213, 221, 255), width=18, joint="curve")
    draw.line((468, 480, 512, 518, 556, 480), fill=(58, 150, 197, 210), width=12, joint="curve")

    # Hidden-item drawer with three aligned rows.
    panel_shadow = Image.new("RGBA", image.size)
    ImageDraw.Draw(panel_shadow).rounded_rectangle((188, 560, 836, 834), radius=50, fill=(0, 0, 0, 160))
    image = Image.alpha_composite(image, panel_shadow.filter(ImageFilter.GaussianBlur(25)))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((188, 548, 836, 822), radius=50, fill=(24, 35, 56, 248), outline=(67, 88, 121, 220), width=5)

    rows = (
        (602, (63, 204, 211, 255), 468),
        (680, (145, 126, 255, 255), 386),
        (758, (243, 173, 101, 255), 430),
    )
    for y, color, line_width in rows:
        draw.ellipse((246, y, 290, y + 44), fill=color)
        draw.rounded_rectangle((326, y + 8, 326 + line_width, y + 36), radius=14, fill=(194, 207, 229, 220))
        draw.rounded_rectangle((770, y + 10, 796, y + 34), radius=12, fill=(92, 112, 146, 220))

    return image


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    master = create_master()
    variants = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for filename, size in variants.items():
        master.resize((size, size), Image.Resampling.LANCZOS).save(OUTPUT / filename)


if __name__ == "__main__":
    main()
