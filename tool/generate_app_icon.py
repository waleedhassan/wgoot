import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_PATH = os.environ.get(
    "MATERIAL_ICONS_FONT",
    r"F:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf",
)
MOSQUE_ROUNDED = chr(0xF0355)

HERO_START = (0x7E, 0x51, 0x30)
HERO_END = (0x2E, 0x1A, 0x0D)
HIGHLIGHT = (0x9A, 0x66, 0x3C)
SHADE = (0x1F, 0x11, 0x08)
CREAM = (0xFA, 0xF2, 0xE2)

RENDER = 1024


def _gradient(size):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = ((size - 1 - x) + y) / (2 * (size - 1))
            px[x, y] = (
                int(HERO_START[0] + (HERO_END[0] - HERO_START[0]) * t),
                int(HERO_START[1] + (HERO_END[1] - HERO_START[1]) * t),
                int(HERO_START[2] + (HERO_END[2] - HERO_START[2]) * t),
            )
    return img


def _glow(img, center, radius, color, strength):
    size = img.size[0]
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse(
        [center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius],
        fill=int(255 * strength),
    )
    mask = mask.filter(ImageFilter.GaussianBlur(radius * 0.55))
    return Image.composite(Image.new("RGB", img.size, color), img, mask)


def background(size=RENDER):
    img = _gradient(size)
    img = _glow(img, (size * 0.72, size * 0.2), size * 0.42, HIGHLIGHT, 0.45)
    img = _glow(img, (size * 0.2, size * 0.9), size * 0.4, SHADE, 0.35)
    return img.convert("RGBA")


def _glyph(size, ratio, color):
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    font = ImageFont.truetype(FONT_PATH, int(size * ratio))
    draw = ImageDraw.Draw(layer)
    box = draw.textbbox((0, 0), MOSQUE_ROUNDED, font=font)
    draw.text(
        ((size - (box[2] - box[0])) / 2 - box[0], (size - (box[3] - box[1])) / 2 - box[1]),
        MOSQUE_ROUNDED,
        font=font,
        fill=color,
    )
    return layer


def foreground(ratio, size=RENDER, color=CREAM + (255,), shadow=True):
    glyph = _glyph(size, ratio, color)
    if not shadow:
        return glyph
    alpha = glyph.split()[3].point(lambda v: int(v * 0.45))
    drop = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    drop.putalpha(alpha)
    drop = drop.filter(ImageFilter.GaussianBlur(size * 0.02))
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    layer.paste(drop, (0, int(size * 0.012)))
    return Image.alpha_composite(layer, glyph)


def icon(ratio=0.5, size=RENDER, round_mask=False):
    img = Image.alpha_composite(background(size), foreground(ratio, size))
    if round_mask:
        mask = Image.new("L", (size * 4, size * 4), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, size * 4 - 1, size * 4 - 1], fill=255)
        img.putalpha(mask.resize((size, size), Image.LANCZOS))
    return img


def save(img, path, sizes, flatten=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = img.resize((sizes, sizes), Image.LANCZOS)
    if flatten:
        base = Image.new("RGB", out.size, (0, 0, 0))
        base.paste(out, mask=out.split()[3])
        out = base
    out.save(path)


ANDROID_DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
"""


def write_android():
    res = os.path.join(ROOT, "android", "app", "src", "main", "res")
    square = icon(0.5)
    round_icon = icon(0.46, round_mask=True)
    bg = background()
    fg = foreground(0.38)
    mono = foreground(0.38, color=(255, 255, 255, 255), shadow=False)

    for density, scale in ANDROID_DENSITIES.items():
        folder = os.path.join(res, "mipmap-" + density)
        save(square, os.path.join(folder, "ic_launcher.png"), int(48 * scale), flatten=True)
        save(round_icon, os.path.join(folder, "ic_launcher_round.png"), int(48 * scale))
        save(bg, os.path.join(folder, "ic_launcher_background.png"), int(108 * scale), flatten=True)
        save(fg, os.path.join(folder, "ic_launcher_foreground.png"), int(108 * scale))
        save(mono, os.path.join(folder, "ic_launcher_monochrome.png"), int(108 * scale))

    anydpi = os.path.join(res, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        with open(os.path.join(anydpi, name), "w", encoding="utf-8") as handle:
            handle.write(ADAPTIVE_XML)


def write_ios():
    folder = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    with open(os.path.join(folder, "Contents.json"), encoding="utf-8") as handle:
        contents = json.load(handle)
    square = icon(0.48)
    for image in contents["images"]:
        side = float(image["size"].split("x")[0]) * float(image["scale"].rstrip("x"))
        save(square, os.path.join(folder, image["filename"]), int(round(side)), flatten=True)


def write_web():
    folder = os.path.join(ROOT, "web")
    square = icon(0.5)
    maskable = icon(0.38)
    save(square, os.path.join(folder, "icons", "Icon-192.png"), 192, flatten=True)
    save(square, os.path.join(folder, "icons", "Icon-512.png"), 512, flatten=True)
    save(maskable, os.path.join(folder, "icons", "Icon-maskable-192.png"), 192, flatten=True)
    save(maskable, os.path.join(folder, "icons", "Icon-maskable-512.png"), 512, flatten=True)
    save(square, os.path.join(folder, "favicon.png"), 32, flatten=True)


def write_master():
    save(icon(0.5), os.path.join(ROOT, "assets", "icon", "app_icon.png"), 1024, flatten=True)


if __name__ == "__main__":
    if not os.path.exists(FONT_PATH):
        sys.exit("MaterialIcons font not found: " + FONT_PATH)
    write_master()
    write_android()
    write_ios()
    write_web()
    print("app icons generated")
