"""Generate the visual layers used by Room4 without editing source art."""
from prepare_room4 import OUT, SIZE, NEAREST, load, shared_past, hashes
from PIL import Image

before = hashes()
assert len(before) == 19
red = load("plataformas v2 s4")
for box in [(204, 200, 255, 220), (475, 170, 540, 191)]:
    red.paste((0, 0, 0, 0), box)
for dimension, decor in [("Present", red), ("Past", shared_past(red))]:
    background = load("fondo Present s4" if dimension == "Present" else "fondo past s4")
    width = round(background.width * SIZE[1] / background.height)
    background = background.resize((width, SIZE[1]), NEAREST)
    world = Image.new("RGBA", SIZE)
    world.paste(background, (0, 0))
    if width < SIZE[0]:
        world.paste(background.crop((width - 1, 0, width, SIZE[1])), (width, 0))
    world.alpha_composite(decor.resize(SIZE, NEAREST))
    world.save(OUT / f"room4_{dimension.lower()}_background.png")
    for state in ("Solid", "TransLucid"):
        layer = load(f"plataformas_{dimension}{state}")
        if dimension == "Present":
            box = (392, 209, 438, 234)
            piece = layer.crop(box)
            layer.paste((0, 0, 0, 0), box)
            layer.paste(piece, (392, 203))
        layer.save(OUT / f"room4_{dimension.lower()}_{state.lower()}.png")
assert before == hashes()
for name, digest in sorted(before.items()):
    print(digest, name)
