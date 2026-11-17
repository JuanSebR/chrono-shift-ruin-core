extends SceneTree
var failures: int = 0
var capture_return_arrival: bool = false
var return_arrival_position: Vector2 = Vector2.ZERO
var return_arrival_velocity: Vector2 = Vector2.ZERO
var return_arrival_health: int = -1
func _init() -> void:
	scene_changed.connect(_on_scene_changed)
	call_deferred("run")

func _on_scene_changed() -> void:
	if not capture_return_arrival or current_scene == null or current_scene.scene_file_path != "res://scenes/Room1_Tutorial.tscn":
		return
	var player: CharacterBody2D = current_scene.get_node("Player") as CharacterBody2D
	return_arrival_position = player.global_position
	return_arrival_velocity = player.velocity
	return_arrival_health = int(player.get("health"))
	print("SCENE_CHANGED_ARRIVAL ", return_arrival_position, " velocity ", return_arrival_velocity)
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1
func step(n: int) -> void:
	for i: int in n:
		await physics_frame
		await process_frame
func run() -> void:
	var progress: Node = root.get_node("GameProgress")
	progress.set("has_cronal_sword", true)
	var room: Node = load("res://scenes/Room1_Tutorial.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player")
	player.position = Vector2(960,284)
	await step(10)
	player.call("take_damage",1)
	for cycle: int in 3:
		Input.action_press("move_right")
		for i: int in 60:
			await step(1)
			if current_scene != null and current_scene.scene_file_path == "res://scenes/Room1_5.tscn":
				break
		Input.action_release("move_right")
		room = current_scene
		check(room.scene_file_path == "res://scenes/Room1_5.tscn","forward transition cycle %d" % cycle)
		if room.scene_file_path != "res://scenes/Room1_5.tscn":
			quit(1)
			return
		player = room.get_node("Player")
		print("FORWARD_POS ", player.position, " health ", player.get("health"))
		check(absf(player.position.x-60.0)<25.0 and int(player.get("health"))==2,"forward marker and health")
		check(not (player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h,"forward facing retained")
		if cycle == 0:
			check(int(player.get("invulnerability_frames_remaining")) > 0,"invulnerability remains active across transition")
		await step(15)
		check(player.is_on_floor() and current_scene == room and player.visible,"forward safe floor, no loop, visible")
		check(get_nodes_in_group("core9_player").size() == 1 and room.find_children("CombatHUD", "CanvasLayer", true, false).size() == 1, "one player and HUD in room1.5")
		check((player.get_node("Camera2D") as Camera2D).is_current(),"camera follows player")
		check(str(room.get_node("CombatHUD/HealthAnchor/HealthValue").get("text")).contains("2/3"),"room1.5 HUD reflects health")
		capture_return_arrival = true
		Input.action_press("move_left")
		for i: int in 100:
			await step(1)
			if current_scene != null and current_scene.scene_file_path == "res://scenes/Room1_Tutorial.tscn":
				break
		Input.action_release("move_left")
		capture_return_arrival = false
		room = current_scene
		check(room.scene_file_path == "res://scenes/Room1_Tutorial.tscn","return transition cycle %d" % cycle)
		if room.scene_file_path != "res://scenes/Room1_Tutorial.tscn":
			quit(1)
			return
		player = room.get_node("Player")
		check(absf(return_arrival_position.x-960.0)<1.0 and return_arrival_health==2,"return marker and health")
		check(return_arrival_velocity.is_zero_approx(),"return arrival starts with zero velocity")
		check((player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h,"return facing retained")
		await step(15)
		check(player.is_on_floor() and current_scene == room and player.visible,"return safe floor, no loop, visible")
		check(get_nodes_in_group("core9_player").size() == 1 and room.find_children("HUD", "CanvasLayer", true, false).size() == 1, "one player and HUD in tutorial")
		check(bool(progress.get("has_cronal_sword")),"sword preserved")
		check((player.get_node("AnimatedSprite2D") as AnimatedSprite2D).sprite_frames.get_frame_count(&"attack")==12,"12 attack frames preserved")
		check((player.get_node("Camera2D") as Camera2D).is_current(),"tutorial camera follows player")
		check(room.get_node("HUD").get("displayed_health")==2,"tutorial HUD reflects health")
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(23.84,39.84)
		query.shape = shape
		query.transform = player.global_transform
		query.collision_mask = 1
		query.exclude = [player.get_rid()]
		check(player.get_world_2d().direct_space_state.intersect_shape(query).is_empty(),"return spawn does not overlap solid terrain")
	player.set("invulnerability_frames_remaining", 0)
	player.call("take_damage", 2)
	await step(80)
	player = current_scene.get_node("Player") as CharacterBody2D
	check(current_scene.scene_file_path == "res://scenes/Room1_Tutorial.tscn" and absf(player.position.x - 45.0) < 0.1 and int(player.get("health")) == 3, "defeat restarts current room at normal spawn, not transition entry")
	check(bool(progress.get("has_cronal_sword")), "sword retained after defeat")
	print("RESULT failures=",failures)
	quit(0 if failures==0 else 1)
