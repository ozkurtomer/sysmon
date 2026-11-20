#!/usr/bin/env python3
"""Generates assets/demo.gif — an animated illustration of the SysMon menu.

Requires Pillow:  pip install pillow
Usage:            python3 assets/make_demo_gif.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).with_name("demo.gif")
S = 2                      # supersampling for smooth edges
W, H = 560, 430
FRAMES, MS = 48, 110

BG, BAR = (24, 27, 34), (36, 40, 50)
CARD, CARD_EDGE = (40, 45, 56), (58, 64, 78)
TEXT, DIM, HEAD = (226, 230, 238), (136, 144, 160), (166, 174, 190)
ACCENT, SEL = (126, 205, 184), (62, 92, 140)

SANS = "/System/Library/Fonts/SFNS.ttf"
MONO = "/System/Library/Fonts/SFNSMono.ttf"


def font(path, size):
    try:
        return ImageFont.truetype(path, size * S)
    except OSError:
        return ImageFont.load_default()


f_bar, f_item, f_head = font(SANS, 13), font(SANS, 14), font(SANS, 11)
f_mono = font(MONO, 13)

CPU_PROCS = [("WindowServer", 21.4), ("Google Chrome Helper", 14.2), ("Xcode", 9.8), ("Finder", 4.1), ("Spotlight", 2.3)]
RAM_PROCS = [("Google Chrome Helper", 993), ("Xcode", 897), ("Slack", 423), ("Figma", 329), ("Finder", 124)]


def frame(i):
    t = i / FRAMES * 2 * math.pi
    rnd = random.Random(i)
    cpu = 22 + 9 * math.sin(t) + 3 * math.sin(3 * t) + rnd.uniform(-1, 1)
    ram = 72.0 + 0.6 * math.sin(t / 2)

    im = Image.new("RGB", (W * S, H * S), BG)
    d = ImageDraw.Draw(im)
    s = lambda v: int(v * S)

    # menu bar
    d.rectangle([0, 0, s(W), s(30)], fill=BAR)
    d.ellipse([s(18), s(10), s(28), s(20)], fill=(120, 126, 140))
    d.text((s(40), s(8)), "Finder    File    Edit    View", font=f_bar, fill=DIM)

    # status item (highlighted — menu is open)
    label = f"CPU {cpu:.0f}%  RAM {ram:.0f}%"
    tw = d.textlength(label, font=f_bar) / S
    x1 = W - 24
    x0 = x1 - tw - 16
    d.rounded_rectangle([s(x0), s(4), s(x1), s(26)], radius=s(6), fill=SEL)
    d.text((s(x0 + 8), s(8)), label, font=f_bar, fill=TEXT)

    # dropdown card
    cw, ch = 292, 372
    cx1, cy0 = x1, 34
    cx0 = cx1 - cw
    d.rounded_rectangle([s(cx0), s(cy0), s(cx1), s(cy0 + ch)], radius=s(12), fill=CARD, outline=CARD_EDGE, width=S)

    y = cy0 + 14
    px = cx0 + 16

    def line(text, fnt=f_item, fill=TEXT, right=None, dy=24):
        nonlocal y
        d.text((s(px), s(y)), text, font=fnt, fill=fill)
        if right:
            rw = d.textlength(right, font=f_mono) / S
            d.text((s(cx1 - 16 - rw), s(y + 1)), right, font=f_mono, fill=ACCENT)
        y += dy

    def rule():
        nonlocal y
        y += 4
        d.line([s(px), s(y), s(cx1 - 16), s(y)], fill=CARD_EDGE, width=S)
        y += 10

    used = 16 * ram / 100
    line(f"CPU: {cpu:.1f}%")
    line(f"RAM: {used:.1f} GB / 16.0 GB ({ram:.0f}%)", dy=20)
    rule()
    line("EN ÇOK CPU KULLANANLAR", f_head, HEAD, dy=22)
    for k, (n, v) in enumerate(CPU_PROCS):
        jitter = 1 + 0.12 * math.sin(t * (k + 1) + k)
        line(n, right=f"{v * jitter:.1f}%", dy=22)
    rule()
    line("EN ÇOK RAM KULLANANLAR", f_head, HEAD, dy=22)
    for k, (n, v) in enumerate(RAM_PROCS):
        line(n, right=f"{v:.0f} MB", dy=22)

    return im.resize((W, H), Image.LANCZOS)


frames = [frame(i) for i in range(FRAMES)]
pal = frames[0].quantize(colors=64, method=Image.Quantize.MEDIANCUT)
frames = [f.quantize(palette=pal, dither=Image.Dither.NONE) for f in frames]
frames[0].save(OUT, save_all=True, append_images=frames[1:], duration=MS, loop=0, optimize=True, disposal=1)
print(f"wrote {OUT} ({OUT.stat().st_size / 1024:.0f} KB)")
