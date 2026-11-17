extends SceneTree
const OUTPUT: String = "res://assets/animations/core9_running_v2_frames.tres"
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/fundamental_manifest.json"))
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for name: String in manifest:
		var data: Dictionary = manifest[name]
		frames.add_animation(name)
		frames.set_animation_speed(name,float(data.fps))
		frames.set_animation_loop(name,bool(data.loop))
		for item: Dictionary in data.frames:
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = load("res://assets/sprites/sprites movimiento/" + str(item.source)) as Texture2D
			assert(atlas.atlas != null)
			atlas.region = Rect2(item.region[0],item.region[1],item.region[2],item.region[3])
			atlas.margin = Rect2(item.destination[0],item.destination[1],181-atlas.region.size.x,724-atlas.region.size.y)
			atlas.filter_clip = true
			frames.add_frame(name,atlas,float(item.duration))
	assert(ResourceSaver.save(frames,OUTPUT) == OK)
	print("PASS: SpriteFrames fundamental construido")
	quit()
