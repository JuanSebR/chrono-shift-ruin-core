extends SceneTree

const SUPPORTS: Array[Vector3] = [
	Vector3(38, 92, 416), Vector3(178, 298, 428), Vector3(412, 506, 404),
	Vector3(574, 718, 462), Vector3(788, 872, 410), Vector3(954, 1076, 344),
	Vector3(1136, 1240, 284),
]
const NAMES: Array[String] = ["EntryLedge", "MetalLeft", "PastLeft", "CentralRest", "MetalRight", "PastRight", "ExitLedge"]
var player: CharacterBody2D
var manager: Node
var failures: int = 0
var shifts: int = 0
var capture_enabled: bool = false
var pending_air_shift: bool = false
var request_position: Vector2
var request_velocity: Vector2
var apex_checks: int = 0

func observe_shift(_is_present: bool) -> void:
	shifts += 1
	if pending_air_shift:
		var step: float = player.get_physics_process_delta_time()
		var gravity: float = float(player.get("gravity")) * (1.5 if request_velocity.y > 0.0 else 1.0)
		var next_velocity: Vector2 = request_velocity + Vector2(0, gravity * step)
		var unchanged: bool = (
			(player.position.distance_to(request_position) < 0.01 and player.velocity.distance_to(request_velocity) < 0.01)
			or (player.position.distance_to(request_position + next_velocity * step) < 0.01
			and player.velocity.distance_to(next_velocity) < 0.01)
		)
		if not unchanged:
			print("FAIL trayectoria al confirmar: ", request_position, " -> ", player.position, " ", request_velocity, " -> ", player.velocity, " previsto ", request_position + next_velocity * step, " ", next_velocity)
			failures += 1
		if absf(player.velocity.y) < 1.0 and unchanged:
			apex_checks += 1
			print("PASS ápice sin salto de posición ni velocidad ", player.velocity)
		pending_air_shift = false

func _initialize() -> void:
	call_deferred("_run")

func shift() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"dimension_shift"
	event.pressed = true
	Input.parse_input_event(event)

func support() -> String:
	if not player.is_on_floor():
		return ""
	for index: int in range(player.get_slide_collision_count()):
		var collision: KinematicCollision2D = player.get_slide_collision(index)
		if collision.get_normal().y < -0.9:
			return str(collision.get_collider().name)
	var foot: Vector2 = player.position + Vector2(0, 20)
	for offset: float in [0.0, -10.0, 10.0]:
		var point: Vector2 = foot + Vector2(offset, 0)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(point - Vector2(0, 2), point + Vector2(0, 3), 1)
		var hit: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			return str(hit.collider.name)
	return ""

func capture(label: String) -> void:
	if not capture_enabled:
		return
	await RenderingServer.frame_post_draw
	var directory: String = "res://artifacts/room4_stage_e"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var image: Image = root.get_texture().get_image()
	if image.save_png("%s/%s_%dx%d.png" % [directory, label, image.get_width(), image.get_height()]) != OK:
		failures += 1

