#!/usr/bin/env python3
"""Composes README media from frames rendered by `SysMon --snapshot` (the real SwiftUI view).

Usage: python3 assets/compose_demo.py <frames_dir> <en|tr>
Outputs (next to this file): demo-<lang>-dark.gif, demo-<lang>-light.gif, and (for en) social-preview.png
Requires Pillow.
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).parent
FRAMES_DIR, LANG = Path(sys.argv[1]), sys.argv[2]
N = 32
FINAL_W = 540

SANS = "/System/Library/Fonts/SFNS.ttf"
THEMES = {
    "dark":  dict(bg=(20, 23, 30), bar=(40, 44, 54), text=(232, 235, 242), dim=(150, 158, 175), pill=(70, 100, 150)),
    "light": dict(bg=(212, 219, 230), bar=(240, 242, 246), text=(30, 34, 42), dim=(110, 118, 135), pill=(170, 200, 245)),
}
CPU, RAM = "CPU", "RAM"


def font(size, weight=None):
    f = ImageFont.truetype(SANS, size)
    if weight:
        try:
            f.set_variation_by_name(weight)
        except Exception:
            pass
    return f


def demo_values(i):
    phase = i / N * 2 * math.pi
    fight = N * 5 // 12 <= i < N * 8 // 12
    cpu = 84 + 4 * math.sin(phase * 6) if fight else 22 + 8 * math.sin(phase) + 3 * math.sin(3 * phase)
    ram = 72 + 1 * math.sin(phase)
    return cpu, ram, fight


def shadow_paste(canvas, img, xy, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius=radius, fill=255)
    sh = Image.new("RGBA", (img.width + 120, img.height + 120), (0, 0, 0, 0))
    sh.paste((0, 0, 0, 110), (60, 70), mask)
    sh = sh.filter(ImageFilter.GaussianBlur(26))
    canvas.alpha_composite(sh, (xy[0] - 60, xy[1] - 60))
    canvas.paste(img.convert("RGB"), xy, mask)


def compose(scheme, i):
    th = THEMES[scheme]
    pop = Image.open(FRAMES_DIR / f"{scheme}-{i:02d}.png").convert("RGB")
    pw, ph = pop.size
    margin = 56
    W, H = pw + margin * 2, 56 + 18 + ph + margin
    img = Image.new("RGBA", (W, H), th["bg"] + (255,))
    d = ImageDraw.Draw(img)

    # menu bar
    d.rectangle([0, 0, W, 56], fill=th["bar"])
    d.ellipse([34, 19, 52, 37], fill=th["dim"])
    d.text((74, 15), "Finder     File     Edit     View", font=font(24), fill=th["dim"])

    cpu, ram, fight = demo_values(i)
    tag, num = font(17, "Bold"), font(24, "Medium")
    red = fight
    colr = (255, 105, 97) if red else th["text"]
    parts = [(CPU + " ", tag), (f"{cpu:.0f}%", num), ("   " + RAM + " ", tag), (f"{ram:.0f}%", num)]
    widths = [d.textlength(p, font=f) for p, f in parts]
    total = sum(widths)
    x1 = W - margin + 8
    x0 = x1 - total - 28
    d.rounded_rectangle([x0, 9, x1, 47], radius=12, fill=th["pill"])
    x = x0 + 14
    for (p, f), w in zip(parts, widths):
        d.text((x, 14 if f is num else 20), p, font=f, fill=colr)
        x += w

    shadow_paste(img, pop, (margin, 56 + 18), radius=28)
    out = img.convert("RGB")
    scale = FINAL_W / W
    return out.resize((FINAL_W, int(H * scale)), Image.LANCZOS)


def build_gif(scheme):
    frames = [compose(scheme, i) for i in range(N)]
    q = [f.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE) for f in frames]
    out = HERE / f"demo-{LANG}-{scheme}.gif"
    q[0].save(out, save_all=True, append_images=q[1:], duration=130, loop=0, optimize=True, disposal=1)
    print(f"{out.name}: {out.stat().st_size / 1024:.0f} KB")
    return frames


def social_preview():
    W, H = 1280, 640
    img = Image.new("RGB", (W, H), (20, 23, 30))
    d = ImageDraw.Draw(img)
    # soft accent glow
    glow = Image.new("RGB", (W, H), (20, 23, 30))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-200, 300, 520, 960], fill=(24, 70, 66))
    glow = glow.filter(ImageFilter.GaussianBlur(140))
    img = Image.blend(img, glow, 0.9)
    d = ImageDraw.Draw(img)

    icon = Image.open(HERE / "icon.png").convert("RGBA").resize((132, 132), Image.LANCZOS)
    img.paste(icon, (88, 118), icon)
    d.text((88, 276), "SysMon", font=font(96, "Bold"), fill=(240, 243, 248))
    d.text((92, 392), "Your Mac's vitals, as a game HUD.", font=font(34), fill=(160, 170, 188))
    d.text((92, 446), "CPU · RAM · Disk · Battery — in your menu bar.", font=font(26), fill=(112, 122, 140))
    d.text((92, 560), "github.com/ozkurtomer/sysmon", font=font(26, "Medium"), fill=(126, 224, 196))

    pop = Image.open(FRAMES_DIR / "dark-14.png").convert("RGB")
    s = 560 / pop.height
    pop = pop.resize((int(pop.width * s), 560), Image.LANCZOS)
    canvas = img.convert("RGBA")
    shadow_paste(canvas, pop, (W - pop.width - 96, 40), radius=22)
    canvas.convert("RGB").save(HERE / "social-preview.png")
    print("social-preview.png")


if __name__ == "__main__":
    if LANG == "tr":
        CPU, RAM = "CPU", "RAM"
    for scheme in ("dark", "light"):
        fr = build_gif(scheme)
        if scheme == "dark":
            fr[N // 2 - 1].save(HERE / f"screenshot-{LANG}-dark.png")
        else:
            fr[2].save(HERE / f"screenshot-{LANG}-light.png")
    if LANG == "en":
        social_preview()
