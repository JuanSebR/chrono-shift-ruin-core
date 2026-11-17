extends RefCounted
## Atlas regions only: original PNGs are never rewritten.

const DIRECTORY: String = "res://assets/Final/"
const CHARACTER_STARTS: Array[int] = [0,272,543,815,1086,1358,1629,1901]

static func crop(file: String, region: Rect2) -> AtlasTexture:
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = load(DIRECTORY+file) as Texture2D
	texture.region = region
	return texture

static func character() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle",8.0)
	frames.set_animation_loop(&"idle",true)
	for start: int in CHARACTER_STARTS:
		var width: int = mini(272,2172-start)
		var texture: AtlasTexture = crop("personaje End.png",Rect2(start,140,width,430))
		texture.margin = Rect2(0,0,272-width,0)
		frames.add_frame(&"idle",texture)
	return frames
