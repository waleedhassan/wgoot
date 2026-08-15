import os
import subprocess

from . import shell
from .log import ReleaseError, banner, info, ok, step, warn

try:
    from PIL import Image
except ModuleNotFoundError:
    Image = None

MIN_SIDE = 320
MAX_SIDE = 3840
MAX_RATIO = 2.0

CLASSES = ("phone", "tablet7", "tablet10")


def _out_dir(config, device_class):
    return os.path.join(config.store_dir, "graphics", "screenshots", device_class)


def _raw_dir(config):
    return os.path.join(config.store_dir, "graphics", "screenshots", "raw")


def devices():
    if not shell.which("adb"):
        raise ReleaseError(
            "adb was not found on PATH. It ships with the Android SDK platform-tools."
        )
    text = shell.output(["adb", "devices"], check=False)
    found = []
    for line in text.splitlines()[1:]:
        parts = line.split()
        if len(parts) >= 2 and parts[1] == "device":
            found.append(parts[0])
    return found


def capture(config, device_class="phone", serial=None):
    banner("capture screenshots")

    available = devices()
    if not available:
        raise ReleaseError(
            "no device is connected. Start an emulator or plug in a phone with USB debugging on."
        )
    serial = serial or available[0]
    info("device " + serial)

    raw = _raw_dir(config)
    os.makedirs(raw, exist_ok=True)

    info("Navigate the app on the device, then press Enter here to grab each screen.")
    info("Press Enter on an empty prompt with no new screens left, or type q, to stop.")

    index = 1
    taken = []
    while index <= 8:
        answer = input("capture {0}/8 (Enter = shoot, q = done): ".format(index)).strip()
        if answer.lower() in ("q", "quit", "done"):
            break

        destination = os.path.join(raw, "{0}-{1:02d}.png".format(device_class, index))
        completed = subprocess.run(
            [shell.which("adb"), "-s", serial, "exec-out", "screencap", "-p"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if completed.returncode != 0 or not completed.stdout:
            warn("capture failed: " + completed.stderr.decode("utf-8", "replace").strip())
            continue

        with open(destination, "wb") as handle:
            handle.write(completed.stdout)
        ok(os.path.relpath(destination, config.root))
        taken.append(destination)
        index += 1

    if not taken:
        warn("nothing captured")
    return taken


def _fit(image):
    width, height = image.size
    scale = 1.0

    if min(width, height) < MIN_SIDE:
        scale = float(MIN_SIDE) / min(width, height)
    if max(width * scale, height * scale) > MAX_SIDE:
        scale = float(MAX_SIDE) / max(width, height)

    if scale != 1.0:
        width = max(1, int(round(width * scale)))
        height = max(1, int(round(height * scale)))
        image = image.resize((width, height), Image.LANCZOS)

    return image


def process(config, device_class="phone"):
    banner("process screenshots")
    if Image is None:
        raise ReleaseError(
            "Pillow is required. Run: pip install -r store/tool/requirements.txt"
        )

    raw = _raw_dir(config)
    if not os.path.isdir(raw):
        raise ReleaseError("no raw screenshots in " + raw)

    names = sorted(
        name
        for name in os.listdir(raw)
        if name.lower().endswith((".png", ".jpg", ".jpeg"))
        and (name.startswith(device_class) or "-" not in name)
    )
    if not names:
        raise ReleaseError(
            "no {0} screenshots in {1}. Name them {0}-01.png ...".format(device_class, raw)
        )

    out = _out_dir(config, device_class)
    os.makedirs(out, exist_ok=True)

    written = []
    for index, name in enumerate(names[:8], start=1):
        step(name)
        image = Image.open(os.path.join(raw, name))
        if image.mode in ("RGBA", "P", "LA"):
            background = Image.new("RGB", image.size, (0, 0, 0))
            converted = image.convert("RGBA")
            background.paste(converted, mask=converted.split()[3])
            image = background
        else:
            image = image.convert("RGB")

        image = _fit(image)
        width, height = image.size
        ratio = max(width, height) / float(min(width, height))
        if ratio > MAX_RATIO:
            warn(
                "{0} is {1}x{2}, aspect ratio {3:.2f}:1 exceeds Play's 2:1 limit".format(
                    name, width, height, ratio
                )
            )

        destination = os.path.join(out, "{0:02d}.png".format(index))
        image.save(destination, "PNG")
        ok("{0} -> {1}x{2}".format(os.path.basename(destination), width, height))
        written.append(destination)

    if len(written) < 2:
        warn("Play requires at least 2 screenshots per device class")

    info("output " + out)
    return written
