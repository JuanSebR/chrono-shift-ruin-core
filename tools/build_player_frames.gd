extends SceneTree

const RUN_SHEET: String = "res://assets/sprites/sprites movimiento/running.png"
const RUN_COLUMNS: int = 12
const RUN_FPS: float = 15.0
const OUTPUT_PATH: String = "res://player_frames.tres"


func _init() -> void:
	var texture: Texture2D = load(RUN_SHEET) as Texture2D
	if texture == null:
		push_error("C.O.R.E.-9: No se encontro la hoja de carrera. El movimiento sigue siendo una teoria.")
		quit(1)
		return
	if texture.get_width() % RUN_COLUMNS != 0:
		push_error("C.O.R.E.-9: La hoja no se divide en %d columnas exactas. Magia de píxeles defectuosa." % RUN_COLUMNS)
		quit(1)
		return

	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	var run_regions: Array[Rect2] = _frame_regions(texture)

	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 1.0)
	frames.set_animation_loop(&"idle", false)
	frames.add_frame(&"idle", _atlas_frame(texture, run_regions[0]))

	frames.add_animation(&"running")
	frames.set_animation_speed(&"running", RUN_FPS)
	frames.set_animation_loop(&"running", true)
	for region: Rect2 in run_regions:
		frames.add_frame(&"running", _atlas_frame(texture, region))

	frames.add_animation(&"jump")
	frames.set_animation_speed(&"jump", 1.0)
	frames.set_animation_loop(&"jump", false)
	frames.add_frame(&"jump", _atlas_frame(texture, run_regions[0]))

	var error: Error = ResourceSaver.save(frames, OUTPUT_PATH)
	if error != OK:
		push_error("C.O.R.E.-9: No se pudieron guardar las animaciones. El caos persiste.")
		quit(1)
		return
	print("C.O.R.E.-9: Animacion running guardada con %d cuadros a %.0f FPS. La elegancia ahora es opcional." % [RUN_COLUMNS, RUN_FPS])
	quit()


func _frame_regions(texture: Texture2D) -> Array[Rect2]:
	var frame_width: float = float(texture.get_width()) / float(RUN_COLUMNS)
	var regions: Array[Rect2] = []
	for index: int in RUN_COLUMNS:
		regions.append(Rect2(index * frame_width, 0.0, frame_width, float(texture.get_height())))
	return regions


func _atlas_frame(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var frame: AtlasTexture = AtlasTexture.new()
	frame.atlas = texture
	frame.region = region
	frame.filter_clip = true
	return frame