func jump(from: int, to: int, change_tick: int, inset: float, hold: int) -> bool:
	var direction: float = 1.0 if to > from else -1.0
	var action: StringName = &"move_right" if direction > 0 else &"move_left"
	var origin: Vector3 = SUPPORTS[from]
	var target: Vector3 = SUPPORTS[to]
	var edge: float = origin.y - inset if direction > 0 else origin.x + inset
	var brake: float = (target.x + target.y) * 0.5
	if direction > 0:
		brake = minf(brake, target.x + 22.0)
	else:
		brake = maxf(brake, target.y - 22.0)
	Input.action_press(action)
	for tick: int in range(70):
		if (player.position.x - edge) * direction >= 0:
			break
		await physics_frame
	if support() != NAMES[from]:
		Input.action_release(action)
		print("FAIL despegue ", NAMES[from], " ", player.position, " apoyo=", support())
		return false
	var start: Vector2 = player.position
	var start_speed: Vector2 = player.velocity
	var starting_dimension: int = manager.active_dimension
	var airborne: bool = false
	Input.action_press("jump")
	for tick: int in range(100):
		await physics_frame
		if (player.position.x - brake) * direction >= 0.0:
			Input.action_release(action)
		if tick == hold:
			Input.action_release("jump")
		if not player.is_on_floor():
			airborne = true
		if tick == change_tick:
			print("Shift vuelo tick=", tick, " dimensión=", manager.active_dimension, " pos=", player.position, " v=", player.velocity)
			request_position = player.position
			request_velocity = player.velocity
			pending_air_shift = not capture_enabled
			shift()
		if tick == change_tick + 2 and change_tick >= 0:
			print("  confirmado dimensión=", manager.active_dimension, " pos=", player.position, " v=", player.velocity)
			if capture_enabled and manager.active_dimension != starting_dimension:
				await capture("air_" + NAMES[to])
		if airborne and player.is_on_floor():
			var landed: String = support()
			var margin: float = minf(player.position.x - target.x, target.y - player.position.x) - 12.0
			print(NAMES[from], " -> ", NAMES[to], " inicio=", start, " v0=", start_speed,
				" fin=", player.position, " v=", player.velocity, " ticks=", tick,
				" margen=", snappedf(margin, 0.1), " apoyo=", landed, " dimensión=", manager.active_dimension)
			Input.action_release(action)
			Input.action_release("jump")
			for settle: int in range(10):
				await physics_frame
			return landed == NAMES[to] and support() == NAMES[to] and (change_tick < 0 or manager.active_dimension != starting_dimension)
		if player.position.y > 720:
			break
	Input.action_release(action)
	Input.action_release("jump")
	print("FAIL ", NAMES[from], " -> ", NAMES[to], " inicio=", start, " v0=", start_speed,
		" fin=", player.position, " v=", player.velocity, " dimensión=", manager.active_dimension)
	return false

func _run() -> void:
	root.get_node("GameProgress").set("has_temporal_lens", true)
	capture_enabled = DisplayServer.get_name() != "headless"
	if capture_enabled:
		root.size = Vector2i(1280, 720) if "1280" in OS.get_cmdline_user_args() else Vector2i(1024, 572)
	var attempts: int = 1 if capture_enabled else 3
	for attempt: int in range(attempts):
		var room: Node2D = load("res://scenes/Room4.tscn").instantiate()
		root.add_child(room)
		player = room.get_node("Player")
		manager = room.get_node("DimensionManager")
		shifts = 0
		manager.dimension_changed.connect(observe_shift)
		for tick: int in range(10):
			await physics_frame
		print("INTENTO ", attempt, " spawn=", player.position)
		await capture("entry")
		var ok: bool = true
		var inset: float = [5.0, 9.0, 13.0][attempt]
		for from: int in range(6):
			if from == 3:
				shift()
				for tick: int in range(15):
					await physics_frame
			var timing: int = [21, 16, 25][attempt] if from in [1, 4] else -1
			if not await jump(from, from + 1, timing, inset, [40, 23, 35][attempt]):
				print("FAIL ida tramo ", from + 1)
				ok = false
				break
			await capture("land_" + NAMES[from + 1])
		print("IDA ", "PASS" if ok else "FAIL", " cambios=", shifts)
		ok = ok and shifts == 3
		if ok:
			var camera: Camera2D = player.get_node("Camera2D")
			var lens: Control = room.get_node("CombatHUD/TemporalLensHUD")
			ok = root.get_camera_2d() == camera and lens.is_visible_in_tree() and player.health == 3
			Input.action_press("move_right")
			while player.position.x < 1210 and support() == "ExitLedge":
				await physics_frame
			Input.action_release("move_right")
			for tick: int in range(10):
				await physics_frame
			ok = ok and support() == "ExitLedge" and player.position.x >= 1210
		if ok:
			for from: int in range(6, 0, -1):
				var timing: int = 19 if from in [5, 3, 2] else -1
				if not await jump(from, from - 1, timing, inset, 40):
					print("FAIL regreso tramo ", from)
					ok = false
					break
			await capture("return")
			ok = ok and shifts == 6
			print("REGRESO ", "PASS" if ok else "FAIL", " cambios acumulados=", shifts)
		if not ok:
			failures += 1
		room.queue_free()
		await process_frame
	if not capture_enabled and apex_checks != 2:
		print("FAIL comprobaciones de ápice: ", apex_checks)
		failures += 1
	quit(0 if failures == 0 else 1)
