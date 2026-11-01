"""Draws the JinhoDesk icon (option B: PC + phone) into every icon slot of the app."""
import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[1]
TEAL = (15, 107, 92, 255)
WHITE = (255, 255, 255, 255)
YELLOW = (243, 201, 105, 255)
SS = 4  # supersampling factor


def _rrect(d, box, r, s, k, fill=None, outline=None):
    """SVG-style rounded rect: stroke centred on the box edge."""
    x0, y0, x1, y1 = (v * k for v in box)
    h = s * k / 2
    d.rounded_rectangle((x0 - h, y0 - h, x1 + h, y1 + h), radius=(r + s / 2) * k,
                        fill=fill, outline=outline, width=round(s * k) if outline else 0)


def art(size, background="square", mono=False, art_scale=1.0):
    """Returns the icon as RGBA; background: 'square' | 'circle' | None."""
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k = big / 512
    if background == "square":
        d.rounded_rectangle((0, 0, big - 1, big - 1), radius=112 * k, fill=TEAL)
    elif background == "circle":
        d.ellipse((0, 0, big - 1, big - 1), fill=TEAL)

    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    stroke_main = WHITE
    stroke_phone = WHITE if mono else YELLOW
    _rrect(ld, (72, 120, 332, 304), 22, 28, k, outline=stroke_main)
    ld.line((150 * k, 360 * k, 254 * k, 360 * k), fill=stroke_main, width=round(28 * k))
    for cx in (150, 254):
        ld.ellipse(((cx - 14) * k, (360 - 14) * k, (cx + 14) * k, (360 + 14) * k), fill=stroke_main)
    # phone body knocks out the monitor behind it
    mask = Image.new("L", (big, big), 0)
    _rrect(ImageDraw.Draw(mask), (300, 196, 440, 416), 26, 28, k, fill=255)
    layer.paste((0, 0, 0, 0), (0, 0), mask)
    _rrect(ld, (300, 196, 440, 416), 26, 28, k, outline=stroke_phone)
    ld.ellipse(((370 - 12) * k, (378 - 12) * k, (370 + 12) * k, (378 + 12) * k), fill=stroke_phone)

    if art_scale != 1.0:
        inner = round(big * art_scale)
        small = layer.resize((inner, inner), Image.LANCZOS)
        layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        off = (big - inner) // 2
        layer.paste(small, (off, off))
    img.alpha_composite(layer)
    return img.resize((size, size), Image.LANCZOS)


def save(img, rel, mode=None):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    (img.convert(mode) if mode else img).save(path)
    print("wrote", rel, img.size)


def main():
    master = art(1024)
    save(master, "res/icon.png")
    save(art(1024), "res/mac-icon.png")
    for n, rel in ((32, "res/32x32.png"), (64, "res/64x64.png"), (128, "res/128x128.png"), (256, "res/128x128@2x.png")):
        save(art(n), rel)
    sizes = [16, 24, 32, 48, 64, 128, 256]
    ico = art(256)
    for rel in ("res/icon.ico", "flutter/windows/runner/resources/app_icon.ico"):
        (ROOT / rel).parent.mkdir(parents=True, exist_ok=True)
        ico.save(ROOT / rel, sizes=[(s, s) for s in sizes])
        print("wrote", rel)
    art(64).save(ROOT / "res/tray-icon.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48)])
    print("wrote res/tray-icon.ico")

    dens = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    base = "flutter/android/app/src/main/res"
    for name, f in dens.items():
        save(art(round(48 * f)), f"{base}/mipmap-{name}/ic_launcher.png")
        save(art(round(48 * f), background="circle", art_scale=0.86), f"{base}/mipmap-{name}/ic_launcher_round.png")
        save(art(round(108 * f), background=None, art_scale=72 / 108), f"{base}/mipmap-{name}/ic_launcher_foreground.png")
        stat = art(round(24 * f), background=None, mono=True, art_scale=1.15)
        save(stat, f"{base}/mipmap-{name}/ic_stat_logo.png", mode="LA")

    bg = ROOT / base / "values/ic_launcher_background.xml"
    bg.write_text(bg.read_text(encoding="utf-8").replace("#ffffff", "#0f6b5c"), encoding="utf-8")
    print("wrote", bg.relative_to(ROOT))

    svg = (ROOT / "jinho/icon.svg").read_text(encoding="utf-8")
    (ROOT / "flutter/assets/icon.svg").write_text(svg, encoding="utf-8")
    print("wrote flutter/assets/icon.svg")


if __name__ == "__main__":
    main()
