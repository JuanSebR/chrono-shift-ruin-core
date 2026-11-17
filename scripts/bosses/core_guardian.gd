extends Node2D

signal health_changed(current: int, maximum: int)
signal damage_accepted(amount: int)
signal core_exposure_changed(exposed: bool)
signal state_changed(current: State)
signal defeated
signal attack_slot_ready(kind: StringName, cycle_id: int)
signal offensive_attacks_cancelled(cycle_id: int)

enum State { IDLE, INTRO, EXITING, OFFSCREEN, RETURNING, RETURNED, CORE_OPENING, VULNERABLE, CORE_CLOSING, DEFEATED }
const MANIFEST: String = "res://assets/sprites/jefe/derived/room5_stage_a_manifest.json"
const ATLAS_DIRECTORY: String = "res://assets/sprites/jefe/derived/atlases/"
const OFFENSIVE_SECONDS: float = 45.0
const OVERHEAT_SECONDS: float = 6.0
const OFFSCREEN_OFFSET: Vector2 = Vector2(360,-120)
const RETURN_START: float = 40.0
const LANDING_START: float = 41.0
const LANDING_END: float = 41.5
const OPENING_START: float = 44.25

@export var dimension_manager: Node
var max_health: int = 3
var health: int = 3
var state: State = State.IDLE
var cycle_running: bool = false
var cycle_player: CharacterBody2D
var cycle_id: int = 0
var cycle_elapsed: float = 0.0
var window_elapsed: float = 0.0
var closing_elapsed: float = 0.0
var core_exposed: bool = false
var base_frames: SpriteFrames
var landmarks: Dictionary = {}
var vulnerable_body_bounds: Rect2
var idle_visual: Sprite2D
var cancel_return_elapsed: float = -1.0
var cancel_return_origin: Vector2
# Compatibility for room-level hazard inspection. New drivers are not installed.
var beam_running: bool = false
var arc_running: bool = false

@onready var sprite: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D
@onready var weakpoint: Area2D = $CoreWeakpoint
@onready var core_shape: CollisionShape2D = $CoreWeakpoint/CollisionShape2D
@onready var visual_root: Node2D = $VisualRoot

func _ready() -> void:
	core_shape.shape = core_shape.shape.duplicate()
	landmarks = (JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary)["animations"]
	base_frames = SpriteFrames.new()
	base_frames.remove_animation(&"default")
	for animation: String in ["starting","repose","vulnerable","retorn","exit","retorn_repose","exit_repose","defeated"]:
		base_frames.add_animation(animation)
		base_frames.set_animation_speed(animation,6.0 if animation == "repose" else 8.0)
		base_frames.set_animation_loop(animation,animation == "repose")
		var atlas: Texture2D = load(ATLAS_DIRECTORY+animation+"_atlas.png") as Texture2D
		for record: Dictionary in landmarks[animation]["frames"]:
			var rect: Array = record["atlas_rect"]
			var texture: AtlasTexture = AtlasTexture.new()
			texture.atlas = atlas
			texture.region = Rect2(rect[0],rect[1],rect[2],rect[3])
			base_frames.add_frame(animation,texture)
	# Exclude transparent atlas padding; cover the complete final overheat pose.
	var final_pose: int = base_frames.get_frame_count(&"vulnerable")-1
	var body_image: Image = base_frames.get_frame_texture(&"vulnerable",final_pose).get_image()
	if body_image.is_compressed():
		body_image.decompress()
	vulnerable_body_bounds = Rect2(body_image.get_used_rect())
	sprite.sprite_frames = base_frames
	var still: Image = (load("res://assets/sprites/jefe/quieto_guardian.png") as Texture2D).get_image()
	if still.is_compressed():
		still.decompress()
	still.resize(557,557,Image.INTERPOLATE_NEAREST)
	var canvas: Image = Image.create(640,800,false,Image.FORMAT_RGBA8)
	canvas.blit_rect(still,Rect2i(0,0,557,557),Vector2i(34,180))
	idle_visual = Sprite2D.new()
	idle_visual.texture = ImageTexture.create_from_image(canvas)
	idle_visual.centered = false
	idle_visual.position = sprite.position
	idle_visual.visible = false
	visual_root.add_child(idle_visual)
	sprite.frame_changed.connect(_update_core)
	sprite.animation_finished.connect(_on_animation_finished)
	if is_instance_valid(dimension_manager):
		dimension_manager.dimension_changed.connect(_on_dimension_changed)
	_play(State.IDLE,&"repose")

