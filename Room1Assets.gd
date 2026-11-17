@tool
extends Node

const RUN_SHEET: String = "res://assets/sprites/sprites movimiento/running.png"
const RUN_COLUMNS: int = 12
const RUN_FPS: float = 15.0
const BACKGROUND_TEXTURE: String = "res://assets/tiles/fondo y plataforma/fondo.png"
const PRESENT_TEXTURE: String = "res://assets/tiles/fondo y plataforma/e49ed822-055e-4f67-8efd-c16c4ffed794.png"
const PAST_TEXTURE: String = "res://assets/tiles/fondo y plataforma/plataforma.png"


func _ready() -> void:
	var room: Node2D = get_parent() as Node2D
	if room == null:
		push_error("C.O.R.E.-9: El configurador de assets perdio su sala. Una proeza cartografica.")
		return
	_setup_background(room)
	_setup_tilemaps(room)
	_setup_player(room)
	if not Engine.is_editor_hint():
		print("C.O.R.E.-9: Assets integrados. La ruina ahora finge tener presupuesto visual.")


func _setup_background(room: Node2D) -> void:
	var background: Sprite2D = room.get_node_or_null("Background") as Sprite2D
	if background != null and background.texture != null:
		return
	if background == null:
		background = Sprite2D.new()
		background.name = "Background"
		room.add_child(background)
		room.move_child(background, 0)
	background.texture = load(BACKGROUND_TEXTURE) as Texture2D


func _setup_tilemaps(room: Node2D) -> void:
	var present: TileMapLayer = room.get_node("TileMapLayer_Present") as TileMapLayer
	var past: TileMapLayer = room.get_node("TileMapLayer_Past") as TileMapLayer
	if present.tile_set != null and past.tile_set != null and not present.get_used_cells().is_empty():
		return
	present.tile_set = _create_platform_tileset(PRESENT_TEXTURE)
	past.tile_set = _create_platform_tileset(PAST_TEXTURE)
	present.clear()
	past.clear()
	present.set_cell(Vector2i.ZERO, 0, Vector2i.ZERO)
	past.set_cell(Vector2i.ZERO, 0, Vector2i.ZERO)


func _create_platform_tileset(texture_path: String) -> TileSet:
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(1024, 572)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = load(texture_path) as Texture2D
	source.texture_region_size = Vector2i(1024, 572)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)
	return tile_set


func _setup_player(room: Node2D) -> void:
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	var old_sprite: Sprite2D = player.get_node_or_null("Sprite2D") as Sprite2D
	if old_sprite != null:
		old_sprite.queue_free()
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		player.add_child(sprite)
	if sprite.sprite_frames == null:
		sprite.sprite_frames = _create_player_frames()


func _create_player_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	var run_regions: Array[Rect2] = _frame_regions(RUN_SHEET)
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 1.0)
	frames.set_animation_loop(&"idle", false)
	frames.add_frame(&"idle", _atlas_frame(RUN_SHEET, run_regions[0]))
	frames.add_animation(&"running")
	frames.set_animation_speed(&"running", RUN_FPS)
	frames.set_animation_loop(&"running", true)
	for region: Rect2 in run_regions:
		frames.add_frame(&"running", _atlas_frame(RUN_SHEET, region))
	frames.add_animation(&"jump")
	frames.set_animation_speed(&"jump", 1.0)
	frames.set_animation_loop(&"jump", false)
	frames.add_frame(&"jump", _atlas_frame(RUN_SHEET, run_regions[0]))
	return frames


func _frame_regions(texture_path: String) -> Array[Rect2]:
	var texture: Texture2D = load(texture_path) as Texture2D
	var frame_width: float = float(texture.get_width()) / float(RUN_COLUMNS)
	var regions: Array[Rect2] = []
	for index: int in RUN_COLUMNS:
		regions.append(Rect2(index * frame_width, 0.0, frame_width, float(texture.get_height())))
	return regions


func _atlas_frame(texture_path: String, region: Rect2) -> AtlasTexture:
	var frame: AtlasTexture = AtlasTexture.new()
	frame.atlas = load(texture_path) as Texture2D
	frame.region = region
	frame.filter_clip = true
	return frame
