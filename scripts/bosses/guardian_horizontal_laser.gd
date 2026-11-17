extends Node2D

const DIRECTORY: String = "res://assets/sprites/jefe/derived/atlases/"
const WARNING_TIME: float = 0.75
const GROW_TIME: float = 0.6
const ACTIVE_TIME: float = 0.5
const FINISH_TIME: float = 0.6
const WIDTH_SCALE: float = 1.0
const GROW_SCALE: float = 1.0/6.0
const LEVELS: Array[float] = [460.0,530.0,600.0]
var boss: Node2D
var vertical: Node2D
var hint: Node
var enabled: bool = false
var cycle_id: int = -1
var last_burst: int = -1
var phase: StringName = &"off"
var elapsed: float = 0.0
var lane_y: float = 600.0
var frame: int = 0
var front: float = 1280.0
var textures: Dictionary = {}
var damaged: Array[int] = []
var damage_events: int = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boss = get_parent() as Node2D
	vertical = boss.get_node("VerticalBurst")
	top_level = true
	global_position = Vector2.ZERO
	process_physics_priority = 11
	for name: String in ["beam_start","beam_hold","beam_finish"]:
		textures[name] = load(DIRECTORY+name+"_atlas.png")
	hint = load("res://scenes/ui/TutorialHints.tscn").instantiate()
	add_child(hint)
	boss.attack_slot_ready.connect(_on_slot)
	boss.offensive_attacks_cancelled.connect(_cancel)
	hide()

func _on_slot(kind: StringName, id: int) -> void:
	if kind == &"horizontal_laser" and id != cycle_id and id == boss.cycle_id and boss.attack_slot_available(kind):
		enabled = true
		cycle_id = id
		last_burst = -1

func _cancel(_id: int = -1) -> void:
	enabled = false
	phase = &"off"
	hide()
	hint.call("hide_hint")
	queue_redraw()

func _phase(value: StringName) -> void:
	phase = value
	elapsed = 0.0
	frame = 0
	visible = value != &"off"
	if value == &"warning":
		hint.call("show_hint","horizontal_warning","BARRIDA HORIZONTAL — cambia de altura. Qué concepto.",Vector2(640,170))
	else:
		hint.call("hide_hint")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if cycle_id != boss.cycle_id or not boss.attack_slot_available(&"horizontal_laser"):
		_cancel()
		return
	if phase == &"off":
		# Use only the vertical's existing downtime; never change its schedule.
		if vertical.phase == &"active" and vertical.burst_index != last_burst:
			last_burst = vertical.burst_index
			lane_y = LEVELS[0]
			for y: float in LEVELS:
				if absf(boss.cycle_player.position.y-y) < absf(boss.cycle_player.position.y-lane_y):
					lane_y = y
			damaged.clear()
			_phase(&"warning")
		return
	elapsed += delta
	match phase:
		&"warning":
			if elapsed+.00001 >= WARNING_TIME:
				_phase(&"grow")
		&"grow":
			frame = mini(5,int(elapsed/0.1))
			if elapsed+.00001 >= GROW_TIME:
				front = 1280.0
				_phase(&"active")
		&"active":
			front = 1280.0*(1.0-clampf(elapsed/ACTIVE_TIME,0,1))
			if elapsed+.00001 >= ACTIVE_TIME:
				front = 0.0
				_phase(&"finish")
		&"finish":
			frame = mini(5,int(elapsed/0.1))
			if elapsed+.00001 >= FINISH_TIME:
				_phase(&"off")
	queue_redraw()
	if is_dangerous() and front < 1280.0:
		_damage()

func danger_height() -> float:
	if phase == &"active":
		return 32.0*WIDTH_SCALE
	if phase == &"finish":
		return [32.0,20.0,8.0,3.0,1.0,0.0][frame]*WIDTH_SCALE
	return 0.0

func is_dangerous() -> bool:
	return enabled and danger_height() >= 6.0 and vertical.danger_bounds().y < 6

func _damage() -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(maxf(1,1280-front),danger_height())
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0,Vector2((1280+front)*.5,lane_y))
	query.collision_mask = 2
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var body: Node = hit["collider"]
		if body.is_in_group("core9_player") and not damaged.has(body.get_instance_id()):
			var before: int = body.health
			body.take_damage(1)
			if body.health < before:
				damaged.append(body.get_instance_id())
				damage_events += 1

func _draw() -> void:
	if phase == &"off":
		return
	var x: float = front if phase == &"active" else 0.0
	while x < 1280.0:
		var width: float = minf(64.0*GROW_SCALE if phase == &"grow" else 64.0*WIDTH_SCALE,1280.0-x)
		if phase == &"warning":
			draw_texture_rect_region(textures["beam_hold"],Rect2(x,lane_y-2,width,4),Rect2(0,30,width,4))
		elif phase == &"grow":
			draw_texture_rect_region(textures["beam_start"],Rect2(x,lane_y-96.0*GROW_SCALE,width,192.0*GROW_SCALE),Rect2(frame*384+160,0,width/GROW_SCALE,192))
		else:
			var name: String = "beam_hold" if phase == &"active" else "beam_finish"
			var sx: float = 0 if phase == &"active" else frame*64
			draw_texture_rect_region(textures[name],Rect2(x,lane_y-32.0*WIDTH_SCALE,width,64.0*WIDTH_SCALE),Rect2(sx,0,width/WIDTH_SCALE,64))
		x += width

func _exit_tree() -> void:
	if is_instance_valid(boss):
		boss.attack_slot_ready.disconnect(_on_slot)
		boss.offensive_attacks_cancelled.disconnect(_cancel)
