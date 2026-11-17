"""Non-destructive temporary platform layer for the playable Room3 prototype."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent
source = Image.open(root.parent / "plataformas s3.png").convert("RGBA")
output = source.copy()
pedestal = Image.open(root / "pedestal_85_transparent.png").convert("RGBA")

# The original pedestal is baked into the platform layer. Its first provisional
# removal used one broad rectangle (1175..1370), which also cut away the rubble
# at both sides. Clear only the actual pedestal silhouette and preserve those
# irregular ruins. Restore the floor from the same source layer.
output.paste((0, 0, 0, 0), (1195, 618, 1343, 640))
output.paste((0, 0, 0, 0), (1195, 640, 1343, 710))
output.paste((0, 0, 0, 0), (1195, 710, 1343, 715))
floor = source.crop((900, 715, 1048, 742))
output.paste(floor, (1195, 715))
# The 85% pedestal leaves 11 px at each side of the original footprint.
# Reuse the neighboring rubble from the source layer and move only those two
# narrow fragments inward so the ruin meets the smaller pedestal naturally.
left_rubble = source.crop((1168, 650, 1195, 715))
right_rubble = source.crop((1343, 650, 1370, 715))
output.alpha_composite(left_rubble, dest=(1179, 650))
output.alpha_composite(right_rubble, dest=(1332, 650))
output.save(root / "platforms_without_pedestal_corrected.png")

# The approved 85% cutout includes two rubble fragments clipped by the source
# crop edges. The room layer already supplies those ruins at full resolution,
# so remove only the clipped edge fragments while retaining the pedestal body,
# dimensions, anchor and all central pixels.
pedestal_alpha = pedestal.getchannel("A")
pedestal_alpha.paste(0, (0, 45, 12, 93))
pedestal_alpha.paste(0, (114, 45, 126, 93))
pedestal.putalpha(pedestal_alpha)
pedestal.save(root / "pedestal_85_edge_corrected.png")
