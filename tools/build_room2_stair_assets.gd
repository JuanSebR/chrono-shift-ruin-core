extends SceneTree

const SOURCE_PATH: String = "res://assets/tiles/sala 2.1/plataformas s2.1.png"
const OUTPUT_DIR: String = "res://assets/tiles/sala 2.1/derived/"
const REGIONS: Array[Rect2i] = [
	Rect2i(1360, 205, 80, 32),
	Rect2i(1280, 205, 80, 32),
	Rect2i(1220, 205, 80, 32),
	Rect2i(1210, 325, 85, 55),
	Rect2i(1210, 325, 85, 55),
	Rect2i(1217, 205, 90, 45),
	Rect2i(1210, 325, 85, 55),
	Rect2i(1220, 205, 95, 45),
	Rect2i(1360, 205, 90, 45),
]
const FLIP_X: Array[bool] = [false, false, false, false, true, false, false, true, false]


func _initialize() -> void:
	var source_texture: Texture2D = load(SOURCE_PATH) as Texture2D
	var source: Image = source_texture.get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for i: int in range(REGIONS.size()):
		var region: Rect2i = REGIONS[i]
		var output: Image = Image.create(region.size.x, region.size.y, false, Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		output.blit_rect(source, region, Vector2i.ZERO)
		if FLIP_X[i]:
			output.flip_x()
		var path: String = OUTPUT_DIR + "room2_stair_p%d.png" % (i + 1)
		var error: Error = output.save_png(ProjectSettings.globalize_path(path))
		print(path, " region=", region, " save=", error)
	quit()
