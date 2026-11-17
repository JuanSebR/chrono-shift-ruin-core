extends SceneTree

const ROOM22: String = "res://scenes/Room2_2.tscn"
const VOID_POSITION: Vector2 = Vector2(220.0, 751.0)
const SPAWN: Vector2 = Vector2(125.0, 382.0)

var failures: int = 0
var reloads: int = 0
var platform_reset_states: Array[Dictionary] = []

func _init() -> void:
	scene_changed.connect(_on_scene_changed)
	call_deferred("run")

func _on_scene_changed() -> void:
	if current_scene != null and current_scene.scene_file_path == ROOM22:
		reloads += 1
		var platform: AnimatableBody2D = current_scene.get_node_or_null("MovingPlatforms/CyanTransportPlatform") as AnimatableBody2D
		if platform != null:
			platform_reset_states.append({
				"x": platform.position.x,
				"target_right": bool(platform.get("target_right")),
				"waiting": float(platform.get("waiting")),
			})

func frames(count: int) -> void:
	for index: int in count:
		await physics_frame
		await process_frame

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func run_void_cycle(room: Node2D, start_health: int, invulnerable: bool) -> Node2D:
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	var hud: CanvasLayer = room.get_node("CombatHUD") as CanvasLayer
	player.health = start_health
	player.invulnerability_frames_remaining = 60 if invulnerable else 0
	hud.call("update_health", start_health)
	var zero_events: Array[int] = [0]
	player.health_changed.connect(func(value: int) -> void:
		if value == 0:
			zero_events[0] += 1
	)
	player.global_position = VOID_POSITION
	player.velocity = Vector2(0.0, 20.0)
	await frames(2)
	check(player.health == 0 and int(hud.get("displayed_health")) == 0, "void fall %d/3 reaches 0/3%s" % [start_health, " despite invulnerability" if invulnerable else ""])
	check(zero_events[0] == 1 and bool(room.get("restart_pending")), "void defeat emits once and begins restart")
	await frames(150)
	var restarted: Node2D = current_scene as Node2D
	check(restarted != room and restarted.scene_file_path == ROOM22, "void defeat reloads only Room2_2")
	var restarted_player: CharacterBody2D = restarted.get_node("Player") as CharacterBody2D
	var restarted_hud: CanvasLayer = restarted.get_node("CombatHUD") as CanvasLayer
	check(restarted_player.health == 3 and int(restarted_hud.get("displayed_health")) == 3 and restarted_player.global_position.distance_to(SPAWN) < 1.0 and restarted_player.velocity == Vector2.ZERO, "restart restores 3/3 at Room2_2 entry")
	var reset_state: Dictionary = platform_reset_states.back()
	check(absf(float(reset_state["x"]) - 260.0) < 0.1 and bool(reset_state["target_right"]) and is_equal_approx(float(reset_state["waiting"]), 1.0), "restart resets cyan platform")
	for guard_name: String in ["Guard22_A", "Guard22_B", "Guard22_C"]:
		check(int(restarted.get_node(guard_name).get("health")) == 2, "%s restarts alive" % guard_name)
	return restarted

func run() -> void:
	var progress: Node = root.get_node("GameProgress")
	progress.set("has_cronal_sword", true)
	var room: Node2D = load(ROOM22).instantiate() as Node2D
	root.add_child(room)
	current_scene = room
	await frames(20)
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	player.global_position = Vector2(250.0, 420.0)
	await frames(20)
	check(player.health == 3, "normal platform approach does not trigger void death")
	room = await run_void_cycle(room, 3, false)
	room = await run_void_cycle(room, 2, false)
	room = await run_void_cycle(room, 1, false)
	room = await run_void_cycle(room, 3, true)
	check(bool(progress.get("has_cronal_sword")), "sword progress survives void restarts")
	check(reloads >= 4, "all void cycles reloaded the same room")
	print("RESULT failures=", failures)
	quit(1 if failures else 0)
