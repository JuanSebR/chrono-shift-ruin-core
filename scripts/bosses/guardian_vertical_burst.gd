extends Node2D

signal phase_changed(current: StringName)
signal burst_started(targets: Array[float])

const COLUMNS: Array[float] = [300.0,640.0,980.0]
const WARNING_TIME: float = 1.4
const FRAME_TIME: float = 0.10
const ACTIVE_TIME: float = 0.75
const REST_TIME: float = 1.2
const WIDTH_SCALE: float = 2.5
const EXPAND_BOUNDS: Array[Vector2i] = [Vector2i(31,1),Vector2i(31,2),Vector2i(29,6),Vector2i(22,20),Vector2i(18,28),Vector2i(16,32)]
const CONTRACT_BOUNDS: Array[Vector2i] = [Vector2i(16,32),Vector2i(22,20),Vector2i(28,8),Vector2i(30,3),Vector2i(31,1),Vector2i(0,0)]
const DIRECTORY: String = "res://assets/sprites/jefe/"

var boss: Node2D
var hint: Node
var phase: StringName = &"off"
var frame: int = 0
var elapsed: float = 0.0
var enabled: bool = false
var cycle_id: int = -1
var burst_index: int = 0
var columns: Array[float] = []
var textures: Dictionary = {}
var damage_events: int = 0
var phase_trace: Array[StringName] = []
var damaged_ids: Array[int] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boss = get_parent() as Node2D
	top_level = true
	global_position = Vector2.ZERO
	process_physics_priority = 10
	textures = {
		&"warning":load(DIRECTORY+"laser_vertical_fijo_64x360.png"),
		&"expansion":load(DIRECTORY+"laser_vertical_expansion_6_frames_384x360.png"),
		&"active":load(DIRECTORY+"laser_vertical_maximo_64x360.png"),
		&"contraction":load(DIRECTORY+"laser_vertical_contraccion_6_frames_384x360.png"),
	}
	hint = load("res://scenes/ui/TutorialHints.tscn").instantiate()
	add_child(hint)
	boss.attack_slot_ready.connect(_on_slot)
	boss.offensive_attacks_cancelled.connect(_on_cancel)
	visible = false

func _on_slot(kind: StringName, id: int) -> void:
	if kind != &"vertical_burst" or enabled or id != boss.cycle_id or not boss.attack_slot_available(kind):
		return
	cycle_id = id
	burst_index = 0
	enabled = true
	_begin_burst()

func _begin_burst() -> void:
	# No new warning if the complete beam would extend into the return sequence.
	if boss.cycle_elapsed+WARNING_TIME+12.0*FRAME_TIME+ACTIVE_TIME > boss.RETURN_START:
		return
	var player: CharacterBody2D = boss.cycle_player
	if not is_instance_valid(player) or player.health <= 0:
		cancel()
		return
	var nearest: int = 0
	for index: int in range(1,COLUMNS.size()):
		if absf(player.global_position.x-COLUMNS[index]) < absf(player.global_position.x-COLUMNS[nearest]):
			nearest = index
	burst_index += 1
	damaged_ids.clear()
	columns.assign([COLUMNS[nearest]])
	if burst_index % 2 == 0:
		var offset: int = 1 + ((burst_index/2+cycle_id) as int) % 2
		columns.append(COLUMNS[(nearest+offset)%3])
	_set_phase(&"warning")
	burst_started.emit(columns.duplicate())

func _set_phase(value: StringName) -> void:
	phase = value
	elapsed = 0.0
	frame = 0
	visible = phase not in [&"off",&"rest"]
	phase_trace.append(phase)
	if phase == &"warning":
		hint.call("show_hint","vertical_warning","LÁSER VERTICAL — sal de las columnas marcadas.",Vector2(640,130))
	else:
		hint.call("hide_hint")
	phase_changed.emit(phase)
	queue_redraw()

func _on_cancel(_id: int) -> void:
	cancel()

func cancel() -> void:
	enabled = false
	columns.clear()
	_set_phase(&"off")

func danger_bounds() -> Vector2i:
	if phase == &"active":
		return Vector2i(16,32)
	if phase == &"expansion":
		return EXPAND_BOUNDS[frame]
	if phase == &"contraction":
		return CONTRACT_BOUNDS[frame]
	return Vector2i.ZERO

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if not is_instance_valid(boss) or cycle_id != boss.cycle_id or not boss.attack_slot_available(&"vertical_burst"):
		cancel()
		return
	elapsed += delta
	match phase:
		&"warning":
			if elapsed+0.00001 >= WARNING_TIME:
				_set_phase(&"expansion")
		&"expansion",&"contraction":
			frame = mini(5,int((elapsed+0.00001)/FRAME_TIME))
			if elapsed+0.00001 >= 6.0*FRAME_TIME:
				if phase == &"expansion":
					_set_phase(&"active")
				else:
					columns.clear()
					_set_phase(&"rest")
		&"active":
			if elapsed+0.00001 >= ACTIVE_TIME:
				_set_phase(&"contraction")
		&"rest":
			if elapsed+0.00001 >= REST_TIME:
				_begin_burst()
	queue_redraw()
	var bounds: Vector2i = danger_bounds()
	# Only thick luminous beam pixels are dangerous; warning/thin tails are safe.
	if bounds.y >= 6:
		_damage_players(bounds)

func _damage_players(bounds: Vector2i) -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(float(bounds.y)*WIDTH_SCALE,720)
	for x: float in columns.duplicate():
		if not enabled or danger_bounds().y < 6:
			break
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0,Vector2(x+(float(bounds.x)-32.0+float(bounds.y)*.5)*WIDTH_SCALE,360))
		query.collision_mask = 2
		for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
			var player: Node = hit["collider"]
			if player.is_in_group("core9_player") and player.health > 0 and not damaged_ids.has(player.get_instance_id()):
				var before: int = player.health
				player.take_damage(1)
				if player.health < before:
					damage_events += 1
					damaged_ids.append(player.get_instance_id())

func _draw() -> void:
	if not visible or not textures.has(phase):
		return
	var texture: Texture2D = textures[phase]
	var source_x: float = float(frame*64) if phase in [&"expansion",&"contraction"] else 0.0
	for x: float in columns:
		for y: int in [0,360]:
			# Same horizontal nearest scale for every phase and its damage bounds.
			draw_texture_rect_region(texture,Rect2(x-32.0*WIDTH_SCALE,y,64.0*WIDTH_SCALE,360),Rect2(source_x,0,64,360))

func _exit_tree() -> void:
	if is_instance_valid(boss):
		if boss.attack_slot_ready.is_connected(_on_slot):
			boss.attack_slot_ready.disconnect(_on_slot)
		if boss.offensive_attacks_cancelled.is_connected(_on_cancel):
			boss.offensive_attacks_cancelled.disconnect(_on_cancel)
