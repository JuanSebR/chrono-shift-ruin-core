"""Extract the five source poses without changing the original sheet."""
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / "Barras" / "skill invulneravity.png"
CENTERS = (217, 651, 1086, 1521, 1955)

with Image.open(SOURCE) as sheet:
    for index, center_x in enumerate(CENTERS):
        # Each 420 px square is centered on its chassis. Wider crops include
        # rays from adjacent poses because the original effects overlap.
        frame = sheet.convert("RGBA").crop((center_x - 210, 152, center_x + 210, 572))
        pixels = frame.load()
        for y in range(frame.height):
            for x in range(frame.width):
                red, green, blue, _alpha = pixels[x, y]
                neutral = max(red, green, blue) - min(red, green, blue) <= 13
                if neutral and min(red, green, blue) >= 220:
                    # The bright core is useful light; the near-white pixels
                    # around it are the checkerboard baked into the PNG.
                    if (x - 210) ** 2 + (y - 210) ** 2 > 78 ** 2:
                        pixels[x, y] = (red, green, blue, 0)
        scaled = frame.resize((526, 526), Image.Resampling.NEAREST)
        output = Image.new("RGBA", (526, 528))
        output.alpha_composite(scaled, (0, 1))
        output.save(ROOT / f"protection_{index:02d}.png")