func _process(_delta: float) -> void:
	var show_still: bool = sprite.animation == &"repose" and health > 0
	idle_visual.flip_h = sprite.flip_h
	idle_visual.visible = show_still
	sprite.visible = not show_still

func _play(next: State, animation: StringName) -> void:
	state = next
	sprite.play(animation)
	sprite.set_frame_and_progress(0,0.0)
	_update_core()
	state_changed.emit(state)

func _update_core() -> void:
	if landmarks.is_empty():
		return
	if state == State.VULNERABLE:
		var pixels: Rect2 = vulnerable_body_bounds
		if sprite.flip_h:
			pixels.position.x = base_frames.get_frame_texture(&"vulnerable",sprite.frame).get_width()-pixels.end.x
		if sprite.flip_v:
			pixels.position.y = base_frames.get_frame_texture(&"vulnerable",sprite.frame).get_height()-pixels.end.y
		var body_transform: Transform2D = global_transform.affine_inverse()*sprite.global_transform
		var body_rect: Rect2 = body_transform*pixels
		weakpoint.position = body_rect.get_center()
		(core_shape.shape as RectangleShape2D).size = body_rect.size
	core_shape.set_deferred("disabled",not can_receive_damage())

func _on_dimension_changed(_present: bool) -> void:
	_update_core()

func _on_animation_finished() -> void:
	if state == State.INTRO:
		_play(State.IDLE,&"repose")

func play_diagnostic(animation: StringName) -> bool:
	if cycle_running or health <= 0 or state != State.IDLE or animation != &"starting":
		return false
	_play(State.INTRO,animation)
	return true

func can_receive_damage() -> bool:
	return cycle_running and state == State.VULNERABLE and core_exposed and health > 0 and visual_root.position == Vector2.ZERO and is_instance_valid(dimension_manager) and int(dimension_manager.get("active_dimension")) == 0

func take_damage(amount: int) -> void:
	if amount <= 0 or not can_receive_damage():
		return
	var accepted: int = mini(amount,health)
	health -= accepted
	health_changed.emit(health,max_health)
	damage_accepted.emit(accepted)
	if health == 0:
		_confirm_defeat()

func start_combat_cycle() -> bool:
	if cycle_running or health <= 0 or state != State.IDLE or not is_instance_valid(dimension_manager):
		return false
	cycle_player = dimension_manager.get("controlled_player") as CharacterBody2D
	if not is_instance_valid(cycle_player) or cycle_player.health <= 0:
		return false
	if not cycle_player.defeated.is_connected(_on_cycle_player_defeated):
		cycle_player.defeated.connect(_on_cycle_player_defeated)
	cancel_return_elapsed = -1.0
	cycle_running = true
	_begin_offense()
	return true

func _begin_offense() -> void:
	cycle_id += 1
	cycle_elapsed = 0.0
	core_exposed = false
	_cancel_offensives()
	sprite.flip_h = false
	_play(State.EXITING,&"exit")
	core_exposure_changed.emit(false)

func attack_slot_available(kind: StringName) -> bool:
	if not cycle_running or core_exposed or health <= 0:
		return false
	if kind in [&"horizontal_laser",&"vertical_burst"]:
		return state == State.OFFSCREEN
	return kind == &"direct_projectile" and state == State.RETURNED

func _cancel_offensives() -> void:
	# Drivers must cancel warnings, packets and hitboxes on this signal.
	$BeamAttack.call("stop")
	$ArcAttack.call("cancel")
	beam_running = false
	arc_running = false
	offensive_attacks_cancelled.emit(cycle_id)

