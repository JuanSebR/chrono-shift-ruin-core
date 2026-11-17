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
	var hud: CanvasLayer = current_scene.get_node("CombatHUD") as CanvasLayer
	arrivals.append({"scene": current_scene.scene_file_path, "health": int(player.get("health")), "hud": int(hud.get("displayed_health")), "position": player.global_position})


func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1


func travel(action: String, destination: String, limit: int) -> bool:
	Input.action_press(action)
	for index: int in limit:
		await physics_frame
		await process_frame
		if current_scene != null and current_scene.scene_file_path == destination:
			Input.action_release(action)
			return true
	Input.action_release(action)
	return false


func run() -> void:
	root.get_node("GameProgress").set("has_cronal_sword", true)
	var room: Node = (load(ROOM15) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	player.position = Vector2(900, 351)
	for health: int in [3, 2, 1]:
		player.set("health", health)
		room.get_node("CombatHUD").call("update_health", health)
		player.set("invulnerability_frames_remaining", 300)
		check(await travel("move_right", ROOM2, 100), "enter Room2 with %d/3" % health)
		if current_scene == null or current_scene.scene_file_path != ROOM2:
			quit(1)
			return
		room = current_scene
		player = room.get_node("Player") as CharacterBody2D
		var arrival: Dictionary = arrivals.back()
		check(arrival.health == health and arrival.hud == health, "Room2 immediate HUD %d/3" % health)
		if health == 1:
			check((room.get_node("CombatHUD/HealthAnchor/HealthFrame") as TextureRect).texture.resource_path.contains("critical"), "Room2 critical art on arrival")
		Input.action_press("move_right")
		for index: int in 35:
			await physics_frame
			await process_frame
		Input.action_release("move_right")
		check(await travel("move_left", ROOM15, 110), "return Room1.5 with %d/3" % health)
		if current_scene == null or current_scene.scene_file_path != ROOM15:
			quit(1)
			return
		room = current_scene
		player = room.get_node("Player") as CharacterBody2D
		arrival = arrivals.back()
		check(arrival.health == health and arrival.hud == health, "Room1.5 immediate HUD %d/3" % health)
		if health == 1:
			check((room.get_node("CombatHUD/HealthAnchor/HealthFrame") as TextureRect).texture.resource_path.contains("critical"), "Room1.5 critical art on return")
	print("RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
