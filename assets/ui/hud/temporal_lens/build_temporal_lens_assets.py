"""Build non-destructive HUD derivatives from the approved temporal lens sheet."""
from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[2] / "Barras" / "skill.png"
NEUTRAL_BOUNDS = (1055, 0, 1579, 724)


def is_baked_grid(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    return min(red, green, blue) >= 235 and max(red, green, blue) - min(red, green, blue) <= 14


sheet = Image.open(SOURCE).convert("RGBA")
neutral = sheet.crop(NEUTRAL_BOUNDS)

# Remove only near-white pixels connected to the cell boundary. This strips the
# baked checkerboard while preserving enclosed highlights on the device.
pixels = neutral.load()
visited: set[tuple[int, int]] = set()
queue: deque[tuple[int, int]] = deque()
for x in range(neutral.width):
    queue.append((x, 0))
    queue.append((x, neutral.height - 1))
for y in range(neutral.height):
    queue.append((0, y))
    queue.append((neutral.width - 1, y))

while queue:
    x, y = queue.popleft()
    if (x, y) in visited or not (0 <= x < neutral.width and 0 <= y < neutral.height):
        continue
    if not is_baked_grid(pixels[x, y]):
        continue
    visited.add((x, y))
    red, green, blue, _alpha = pixels[x, y]
    pixels[x, y] = (red, green, blue, 0)
    queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))

# The activation frame begins immediately after the neutral frame and one cyan
# ray crosses their boundary. The neutral device itself contains no cyan state
# lighting, so strip only those saturated cyan pixels from this cell.
for y in range(neutral.height):
    for x in range(neutral.width):
        red, green, blue, alpha = pixels[x, y]
        if alpha > 0 and blue > 150 and green > 110 and red < 100 and blue + green > red * 3:
            pixels[x, y] = (red, green, blue, 0)

alpha_box = neutral.getchannel("A").getbbox()
if alpha_box is None:
    raise RuntimeError("Neutral temporal lens frame became empty")
padding = 6
isolated = neutral.crop(alpha_box)
result = Image.new("RGBA", (isolated.width + padding * 2, isolated.height + padding * 2))
result.alpha_composite(isolated, dest=(padding, padding))
result.save(ROOT / "temporal_lens_owned_neutral.png")
