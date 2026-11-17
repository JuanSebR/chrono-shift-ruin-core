extends SceneTree

const ROOM_PATH: String = "res://scenes/Room2.tscn"
const FRAME_LIMIT: int = 180
const LANDING_TOLERANCE_Y: float = 3.0

const ASCENT: Array[Dictionary] = [
	{"name": "Slope -> P1", "prepare_x": 1500.0, "target_x": 1370.0, "surface_y": 600.0},
	{"name": "P1 -> P2", "prepare_x": 1340.0, "target_x": 1210.0, "surface_y": 540.0},
	{"name": "P2 -> P3", "prepare_x": 1180.0, "target_x": 1140.0, "surface_y": 480.0},
	{"name": "P3 -> Step1", "prepare_x": 1110.0, "target_x": 1080.0, "surface_y": 440.0},
	{"name": "Step1 -> P4", "prepare_x": 1000.0, "takeoff_x": 875.0, "target_x": 800.0, "surface_y": 380.0},
	{"name": "P4 -> P5", "prepare_x": 815.0, "target_x": 942.0, "surface_y": 325.0},
	{"name": "P5 -> Step2", "prepare_x": 975.0, "target_x": 1060.0, "surface_y": 325.0},
	{"name": "Step2 -> P6", "prepare_x": 1060.0, "target_x": 975.0, "surface_y": 265.0},
	{"name": "P6 -> P7", "prepare_x": 1010.0, "target_x": 1127.0, "surface_y": 205.0},
	{"name": "P7 -> Step3", "prepare_x": 1160.0, "target_x": 1235.0, "surface_y": 205.0},
	{"name": "Step3 -> P8", "prepare_x": 1235.0, "target_x": 1147.0, "surface_y": 145.0},
	{"name": "P8 -> P9", "prepare_x": 1185.0, "target_x": 1325.0, "surface_y": 98.0},
	{"name": "P9 -> Upper", "prepare_x": 1360.0, "target_x": 1480.0, "surface_y": 98.0},
]

const DESCENT: Array[Dictionary] = [
	{"name": "Upper -> P9", "prepare_x": 1470.0, "target_x": 1325.0, "surface_y": 98.0},
	{"name": "P9 -> P8", "prepare_x": 1290.0, "target_x": 1147.0, "surface_y": 145.0},
	{"name": "P8 -> Step3", "prepare_x": 1110.0, "target_x": 1235.0, "surface_y": 205.0},
	{"name": "Step3 -> P7", "prepare_x": 1230.0, "target_x": 1127.0, "surface_y": 205.0, "release_frame": 1},
	{"name": "P7 -> P6", "prepare_x": 1095.0, "target_x": 975.0, "surface_y": 265.0},
	{"name": "P6 -> Step2", "prepare_x": 940.0, "target_x": 1060.0, "surface_y": 325.0},
	{"name": "Step2 -> P5", "prepare_x": 1060.0, "target_x": 942.0, "surface_y": 325.0, "release_frame": 1},
	{"name": "P5 -> P4", "prepare_x": 910.0, "target_x": 800.0, "surface_y": 380.0},
	{"name": "P4 -> Step1", "prepare_x": 750.0, "target_x": 870.0, "surface_y": 440.0},
	{"name": "Step1 -> P3", "prepare_x": 1080.0, "target_x": 1140.0, "surface_y": 480.0},
	{"name": "P3 -> P2", "prepare_x": 1170.0, "target_x": 1210.0, "surface_y": 540.0},
	{"name": "P2 -> P1", "prepare_x": 1185.0, "takeoff_x": 1235.0, "target_x": 1370.0, "surface_y": 600.0, "release_frame": 1},
	{"name": "P1 -> slope", "prepare_x": 1400.0, "target_x": 1500.0, "surface_y": 632.0},
]

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		print("FAIL: ", message)


func run() -> void:
	var room: Node2D = (load(ROOM_PATH) as PackedScene).instantiate()
	root.add_child(room)
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	for frame: int in range(40):
		await physics_frame
	check(player.is_on_floor(), "Player starts grounded")
	Input.action_press("move_right")
	for frame: int in range(900):
		await physics_frame
		if player.global_position.x >= 1490.0:
			break
	Input.action_release("move_right")
	await brake(player)
	check(player.global_position.x >= 1490.0, "lower route reaches stair start")
	var ascent_ok: bool = await run_route(player, ASCENT, "ASCENT")
	check(ascent_ok, "complete ascent uses real movement and jump input")
	var descent_ok: bool = false
	if ascent_ok:
		descent_ok = await run_route(player, DESCENT, "DESCENT")
	check(descent_ok, "complete descent uses real movement and jump input")
	clear_inputs()
	print("RESULT failures=", failures)
	quit(1 if failures > 0 else 0)


