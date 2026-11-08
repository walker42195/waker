#!/usr/bin/env python3
"""Skapar assets/waker.png (512×512) av neontemat: vågutsnitt + lysande väckarklocka."""
import pathlib
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
S = 512
src = Image.open(ROOT / "assets/themes/neon.jpg").convert("RGB")
h = src.height
crop = src.crop((int(src.width * 0.30), int(h * 0.18), int(src.width * 0.30) + int(h * 0.64), int(h * 0.82)))
bg = crop.resize((S, S), Image.LANCZOS)

glyph = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(glyph)
white = (255, 246, 255, 255)
cx, cy, r = S // 2, int(S * 0.54), int(S * 0.27)
d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=white, width=24)
d.line([cx, cy, cx, cy - int(r * 0.62)], fill=white, width=24)
d.line([cx, cy, cx + int(r * 0.48), cy + int(r * 0.30)], fill=white, width=24)
d.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=white)
# klockor
bell = (255, 140, 225, 255)
R = r + 46
d.arc([cx - R, cy - R, cx + R, cy + R], 203, 247, fill=bell, width=34)
d.arc([cx - R, cy - R, cx + R, cy + R], 293, 337, fill=bell, width=34)
d.line([cx - int(r * 0.75), cy + int(r * 0.85), cx - int(r * 1.0), cy + int(r * 1.15)], fill=white, width=22)
d.line([cx + int(r * 0.75), cy + int(r * 0.85), cx + int(r * 1.0), cy + int(r * 1.15)], fill=white, width=22)

glow = glyph.filter(ImageFilter.GaussianBlur(18))
out = bg.convert("RGBA")
out.alpha_composite(Image.new("RGBA", (S, S), (10, 8, 40, 70)))
out.alpha_composite(glow)
out.alpha_composite(glow)
out.alpha_composite(glyph)

mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.22), fill=255)
final = Image.new("RGBA", (S, S), (0, 0, 0, 0))
final.paste(out, (0, 0), mask)
final.save(ROOT / "assets/waker.png")
print(ROOT / "assets/waker.png")
