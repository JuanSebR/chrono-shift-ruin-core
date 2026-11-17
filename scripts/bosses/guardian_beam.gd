extends Node2D

const ATLAS_DIRECTORY: String = "res://assets/sprites/jefe/derived/atlases/"
const GROW_SCALE: float = 0.20
const HOLD_SCALE: float = 0.9375
const DAMAGE_HEIGHT: float = 24.0

var textures: Dictionary = {}
var phase: StringName = &"off"
var frame: int = 0
var length: float = 900.0
var damage_shape: RectangleShape2D = RectangleShape2D.new()


func _ready() -> void:
	for name: String in ["beam_start", "beam_hold", "beam_finish"]:
		textures[name] = load(ATLAS_DIRECTORY + name + "_atlas.png") as Texture2D
	hide()


func show_phase(next_phase: StringName, next_frame: int, next_length: float) -> void:
	phase = next_phase
	frame = next_frame
	length = next_length
	visible = phase != &"off"
	queue_redraw()


func stop() -> void:
	show_phase(&"off", 0, length)


func damage_players(amount: int) -> void:
	if phase != &"active":
		return
	damage_shape.size = Vector2(length, DAMAGE_HEIGHT)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = damage_shape
	query.transform = global_transform * Transform2D(0.0, Vector2(-length * 0.5, 0.0))
	query.collision_mask = 2
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var body: Node = hit["collider"]
		if body.is_in_group("core9_player"):
			body.call("take_damage", amount)


func _draw() -> void:
	if phase == &"off" or textures.is_empty():
		return
	var growing: bool = phase == &"prepare" or phase == &"grow"
	var scale_factor: float = GROW_SCALE if growing else HOLD_SCALE
	var height: float = 192.0 if growing else 64.0
	var texture_name: String = "beam_start" if growing else ("beam_finish" if phase == &"finish" else "beam_hold")
	var atlas_frame: int = frame if texture_name != "beam_hold" else 0
	var source_x: float = float(atlas_frame * (384 if growing else 64) + (160 if growing else 0))
	var step: float = 64.0 * scale_factor
	var x: float = -length
	while x < -0.001:
		var width: float = minf(step, -x)
		# Equal X/Y scale; crop the last tile rather than stretch it.
		draw_texture_rect_region(textures[texture_name], Rect2(x, -height * scale_factor * 0.5, width, height * scale_factor), Rect2(source_x, 0.0, width / scale_factor, height))
		x += width