func _physics_process(delta: float) -> void:
	if cancel_return_elapsed >= 0.0:
		cancel_return_elapsed = minf(1.0,cancel_return_elapsed+delta)
		visual_root.position = cancel_return_origin.lerp(Vector2.ZERO,smoothstep(0.0,1.0,cancel_return_elapsed))
		_update_core()
		if cancel_return_elapsed >= 1.0:
			cancel_return_elapsed = -1.0
			_play(State.IDLE,&"repose")
		return
	if not cycle_running:
		return
	if not is_instance_valid(cycle_player) or cycle_player.health <= 0:
		stop_combat_cycle()
		return
	if state == State.VULNERABLE:
		window_elapsed += delta
		if window_elapsed+0.00001 >= OVERHEAT_SECONDS:
			core_exposed = false
			core_exposure_changed.emit(false)
			closing_elapsed = 0.0
			_play(State.CORE_CLOSING,&"vulnerable")
			sprite.set_frame_and_progress(base_frames.get_frame_count(&"vulnerable")-1,1.0)
			sprite.play_backwards(&"vulnerable")
		return
	if state == State.CORE_CLOSING:
		closing_elapsed += delta
		if closing_elapsed+0.00001 >= float(base_frames.get_frame_count(&"vulnerable"))/base_frames.get_animation_speed(&"vulnerable"):
			_begin_offense()
		return
	cycle_elapsed += delta
	if cycle_elapsed < 1.0:
		visual_root.position = Vector2.ZERO.lerp(OFFSCREEN_OFFSET,smoothstep(0.0,1.0,cycle_elapsed))
		if cycle_elapsed >= 0.5 and sprite.animation != &"exit_repose":
			_play(State.EXITING,&"exit_repose")
	elif cycle_elapsed < RETURN_START:
		visual_root.position = OFFSCREEN_OFFSET
		if state != State.OFFSCREEN:
			_play(State.OFFSCREEN,&"exit_repose")
			attack_slot_ready.emit(&"horizontal_laser",cycle_id)
			attack_slot_ready.emit(&"vertical_burst",cycle_id)
	elif cycle_elapsed < LANDING_START:
		if state != State.RETURNING:
			_cancel_offensives()
			sprite.flip_h = true
			_play(State.RETURNING,&"retorn_repose")
		visual_root.position = OFFSCREEN_OFFSET.lerp(Vector2.ZERO,smoothstep(RETURN_START,LANDING_START,cycle_elapsed))
	elif cycle_elapsed < LANDING_END:
		visual_root.position = Vector2.ZERO
		if sprite.animation != &"retorn":
			_play(State.RETURNING,&"retorn")
	elif cycle_elapsed < OPENING_START:
		if state != State.RETURNED:
			_play(State.RETURNED,&"repose")
			attack_slot_ready.emit(&"direct_projectile",cycle_id)
	elif cycle_elapsed+0.00001 < OFFENSIVE_SECONDS:
		if state != State.CORE_OPENING:
			_cancel_offensives()
			_play(State.CORE_OPENING,&"vulnerable")
	else:
		_cancel_offensives()
		visual_root.position = Vector2.ZERO
		sprite.set_frame_and_progress(base_frames.get_frame_count(&"vulnerable")-1,0.0)
		sprite.pause()
		state = State.VULNERABLE
		core_exposed = true
		window_elapsed = 0.0
		_update_core()
		core_exposure_changed.emit(true)
		state_changed.emit(state)
	_update_core()

func _disconnect_cycle_player() -> void:
	if is_instance_valid(cycle_player) and cycle_player.defeated.is_connected(_on_cycle_player_defeated):
		cycle_player.defeated.disconnect(_on_cycle_player_defeated)
	cycle_player = null

func _on_cycle_player_defeated() -> void:
	stop_combat_cycle()

func stop_combat_cycle() -> void:
	cycle_running = false
	core_exposed = false
	_cancel_offensives()
	_disconnect_cycle_player()
	core_shape.set_deferred("disabled",true)
	core_exposure_changed.emit(false)
	if state == State.DEFEATED:
		return
	if visual_root.position != Vector2.ZERO:
		cancel_return_origin = visual_root.position
		cancel_return_elapsed = 0.0
		sprite.flip_h = true
		_play(State.RETURNING,&"retorn_repose")
	else:
		_play(State.IDLE,&"repose")

func _confirm_defeat() -> void:
	if state == State.DEFEATED:
		return
	cycle_running = false
	core_exposed = false
	_cancel_offensives()
	_disconnect_cycle_player()
	core_shape.set_deferred("disabled",true)
	core_exposure_changed.emit(false)
	_play(State.DEFEATED,&"defeated")
	defeated.emit()

func guardian_hint_text() -> String:
	if not cycle_running:
		return ""
	if state == State.VULNERABLE:
		return "SOBRECALENTAMIENTO — espada en Presente." if can_receive_damage() else "NÚCLEO TEMPORAL — vuelve a Presente."
	return "ESCUDO ACTIVO — aprovecha para moverte. Mi paciencia también se recalienta."

func _exit_tree() -> void:
	offensive_attacks_cancelled.emit(cycle_id)
	_disconnect_cycle_player()
	cycle_running = false
