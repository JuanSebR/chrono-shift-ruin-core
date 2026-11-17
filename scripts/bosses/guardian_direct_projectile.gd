extends Node2D

const DIRECTORY: String = "res://assets/sprites/jefe/derived/atlases/"
const PREPARE_TIME: float = 0.6
const SPEED: float = 900.0
const MAX_FLIGHT: float = 1.8
const PACKET_RECOVERY_TIME: float = 0.1
const BODY_RECOVERY_TIME: float = 0.5
var boss: Node2D
var phase: StringName = &"off"
var elapsed: float = 0.0
var flight_elapsed: float = 0.0
var cycle_id: int = -1
var frames: SpriteFrames
var hint: Node
var packet: Sprite2D
var packet_texture: AtlasTexture
var direction: Vector2
var target: Vector2
var origin: Vector2
var owned: bool = false
var emitted: bool = false
var damage_events: int = 0
var emissions: int = 0
var shape: RectangleShape2D = RectangleShape2D.new()
var finishes: Array[AtlasTexture] = []
var finish_elapsed: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boss = get_parent() as Node2D
	top_level = true
	global_position = Vector2.ZERO
	process_physics_priority = 12
	frames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"attack3")
	frames.set_animation_loop(&"attack3",false)
	var atlas: Texture2D = load(DIRECTORY+"attack3_atlas.png")
	for i: int in range(6):
		var texture: AtlasTexture = AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(i*640,0,640,800)
		frames.add_frame(&"attack3",texture)
	packet_texture = AtlasTexture.new()
	packet_texture.atlas = load(DIRECTORY+"beam_hold_atlas.png")
	packet_texture.region = Rect2(0,0,64,64)
	var finish_atlas: Texture2D = load(DIRECTORY+"beam_finish_atlas.png")
	for index: int in range(6):
		var finish_texture: AtlasTexture = AtlasTexture.new()
		finish_texture.atlas = finish_atlas
		finish_texture.region = Rect2(index*64,0,64,64)
		finishes.append(finish_texture)
	shape.size = Vector2(32,16)
	hint = load("res://scenes/ui/TutorialHints.tscn").instantiate()
	add_child(hint)
	boss.attack_slot_ready.connect(_on_slot)
	boss.offensive_attacks_cancelled.connect(_cancel)

func _on_slot(kind: StringName, id: int) -> void:
	if kind != &"direct_projectile" or id == cycle_id or id != boss.cycle_id or not boss.attack_slot_available(kind):
		return
	cycle_id = id
	owned = true
	emitted = false
	elapsed = 0.0
	phase = &"prepare"
	target = boss.cycle_player.global_position
	boss.sprite.flip_h = target.x < boss.global_position.x
	boss.sprite.sprite_frames = frames
	boss.sprite.play(&"attack3")
	boss.sprite.pause()
	boss.sprite.frame = 0
	hint.call("show_hint","direct_warning","PROYECTIL FIJANDO — evita su línea. Sobrevivir es opcional.",Vector2(640,140))

func _pose(frame_index: int) -> void:
	boss.sprite.frame = frame_index
	boss._update_core()

func _muzzle_world() -> Vector2:
	var muzzle: Array = boss.landmarks["attack3"]["frames"][2]["muzzle_atlas_estimate"]
	var x: float = 640.0-float(muzzle[0]) if boss.sprite.flip_h else float(muzzle[0])
	return boss.visual_root.to_global(boss.sprite.position+Vector2(x,float(muzzle[1])))

func _emit() -> void:
	# Sample once at emission; direction remains fixed thereafter.
	target = boss.cycle_player.global_position
	boss.sprite.flip_h = target.x < boss.global_position.x
	origin = _muzzle_world()
	direction = origin.direction_to(target)
	packet = Sprite2D.new()
	packet.texture = packet_texture
	packet.scale = Vector2.ONE*.5
	add_child(packet)
	packet.global_position = origin
	packet.rotation = direction.angle()
	flight_elapsed = 0.0
	emitted = true
	emissions += 1
	phase = &"flight"
	hint.call("hide_hint")

func _physics_process(delta: float) -> void:
	if not owned:
		return
	if cycle_id != boss.cycle_id or not boss.attack_slot_available(&"direct_projectile"):
		_cancel()
		return
	elapsed += delta
	if not emitted:
		target = boss.cycle_player.global_position
		boss.sprite.flip_h = target.x < boss.global_position.x
		# Aim with the original preparation poses for the entire visible warning.
		_pose(0 if elapsed < PREPARE_TIME*0.5 else 1)
		if elapsed+.00001 >= PREPARE_TIME:
			_pose(2)
			_emit()
	else:
		# Original firing/recovery poses; cropped4/5 remain excluded.
		var pose_order: Array[int] = [2,3,1,0]
		_pose(pose_order[mini(3,int((elapsed-PREPARE_TIME)/.125))])
	if is_instance_valid(packet) and phase == &"flight":
		_move_packet(delta)
	elif is_instance_valid(packet) and phase == &"recovery":
		finish_elapsed += delta
		packet.texture = finishes[mini(5,int(finish_elapsed/(PACKET_RECOVERY_TIME/6.0)))]
		if finish_elapsed+.00001 >= PACKET_RECOVERY_TIME:
			_remove_packet()
	if emitted and not is_instance_valid(packet) and elapsed+.00001 >= PREPARE_TIME+BODY_RECOVERY_TIME:
		_cancel()
	queue_redraw()

func _move_packet(delta: float) -> void:
	flight_elapsed += delta
	var start: Vector2 = packet.global_position
	var finish: Vector2 = start+direction*SPEED*delta
	var steps: int = maxi(1,ceili(start.distance_to(finish)/4.0))
	for i: int in range(1,steps+1):
		var point: Vector2 = start.lerp(finish,float(i)/steps)
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(direction.angle(),point)
		query.collision_mask = 2
		for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
			var body: Node = hit["collider"]
			if body.is_in_group("core9_player"):
				var before: int = body.health
				body.take_damage(1)
				if body.health < before:
					damage_events += 1
				_clear_packet()
				return
		if not is_instance_valid(packet):
			return
		packet.global_position = point
	if flight_elapsed >= MAX_FLIGHT or not Rect2(-40,-40,1360,800).has_point(packet.global_position):
		_clear_packet()

func _clear_packet() -> void:
	finish_elapsed = 0.0
	if is_instance_valid(packet):
		packet.texture = finishes[0]
	phase = &"recovery"

func _remove_packet() -> void:
	if is_instance_valid(packet):
		packet.queue_free()
	packet = null

func _cancel(_id: int = -1) -> void:
	_remove_packet()
	hint.call("hide_hint")
	if owned and is_instance_valid(boss.sprite):
		boss.sprite.sprite_frames = boss.base_frames
		boss.sprite.play(&"repose")
	owned = false
	phase = &"off"
	queue_redraw()

func _draw() -> void:
	if not owned or phase != &"prepare":
		return
	var muzzle: Vector2 = _muzzle_world()
	var ray: Vector2 = target-muzzle
	for i: int in range(1,20,2):
		var p: Vector2 = muzzle+ray*float(i)/20.0
		draw_set_transform(p,ray.angle())
		draw_texture_rect_region(packet_texture.atlas,Rect2(-6,-2,12,4),Rect2(0,30,12,4))
	draw_set_transform(Vector2.ZERO)

func _exit_tree() -> void:
	if is_instance_valid(boss):
		boss.attack_slot_ready.disconnect(_on_slot)
		boss.offensive_attacks_cancelled.disconnect(_cancel)
