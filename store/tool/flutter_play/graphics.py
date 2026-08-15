import glob
import math
import os

from .log import ReleaseError, banner, info, ok, step, warn

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ModuleNotFoundError:
    Image = None

try:
    import arabic_reshaper
    from bidi.algorithm import get_display

    RESHAPER = arabic_reshaper.ArabicReshaper(
        configuration={"delete_harakat": False, "support_ligatures": True}
    )
    SHAPING = True
except ModuleNotFoundError:
    RESHAPER = None
    SHAPING = False

ICON_SIZE = 512
FEATURE_SIZE = (1024, 500)


def _require_pillow():
    if Image is None:
        raise ReleaseError(
            "Pillow is required for graphics. Run: pip install -r store/tool/requirements.txt"
        )


def _rgb(value):
    value = value.lstrip("#")
    if len(value) == 8:
        value = value[2:]
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def _has_arabic(text):
    return any("؀" <= character <= "ۿ" for character in text)


def shape(text):
    if not text:
        return text
    if not _has_arabic(text):
        return text
    if not SHAPING:
        warn("Arabic text needs shaping. Run: pip install arabic-reshaper python-bidi")
        return text
    return get_display(RESHAPER.reshape(text))


def _font(config, size):
    configured = config.get("graphics", "font")
    candidates = []
    if configured:
        candidates.append(config.resolve(configured))
    candidates += sorted(glob.glob(os.path.join(config.root, "assets", "fonts", "*Bold*.ttf")))
    candidates += sorted(glob.glob(os.path.join(config.root, "assets", "fonts", "*.ttf")))

    for path in candidates:
        if os.path.isfile(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default(size)


def _gradient(size, start, end):
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    span = float(max(1, width + height - 2))
    for y in range(height):
        for x in range(width):
            t = ((width - 1 - x) + y) / span
            pixels[x, y] = (
                int(start[0] + (end[0] - start[0]) * t),
                int(start[1] + (end[1] - start[1]) * t),
                int(start[2] + (end[2] - start[2]) * t),
            )
    return image


def _star(draw, center, radius, points, rotation, fill):
    coordinates = []
    for index in range(points * 2):
        angle = rotation + index * math.pi / points
        length = radius if index % 2 == 0 else radius * 0.42
        coordinates.append(
            (center[0] + length * math.cos(angle), center[1] + length * math.sin(angle))
        )
    draw.polygon(coordinates, fill=fill)


def _ornament(size, accent, opacity=18, spacing=118):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    fill = accent + (opacity,)
    rows = size[1] // spacing + 2
    columns = size[0] // spacing + 2
    for row in range(rows):
        for column in range(columns):
            offset = spacing / 2 if row % 2 else 0
            center = (column * spacing + offset, row * spacing)
            _star(draw, center, spacing * 0.30, 8, math.pi / 8, fill)
    return layer


def _glow(image, center, radius, color, strength):
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).ellipse(
        [center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius],
        fill=int(255 * strength),
    )
    mask = mask.filter(ImageFilter.GaussianBlur(radius * 0.55))
    return Image.composite(Image.new("RGB", image.size, color), image, mask)


def _source_icon(config):
    configured = config.get("graphics", "icon_source")
    candidates = []
    if configured:
        candidates.append(config.resolve(configured))
    candidates += [
        config.resolve("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"),
        config.resolve("web/icons/Icon-512.png"),
    ]
    for path in candidates:
        if os.path.isfile(path):
            return path
    return None


def store_icon(config, destination):
    _require_pillow()
    source = _source_icon(config)
    if not source:
        raise ReleaseError(
            "no source icon found. Set graphics.icon_source in release.toml."
        )

    image = Image.open(source).convert("RGBA")
    if image.size != (ICON_SIZE, ICON_SIZE):
        image = image.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)

    flat = Image.new("RGB", image.size, _rgb(config.get("graphics", "background_end")))
    flat.paste(image, mask=image.split()[3])

    opaque = flat.convert("RGBA")
    opaque.putalpha(255)
    opaque.save(destination, "PNG")

    info("source " + os.path.relpath(source, config.root))
    return destination


def feature_graphic(config, destination):
    _require_pillow()

    start = _rgb(config.get("graphics", "background_start"))
    end = _rgb(config.get("graphics", "background_end"))
    accent = _rgb(config.get("graphics", "accent"))
    text_color = _rgb(config.get("graphics", "text"))

    title = config.get("graphics", "title") or config.pubspec["name"]
    subtitle = config.get("graphics", "subtitle") or ""

    rtl = _has_arabic(title) or _has_arabic(subtitle)
    width, height = FEATURE_SIZE

    image = _gradient(FEATURE_SIZE, start, end)
    glow_x = width * (0.22 if rtl else 0.78)
    image = _glow(image, (glow_x, height * 0.18), 380, accent, 0.20)
    image = image.convert("RGBA")
    image = Image.alpha_composite(image, _ornament(FEATURE_SIZE, accent))

    draw = ImageDraw.Draw(image)

    source = _source_icon(config)
    badge_center = (205 if rtl else width - 205, height // 2)
    if source:
        badge = Image.open(source).convert("RGBA").resize((228, 228), Image.LANCZOS)
        mask = Image.new("L", (912, 912), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, 911, 911], fill=255)
        badge.putalpha(mask.resize((228, 228), Image.LANCZOS))
        draw.ellipse(
            [
                badge_center[0] - 128,
                badge_center[1] - 128,
                badge_center[0] + 128,
                badge_center[1] + 128,
            ],
            outline=accent + (110,),
            width=3,
        )
        image.paste(badge, (badge_center[0] - 114, badge_center[1] - 114), badge)

    title_font = _font(config, 92)
    subtitle_font = _font(config, 40)

    shaped_title = shape(title)
    shaped_subtitle = shape(subtitle)

    anchor_x = width - 78 if rtl else 78
    align = "rt" if rtl else "lt"

    ascent, descent = title_font.getmetrics()
    title_height = ascent + descent
    block_height = title_height + (96 if shaped_subtitle else 0)
    top = (height - block_height) // 2

    draw.text(
        (anchor_x + 3, top + 4), shaped_title, font=title_font, fill=(0, 0, 0, 90), anchor=align
    )
    draw.text(
        (anchor_x, top), shaped_title, font=title_font, fill=text_color + (255,), anchor=align
    )

    rule_y = top + title_height + 22
    rule_end = anchor_x - 150 if rtl else anchor_x + 150
    draw.line([(anchor_x, rule_y), (rule_end, rule_y)], fill=accent + (220,), width=4)
    _star(
        draw,
        (rule_end - 26 if rtl else rule_end + 26, rule_y),
        13,
        8,
        math.pi / 8,
        accent + (230,),
    )

    if shaped_subtitle:
        draw.text(
            (anchor_x, rule_y + 26),
            shaped_subtitle,
            font=subtitle_font,
            fill=accent + (235,),
            anchor=align,
        )

    image.convert("RGB").save(destination, "PNG")
    return destination


def generate(config):
    banner("store graphics")
    _require_pillow()

    out = os.path.join(config.store_dir, "graphics")
    os.makedirs(out, exist_ok=True)

    step("icon-512.png")
    store_icon(config, os.path.join(out, "icon-512.png"))
    ok("512x512 store icon, no transparency")

    step("feature-graphic-1024x500.png")
    feature_graphic(config, os.path.join(out, "feature-graphic-1024x500.png"))
    ok("1024x500 feature graphic")

    if not SHAPING:
        warn("install arabic-reshaper and python-bidi for correct Arabic in graphics")

    info("output " + out)
    return out