func run_route(player: CharacterBody2D, route: Array[Dictionary], phase: String) -> bool:
	for connection: Dictionary in route:
		var prepared: bool = await walk_to(player, float(connection["prepare_x"]))
		if not prepared:
			print("FAIL: ", phase, " prepare ", connection["name"], " pos=", player.global_position)
			return false
		var landed: bool = await jump_to(
			player,
			String(connection["name"]),
			float(connection["target_x"]),
			float(connection["surface_y"]),
			float(connection.get("takeoff_x", connection["prepare_x"])),
			int(connection.get("release_frame", 20))
		)
		if not landed:
			return false
	return true


func walk_to(player: CharacterBody2D, target_x: float) -> bool:
	var direction: float = signf(target_x - player.global_position.x)
	if is_zero_approx(direction):
		return true
	var action: StringName = &"move_right" if direction > 0.0 else &"move_left"
	Input.action_press(action)
	for frame: int in range(240):
		await physics_frame
		if direction > 0.0 and player.global_position.x >= target_x - 14.0:
			break
		if direction < 0.0 and player.global_position.x <= target_x + 14.0:
			break
	Input.action_release(action)
	await brake(player)
	return absf(player.global_position.x - target_x) <= 22.0 and player.is_on_floor()


func brake(player: CharacterBody2D) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	for frame: int in range(20):
		await physics_frame
		if absf(player.velocity.x) < 1.0:
			break


func jump_to(player: CharacterBody2D, label: String, target_x: float, surface_y: float, takeoff_x: float, release_frame: int) -> bool:
	var direction: float = signf(target_x - player.global_position.x)
	var action: StringName = &"move_right" if direction > 0.0 else &"move_left"
	Input.action_release("jump")
	await physics_frame
	await process_frame
	Input.action_press(action)
	for frame: int in range(180):
		if direction > 0.0 and player.global_position.x >= takeoff_x:
			break
		if direction < 0.0 and player.global_position.x <= takeoff_x:
			break
		await physics_frame
	var start: Vector2 = player.global_position
	Input.action_press("jump")
	var jump_started: bool = false
	var takeoff_frames: int = 0
	for frame: int in range(6):
		await physics_frame
		await process_frame
		takeoff_frames += 1
		if player.velocity.y < -1.0:
			jump_started = true
			break
	print("TAKEOFF ", label, " pos=", player.global_position, " velocity=", player.velocity, " floor=", player.is_on_floor())
	if not jump_started:
		clear_inputs()
		print("JUMP ", label, " start=", start, " end=", player.global_position, " time=no_takeoff landed=false")
		return false
	var elapsed_frames: int = takeoff_frames
	var horizontal_released: bool = false
	for frame: int in range(FRAME_LIMIT):
		if frame == release_frame:
			Input.action_release("jump")
		if not horizontal_released:
			if direction > 0.0 and player.global_position.x >= target_x - 15.0:
				Input.action_release(action)
				horizontal_released = true
			elif direction < 0.0 and player.global_position.x <= target_x + 15.0:
				Input.action_release(action)
				horizontal_released = true
		await physics_frame
		elapsed_frames += 1
		if elapsed_frames > 5 and player.is_on_floor() and absf(player.global_position.x - target_x) <= 55.0:
			clear_inputs()
			await brake(player)
			var expected_y: float = surface_y - 20.0
			var landed: bool = absf(player.global_position.y - expected_y) <= LANDING_TOLERANCE_Y
			landed = landed and absf(player.global_position.x - target_x) <= 55.0
			print("JUMP ", label, " start=", start, " end=", player.global_position, " time=", snappedf(float(elapsed_frames) / 60.0, 0.001), " landed=", landed)
			return landed
	clear_inputs()
	print("JUMP ", label, " start=", start, " end=", player.global_position, " time=timeout landed=false")
	return false


func clear_inputs() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
