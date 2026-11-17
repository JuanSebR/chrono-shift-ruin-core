extends SceneTree

const ROOM2: String = "res://scenes/Room2.tscn"

var failures: int = 0
var defeat_finished: bool = false
var reload_seen: bool = false


func _init() -> void:
	scene_changed.connect(_on_scene_changed)
	call_deferred("run")


func _on_scene_changed() -> void:
	if current_scene != null and current_scene.scene_file_path == ROOM2:
		reload_seen = true


func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1


func step(count: int) -> void:
	for index: int in count:
		await physics_frame
		await process_frame


func run() -> void:
	var progress: Node = root.get_node("GameProgress")
	progress.set("has_cronal_sword", true)
	var room: Node = (load(ROOM2) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	var hud: CanvasLayer = room.get_node("CombatHUD") as CanvasLayer
	check(room.find_children("CombatHUD", "CanvasLayer", true, false).size() == 1, "one HUD")
	check(int(player.get("health")) == 3 and int(hud.get("displayed_health")) == 3, "initial 3/3")
	var accepted_damage: Array[int] = [0]
	player.damage_taken.connect(func(_health: int) -> void: accepted_damage[0] += 1)
	player.call("take_damage", 1)
	check(int(player.get("health")) == 2 and int(hud.get("displayed_health")) == 2 and int(hud.get("loss_index")) == 0, "valid damage 3 to 2 and loss effect")
	player.call("take_damage", 1)
	check(int(player.get("health")) == 2 and accepted_damage[0] == 1 and int(player.get("invulnerability_frames_remaining")) > 0, "rejected hit during immunity")
	player.set("invulnerability_frames_remaining", 0)
	player.call("take_damage", 1)
	check(int(player.get("health")) == 1 and int(hud.get("displayed_health")) == 1 and accepted_damage[0] == 2, "critical 1/3")
	await step(50)
	check(int(hud.get("loss_index")) == -1 and int(hud.get("critical_index")) >= 0, "loss completed and critical alert active")
	player.set("invulnerability_frames_remaining", 0)
	player.defeat_animation_finished.connect(func() -> void: defeat_finished = true)
	player.call("take_damage", 1)
	check(int(player.get("health")) == 0 and int(hud.get("displayed_health")) == 0 and bool(room.get("restart_pending")), "0/3 starts defeat once")
	await step(10)
	check(current_scene == room and not reload_seen, "scene remains during defeat presentation")
	await step(140)
	check(defeat_finished and reload_seen and current_scene != room, "animation finishes before reload")
	if current_scene != null:
		player = current_scene.get_node("Player") as CharacterBody2D
		hud = current_scene.get_node("CombatHUD") as CanvasLayer
		check(int(player.get("health")) == 3 and int(hud.get("displayed_health")) == 3 and player.global_position.distance_to(Vector2(100, 560)) < 1.0, "safe restart at 3/3")
	check(bool(progress.get("has_cronal_sword")), "sword survives defeat")
	print("RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
