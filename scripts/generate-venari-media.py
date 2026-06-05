#!/usr/bin/env python3
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter


OUT = Path(__file__).resolve().parents[1] / "src/versions/tbc-anniversary-cn/addons/Venari/Media"


GOLD = (142, 105, 42, 255)
GOLD_HI = (198, 165, 82, 255)
GOLD_DARK = (58, 43, 21, 255)
IRON = (13, 13, 12, 245)
IRON_HI = (42, 39, 31, 245)
LEATHER = (20, 13, 7, 236)
VOID = (1, 1, 1, 235)
GREEN = (92, 190, 45, 255)


def transparent(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def rounded(draw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def glow(size, color, inner=0.35, outer=0.9):
    img = transparent((size, size))
    d = ImageDraw.Draw(img)
    cx = cy = size / 2
    max_r = size * outer / 2
    min_r = size * inner / 2
    steps = 42
    for i in range(steps, 0, -1):
        t = i / steps
        r = min_r + (max_r - min_r) * t
        a = int(color[3] * (1 - t) ** 1.8)
        c = (*color[:3], a)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=c, width=max(1, size // 42))
    return img


def metal_panel(size, radius, inset=8):
    img = transparent(size)
    d = ImageDraw.Draw(img)
    w, h = size
    rounded(d, (1, 1, w - 2, h - 2), radius, fill=(0, 0, 0, 150), outline=GOLD_DARK, width=3)
    rounded(d, (5, 5, w - 6, h - 6), max(2, radius - 3), fill=IRON, outline=GOLD, width=3)
    rounded(d, (9, 9, w - 10, h - 10), max(2, radius - 7), fill=LEATHER, outline=GOLD_HI, width=1)
    rounded(d, (inset + 4, inset + 4, w - inset - 5, h - inset - 5), max(2, radius - inset), fill=VOID, outline=GOLD_DARK, width=2)
    return img


def add_corner_caps(img, inset=7, length=18):
    d = ImageDraw.Draw(img)
    w, h = img.size
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        x0 = inset if sx > 0 else w - inset
        y0 = inset if sy > 0 else h - inset
        d.line((x0, y0, x0 + sx * length, y0), fill=GOLD_HI, width=2)
        d.line((x0, y0, x0, y0 + sy * length), fill=GOLD_HI, width=2)
        d.line((x0 + sx, y0 + sy, x0 + sx * (length - 4), y0 + sy), fill=GOLD_DARK, width=1)
        d.line((x0 + sx, y0 + sy, x0 + sx, y0 + sy * (length - 4)), fill=GOLD_DARK, width=1)


def square_button():
    img = metal_panel((86, 86), 10, 11)
    d = ImageDraw.Draw(img)
    rounded(d, (14, 14, 72, 72), 4, fill=(2, 2, 2, 240), outline=GOLD_HI, width=2)
    rounded(d, (19, 19, 67, 67), 3, fill=(0, 0, 0, 255), outline=(32, 27, 18, 255), width=1)
    add_corner_caps(img, 7, 15)
    return img


def resource_panel():
    img = metal_panel((260, 70), 12, 12)
    d = ImageDraw.Draw(img)
    for x0, x1 in ((23, 120), (140, 237)):
        rounded(d, (x0, 16, x1, 54), 6, fill=(2, 2, 2, 245), outline=GOLD, width=2)
        rounded(d, (x0 + 9, 21, x0 + 46, 49), 4, fill=(0, 0, 0, 255), outline=GOLD_DARK, width=1)
    d.line((130, 9, 130, 61), fill=GOLD_DARK, width=2)
    d.line((131, 12, 131, 58), fill=(44, 32, 17, 255), width=1)
    add_corner_caps(img, 9, 18)
    return img


def aspect_panel():
    img = metal_panel((116, 190), 14, 11)
    d = ImageDraw.Draw(img)
    d.ellipse((25, 25, 91, 91), fill=(2, 2, 2, 245), outline=GOLD_HI, width=3)
    d.ellipse((30, 30, 86, 86), outline=GOLD_DARK, width=2)
    rounded(d, (33, 116, 83, 166), 5, fill=(2, 2, 2, 245), outline=GOLD, width=2)
    add_corner_caps(img, 9, 18)
    return img


def trap_panel():
    img = metal_panel((190, 190), 13, 12)
    d = ImageDraw.Draw(img)
    for x in (28, 101):
        for y in (28, 101):
            rounded(d, (x, y, x + 61, y + 61), 5, fill=(2, 2, 2, 245), outline=GOLD_HI, width=2)
            rounded(d, (x + 6, y + 6, x + 55, y + 55), 3, fill=(0, 0, 0, 255), outline=GOLD_DARK, width=1)
    d.line((95, 18, 95, 172), fill=GOLD_DARK, width=3)
    d.line((18, 95, 172, 95), fill=GOLD_DARK, width=3)
    add_corner_caps(img, 9, 20)
    return img


def tool_panel():
    img = metal_panel((410, 86), 12, 12)
    d = ImageDraw.Draw(img)
    for x in (24, 96, 168, 240, 312):
        rounded(d, (x, 16, x + 58, 74), 5, fill=(2, 2, 2, 245), outline=GOLD_HI, width=2)
        rounded(d, (x + 6, 22, x + 52, 68), 3, fill=(0, 0, 0, 255), outline=GOLD_DARK, width=1)
    add_corner_caps(img, 9, 20)
    return img


def orb_ring():
  size = 180
  img = transparent((size, size))
  d = ImageDraw.Draw(img)
  d.ellipse((8, 8, 172, 172), outline=GOLD_DARK, width=5)
  d.ellipse((14, 14, 166, 166), outline=GOLD_HI, width=2)
  d.ellipse((20, 20, 160, 160), outline=IRON_HI, width=5)

  # Broken green status ring: closer to the reference than a bullseye stack.
  cx = cy = size / 2
  outer = 70
  inner = 58
  for index in range(24):
      start = math.radians(index * 15 - 90)
      end = math.radians(index * 15 + 10 - 90)
      points = [
          (cx + math.cos(start) * outer, cy + math.sin(start) * outer),
          (cx + math.cos(end) * outer, cy + math.sin(end) * outer),
          (cx + math.cos(end) * inner, cy + math.sin(end) * inner),
          (cx + math.cos(start) * inner, cy + math.sin(start) * inner),
      ]
      d.polygon(points, fill=(74, 166, 35, 210))
      d.line((points[0], points[1]), fill=(132, 226, 73, 235), width=1)

  d.ellipse((47, 47, 133, 133), outline=GOLD_DARK, width=3)
  return img.filter(ImageFilter.UnsharpMask(radius=1.0, percent=110, threshold=2))


def dot(active):
    size = 28
    img = transparent((size, size))
    d = ImageDraw.Draw(img)
    d.ellipse((2, 2, 26, 26), fill=(0, 0, 0, 150), outline=GOLD_DARK, width=2)
    if active:
        d.ellipse((6, 6, 22, 22), fill=(141, 255, 91, 245), outline=(224, 255, 172, 255), width=2)
        img = Image.alpha_composite(glow(size, (127, 255, 83, 160), 0.45, 1.0), img)
    else:
        d.ellipse((7, 7, 21, 21), fill=(21, 20, 16, 235), outline=(85, 77, 53, 210), width=1)
    return img


def save(name, img):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name)


def main():
    save("v3-square-button.tga", square_button())
    save("v3-resource-panel.tga", resource_panel())
    save("v3-aspect-panel.tga", aspect_panel())
    save("v3-trap-panel.tga", trap_panel())
    save("v3-tool-panel.tga", tool_panel())
    save("v3-orb-ring.tga", orb_ring())
    save("v3-ring-dot-bg.tga", dot(False))
    save("v3-ring-dot-active.tga", dot(True))


if __name__ == "__main__":
    main()
