extends SceneTree

func _init() -> void:
	var frames: SpriteFrames = (load("res://assets/animations/core9_running_v2_frames.tres") as SpriteFrames).duplicate(true) as SpriteFrames
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/player_presentation_manifest.json"))
	DirAccess.make_dir_recursive_absolute("res://assets/animations/player_actions")
	for name: String in manifest:
		var spec: Dictionary = manifest[name]
		frames.add_animation(name)
		frames.set_animation_speed(name, spec["fps"])
		frames.set_animation_loop(name, false)
		if name == "attack" and spec.has("source_directory"):
			for entry: Dictionary in spec["frames"]:
				var texture_path: String = "res://assets/sprites/sprites movimiento/" + str(spec["source_directory"]) + "/" + str(entry["source"])
				var original: Texture2D = load(texture_path) as Texture2D
				assert(original != null)
				var image: Image = original.get_image()
				image.resize(int(spec["resize"][0]), int(spec["resize"][1]), Image.INTERPOLATE_NEAREST)
				var resized: ImageTexture = ImageTexture.create_from_image(image)
				var derived_path: String = "res://assets/animations/attack12/frame_%02d.res" % int(entry["source_frame"])
				DirAccess.make_dir_recursive_absolute("res://assets/animations/attack12")
				assert(ResourceSaver.save(resized, derived_path) == OK)
				resized.take_over_path(derived_path)
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = resized
				atlas.region = Rect2(0, 0, image.get_width(), image.get_height())
				atlas.margin = Rect2(Vector2(spec["destination"][0], spec["destination"][1]), Vector2(spec["canvas"][0] - image.get_width(), spec["canvas"][1] - image.get_height()))
				atlas.filter_clip = true
				frames.add_frame(name, atlas, float(entry["duration"]))
			continue
		var source: Texture2D = load("res://assets/sprites/sprites movimiento/" + spec["source"]) as Texture2D
		for entry: Dictionary in spec["frames"]:
			var values: Array = entry["region"]
			var region: Rect2 = Rect2(values[0], values[1], values[2], values[3])
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = source
			atlas.region = region
			if entry.has("exclude_rects"):
				# Remove only the neighboring pose's arc in a derived texture, never the source PNG.
				var extracted: Image = source.get_image().get_region(Rect2i(region))
				for rect: Array in entry["exclude_rects"]:
					extracted.fill_rect(Rect2i(rect[0], rect[1], rect[2], rect[3]), Color.TRANSPARENT)
				var derived: ImageTexture = ImageTexture.create_from_image(extracted)
				var path: String = "res://assets/animations/player_actions/%s_%02d.res" % [name, int(entry["source_frame"])]
				assert(ResourceSaver.save(derived, path) == OK)
				atlas.atlas = derived
				atlas.region = Rect2(Vector2.ZERO, region.size)
			var canvas: Vector2 = Vector2(spec["canvas"][0], spec["canvas"][1])
			var destination: Vector2 = Vector2(canvas.x / 2.0 - (float(entry["anchor_x"]) - region.position.x), float(spec["foot_y"]) - (float(entry["support_y"]) - region.position.y))
			atlas.margin = Rect2(destination, canvas - region.size)
			atlas.filter_clip = true
			frames.add_frame(name, atlas, entry["duration"])
	assert(ResourceSaver.save(frames, "res://assets/animations/core9_presentation_attack12.tres") == OK)
	print("PASS: presentation resource built; source resources unchanged")
	quit()
