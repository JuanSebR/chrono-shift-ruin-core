"""Extract the two ready poses and six recharge poses from the source sheets."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent
source = root.parents[2] / "Barras"
with Image.open(source / "skill.png") as sheet:
    for name, left in [("present", 0), ("past", 526)]:
        icon = sheet.convert("RGBA").crop((left, 78, left + 526, 606))
        # Only the background connected to a corner is keyed out.
        for point in [(0, 0), (525, 0), (0, 527), (525, 527)]:
            ImageDraw.floodfill(icon, point, (0, 0, 0, 0), thresh=65)
        icon.save(root / f"ready_{name}.png")
with Image.open(source / "skill recharging.png") as sheet:
    atlas = Image.new("RGBA", (6 * 384, 384))
    for i in range(6):
        pose = sheet.convert("RGBA").crop((i * 362, 153, (i + 1) * 362, 537))
        atlas.paste(pose, (i * 384 + 11, 0))
    atlas.save(root / "recharge_atlas.png")
