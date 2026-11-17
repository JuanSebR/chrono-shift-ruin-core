extends SceneTree

const ROOM15: String = "res://scenes/Room1_5.tscn"
const ROOM2: String = "res://scenes/Room2.tscn"

var failures: int = 0
var arrivals: Array[Dictionary] = []


func _init() -> void:
	scene_changed.connect(_on_scene_changed)
	call_deferred("run")


func _on_scene_changed() -> void:
	if current_scene == null or current_scene.scene_file_path not in [ROOM15, ROOM2]:
		return
	var player: CharacterBody2D = current_scene.get_node("Player") as CharacterBody2D
	arrivals.append({
		"scene": current_scene.scene_file_path,
		"position": player.global_position,
		"velocity": player.velocity,
		"health": int(player.get("health")),
		"facing_left": (player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h,
		"invulnerability": int(player.get("invulnerability_frames_remaining")),
	})
	print("ARRIVAL ", arrivals.back())


func check(condition: bool, label: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + label)
	if not condition:
		failures += 1


func step() -> void:
	await physics_frame
	await process_frame


func travel(action: String, destination: String, limit: int) -> bool:
	Input.action_press(action)
	for index: int in limit:
		await step()
		if current_scene != null and current_scene.scene_file_path == destination:
			Input.action_release(action)
			return true
	Input.action_release(action)
	return false


func safe_spawn(player: CharacterBody2D) -> bool:
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(23.84, 39.84)
	query.shape = shape
	query.transform = player.global_transform
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	return player.get_world_2d().direct_space_state.intersect_shape(query).is_empty()


func run() -> void:
	var progress: Node = root.get_node("GameProgress")
	progress.set("has_cronal_sword", true)
	var room: Node = (load(ROOM15) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	player.position = Vector2(900, 351)
	player.set("health", 2)
	player.set("invulnerability_frames_remaining", 60)
	player.set("attack_cooldown_remaining", 0.25)
	for index: int in 3:
		if not await travel("move_right", ROOM2, 100):
			check(false, "enter Room2 cycle %d" % index)
			quit(1)
			return
		room = current_scene
		player = room.get_node("Player") as CharacterBody2D
		var arrival: Dictionary = arrivals.back()
		check(arrival.scene == ROOM2 and arrival.position.distance_to(Vector2(100, 560)) < 0.01, "Room2 exact marker cycle %d" % index)
		check((arrival.velocity as Vector2).is_zero_approx(), "Room2 initial velocity cycle %d" % index)
		check(arrival.health == 2 and not arrival.facing_left, "Room2 health and facing cycle %d" % index)
		check(bool(progress.get("has_cronal_sword")), "sword retained cycle %d" % index)
		check(get_nodes_in_group("core9_player").size() == 1 and safe_spawn(player), "Room2 one safe player cycle %d" % index)
		if index == 0:
			check(arrival.invulnerability > 0, "damage protection carried to Room2")
		for frame: int in 15:
			await step()
		check(current_scene == room and player.is_on_floor(), "Room2 no return loop cycle %d" % index)
		Input.action_press("move_right")
		for frame: int in 35:
			await step()
		Input.action_release("move_right")
		check(player.global_position.x > 120.0, "Room2 normal movement cycle %d" % index)
		if not await travel("move_left", ROOM15, 110):
			check(false, "return Room1.5 cycle %d" % index)
			quit(1)
			return
		room = current_scene
		player = room.get_node("Player") as CharacterBody2D
		arrival = arrivals.back()
		check(arrival.scene == ROOM15 and arrival.position.distance_to(Vector2(950, 351)) < 0.01, "Room1.5 exact marker cycle %d" % index)
		check((arrival.velocity as Vector2).is_zero_approx(), "Room1.5 initial velocity cycle %d" % index)
		check(arrival.health == 2 and arrival.facing_left, "Room1.5 health and facing cycle %d" % index)
		check(int(room.get_node("CombatHUD").get("displayed_health")) == 2, "Room1.5 HUD restored cycle %d" % index)
		check(get_nodes_in_group("core9_player").size() == 1 and safe_spawn(player), "Room1.5 one safe player cycle %d" % index)
		check(player.global_position.distance_to((room.get_node("Enemy1") as Node2D).global_position) > 40.0, "Room1.5 enemy clear cycle %d" % index)
		for frame: int in 15:
			await step()
		check(current_scene == room and player.is_on_floor(), "Room1.5 no return loop cycle %d" % index)
	print("RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
