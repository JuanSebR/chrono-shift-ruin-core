"""Reproduce the Phase A comparison boards from the original PNGs."""
from pathlib import Path
from hashlib import sha256
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
SOURCE = OUT.parent
SIZE = (1280, 720)
NEAREST = Image.Resampling.NEAREST
SUPPORTS = [
    (19, 46, 208), (89, 149, 214), (206, 253, 202),
    (287, 359, 231), (394, 436, 211), (477, 538, 172), (568, 620, 142),
]


def load(name):
    with Image.open(SOURCE / (name + ".png")) as source:
        return source.convert("RGBA")


def hashes():
    return {p.name: sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob("*.png")}


def shared_past(red):
    # Preserve the exact visible support tops. The blue background already
    # supplies its own side columns and lower deck.
    layer = Image.new("RGBA", red.size)
    for box in [(19, 207, 47, 226), (286, 230, 360, 251), (567, 141, 620, 174)]:
        layer.paste(red.crop(box), box[:2])
    return layer


def compose(present, adjust=False):
    background = load("fondo Present s4" if present else "fondo past s4")
    width = round(background.width * SIZE[1] / background.height)
    background = background.resize((width, SIZE[1]), NEAREST)
    world = Image.new("RGBA", SIZE)
    world.paste(background, (0, 0))
    if width < SIZE[0]:
        edge = background.crop((width - 1, 0, width, SIZE[1]))
        world.paste(edge.resize((SIZE[0] - width, SIZE[1]), NEAREST), (width, 0))
    red = load("plataformas v2 s4")
    past_solid = load("plataformas_PastSolid")
    assert past_solid.size == red.size == (640, 360)
    # Remove only the two baked copies of the Past steps from the red layer.
    for box in [(204, 200, 255, 220), (475, 170, 540, 191)]:
        red.paste((0, 0, 0, 0), box)
    layers = [
        red if present else shared_past(red),
        load("plataformas_PresentSolid" if present else "plataformas_PresentTransLucid"),
        load("plataformas_PastTransLucid" if present else "plataformas_PastSolid"),
    ]
    if adjust:
        # Raise the right metallic platform by 12 world px. Move its solid
        # and ghost renderings by the same amount in their respective worlds.
        box = (392, 209, 438, 232)
        piece = layers[1].crop(box)
        layers[1].paste((0, 0, 0, 0), box)
        layers[1].paste(piece, (box[0], box[1] - 6))
    for layer in layers:
        world.alpha_composite(layer.resize(SIZE, NEAREST))
    return world


def annotate(world, scale, adjusted=False):
    result = world.copy()
    draw = ImageDraw.Draw(result)
    font = ImageFont.load_default(size=16 if scale == 2 else 11)
    for index, (left, right, top) in enumerate(SUPPORTS, 1):
        if adjusted and index == 5:
            top -= 6
        x, y = left * scale, top * scale
        color = "#ffe389" if index in (2, 5, 6, 7) else "#94f6ff"
        draw.line((x, y, right * scale - 1, y), fill=color, width=2)
        draw.text((x, y - 12), str(index), fill=color, font=font, anchor="ls",
                  stroke_width=1, stroke_fill="black")
    # Player collision silhouette at the entry, always 24 x 40 world pixels.
    x, feet = 32 * scale, 208 * scale
    draw.rectangle((x - 12, feet - 40, x + 11, feet - 1),
                   fill="#173744", outline="#e0fcff")
    return result


def main():
    before = hashes()
    assert len(before) == 19
    for stem in ("Present", "Past"):
        solid = load(f"plataformas_{stem}Solid").getchannel("A")
        ghost = load(f"plataformas_{stem}TransLucid").getchannel("A")
        assert solid.getbbox() == ghost.getbbox()
        assert solid.point(lambda a: 255 if a else 0).tobytes() == ghost.point(lambda a: 255 if a else 0).tobytes()
        assert ghost.getextrema()[1] < 255
        print(stem, solid.getbbox(), "ghost maximum alpha", ghost.getextrema()[1])
    present, past = compose(True), compose(False)
    present.save(OUT / "present_2x.png")
    past.save(OUT / "past_2x.png")
    comparison = Image.new("RGB", (2560, 720))
    comparison.paste(present, (0, 0))
    comparison.paste(past, (1280, 0))
    comparison.save(OUT / "worlds_2x.png")
    board = Image.new("RGB", (1280, 1800), "#15141e")
    board.paste(annotate(load("diseño completo v1 s4"), 1), (0, 0))
    board.paste(annotate(present, 2), (0, 360))
    board.paste(annotate(compose(True, adjust=True), 2, adjusted=True), (0, 1080))
    draw = ImageDraw.Draw(board)
    for y, title in [(8, "1x original"), (368, "2x baseline"), (1088, "2x option: raise support 5 by 12 px")]:
        draw.text((90, y), title, fill="white", stroke_width=2, stroke_fill="black")
    board.save(OUT / "surface_comparison.png")
    assert hashes() == before
    print("19 source PNG hashes unchanged")


if __name__ == "__main__":
    main()
