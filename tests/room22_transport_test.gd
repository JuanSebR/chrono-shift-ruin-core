extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in count:
		await physics_frame
		await process_frame

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func run() -> void:
	var room: Node2D = load("res://scenes/Room2_2.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var p: CharacterBody2D = room.get_node("Player")
	var platform: AnimatableBody2D = room.get_node("MovingPlatforms/CyanTransportPlatform")
	# Esta regresion mide transporte y transiciones, no supervivencia en el corredor.
	for guard_name: String in ["Guard22_A", "Guard22_B", "Guard22_C"]:
		var guard: CharacterBody2D = room.get_node(guard_name) as CharacterBody2D
		guard.set_physics_process(false)
	await frames(20)
	check(p.is_on_floor() and absf(p.position.y - 382.0) < 1.0, "safe spawn")
	Input.action_press("move_right")
	for i: int in 100:
		await frames(1)
		if p.position.x >= 260:
			break
	Input.action_release("move_right")
	await frames(20)
	check(p.is_on_floor() and absf(p.position.y - 420.0) < 2.0, "boarding with real input")
	var offset: float = p.position.x - platform.position.x
	var stable: bool = true
	for i: int in 400:
		await frames(1)
		stable = stable and p.is_on_floor() and absf(p.position.x - platform.position.x - offset) < 3.0
	check(stable, "transport and reversals without sliding")
	for i: int in 400:
		await frames(1)
		if platform.position.x >= 364:
			break
	Input.action_press("move_right")
	Input.action_press("jump")
	await frames(20)
	Input.action_release("jump")
	for i: int in 120:
		await frames(1)
		if p.position.x > 520 and p.is_on_floor():
			break
	check(p.position.x > 520 and p.is_on_floor(), "jump and disembark")
	for i: int in 420:
		await frames(1)
		if p.position.x > 1950:
			break
	Input.action_release("move_right")
	check(p.position.x > 1950 and p.is_on_floor(), "walk to future door")
	check(not room.get_node("RoomTransitions/ToRoom3").monitoring, "Room3 inactive")
	check(room.get_node("CombatHUD") != null, "shared HUD")
	p.health = 2
	room.get_node("RoomTransitions/ToRoom2").call("_on_body_entered", p)
	await frames(20)
	var previous: Node = current_scene
	var previous_player: CharacterBody2D = previous.get_node("Player")
	check(previous.scene_file_path == "res://scenes/Room2.tscn" and absf(previous_player.position.x - 1550.0) < 2.0, "return to Room2 without loop")
	previous.get_node("RoomTransitions/ToRoom2_2").call("_on_body_entered", previous_player)
	await frames(20)
	var arrived: CharacterBody2D = current_scene.get_node("Player")
	check(current_scene.scene_file_path == "res://scenes/Room2_2.tscn" and absf(arrived.position.x - 125.0) < 2.0 and arrived.velocity == Vector2.ZERO and arrived.health == 2, "Room2 arrival position velocity and health")
	print("RESULT failures=", failures)
	quit(1 if failures else 0)
