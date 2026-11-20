#!/usr/bin/env python3
"""Generates assets/icon.png (1024px) and assets/AppIcon.icns — segmented HUD bars on a dark squircle.

Requires Pillow (pip install pillow) and macOS `iconutil`.
"""
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).parent
N = 1024
SS = 2  # supersample

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def build():
    S = N * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # squircle-ish background with vertical gradient
    bg = Image.new("RGBA", (S, S))
    px = ImageDraw.Draw(bg)
    top, bot = (38, 44, 58), (18, 21, 29)
    for y in range(S):
        px.line([(0, y), (S, y)], fill=lerp(top, bot, y / S) + (255,))
    mask = Image.new("L", (S, S), 0)
    inset = int(S * 0.04)
    ImageDraw.Draw(mask).rounded_rectangle([inset, inset, S - inset, S - inset], radius=int(S * 0.225), fill=255)
    img.paste(bg, (0, 0), mask)

    d = ImageDraw.Draw(img)
    # three segmented gauges (CPU / RAM / Disk)
    cols = [(7, "cpu"), (5, "ram"), (3, "disk")]
    total_seg = 8
    seg_w, seg_h = int(S * 0.16), int(S * 0.062)
    gap_x, gap_y = int(S * 0.045), int(S * 0.02)
    width = 3 * seg_w + 2 * gap_x
    x0 = (S - width) // 2
    base = int(S * 0.80)
    mint, teal = (126, 224, 196), (60, 184, 170)
    for ci, (filled, _) in enumerate(cols):
        x = x0 + ci * (seg_w + gap_x)
        for si in range(total_seg):
            y = base - (si + 1) * seg_h - si * gap_y
            if si < filled:
                color = lerp(teal, mint, si / (total_seg - 1))
                if si >= 7:
                    color = (255, 120, 110)
                fill = color + (255,)
            else:
                fill = (52, 59, 74, 255)   # opaque "empty" segment
            d.rounded_rectangle([x, y, x + seg_w, y + seg_h], radius=int(seg_h * 0.3), fill=fill)

    return img.resize((N, N), Image.LANCZOS)

if __name__ == "__main__":
    icon = build()
    icon.save(HERE / "icon.png")
    with tempfile.TemporaryDirectory() as tmp:
        iconset = Path(tmp) / "AppIcon.iconset"
        iconset.mkdir()
        for size in (16, 32, 128, 256, 512):
            icon.resize((size, size), Image.LANCZOS).save(iconset / f"icon_{size}x{size}.png")
            icon.resize((size * 2, size * 2), Image.LANCZOS).save(iconset / f"icon_{size}x{size}@2x.png")
        subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(HERE / "AppIcon.icns")], check=True)
    print("wrote icon.png and AppIcon.icns")
