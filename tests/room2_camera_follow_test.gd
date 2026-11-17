extends SceneTree

const ROOM_PATH: String = "res://scenes/Room2.tscn"
const WORLD_SIZE: Vector2 = Vector2(1672.0, 941.0)
const SAMPLE_X: Array[float] = [100.0, 350.0, 550.0, 800.0, 1100.0, 1350.0, 1500.0]
const SAMPLE_Y: Array[float] = [560.0, 560.0, 560.0, 560.0, 680.0, 680.0, 620.0]

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
	for viewport_size: Vector2i in [Vector2i(1024, 572), Vector2i(1280, 720)]:
		await test_viewport(viewport_size)
	await test_physical_round_trip()
	print("RESULT failures=", failures)
	quit(1 if failures > 0 else 0)


func test_viewport(viewport_size: Vector2i) -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var room: Node2D = (load(ROOM_PATH) as PackedScene).instantiate()
	viewport.add_child(room)
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	var camera: Camera2D = player.get_node("Camera2D") as Camera2D
	var hud_anchor: Control = room.get_node("CombatHUD/HealthAnchor") as Control
	camera.position_smoothing_enabled = false
	camera.make_current()
	await process_frame
	check(camera.is_current(), "%s uses Player camera" % viewport_size)
	check(camera.enabled, "%s Player camera enabled" % viewport_size)
	check(camera.limit_left == 0 and camera.limit_top == 0, "%s upper-left limits" % viewport_size)
	check(camera.limit_right == int(WORLD_SIZE.x) and camera.limit_bottom == int(WORLD_SIZE.y), "%s Room2 world limits" % viewport_size)
	for i: int in range(SAMPLE_X.size()):
		player.global_position = Vector2(SAMPLE_X[i], SAMPLE_Y[i])
		player.velocity = Vector2.ZERO
		camera.reset_smoothing()
		camera.force_update_scroll()
		await process_frame
		var center: Vector2 = camera.get_screen_center_position()
		var screen_position: Vector2 = (player.global_position - center) * camera.zoom + Vector2(viewport_size) * 0.5
		var visible: bool = screen_position.x >= 24.0 and screen_position.x <= float(viewport_size.x) - 24.0
		visible = visible and screen_position.y >= 40.0 and screen_position.y <= float(viewport_size.y) - 20.0
		print("SAMPLE size=", viewport_size, " player=", player.global_position, " camera_local=", camera.position, " camera_global=", camera.global_position, " center=", center, " screen=", screen_position, " limits=", Vector4(camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom))
		check(visible, "%s Player visible at X=%d" % [viewport_size, int(SAMPLE_X[i])])
	check(hud_anchor.global_position.x >= 0.0 and hud_anchor.global_position.y >= 0.0, "%s HUD anchored inside viewport" % viewport_size)
	viewport.queue_free()
	await process_frame


func test_physical_round_trip() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1024, 572)
	root.add_child(viewport)
	var room: Node2D = (load(ROOM_PATH) as PackedScene).instantiate()
	viewport.add_child(room)
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	var camera: Camera2D = player.get_node("Camera2D") as Camera2D
	camera.make_current()
	await process_frame
	var always_visible: bool = true
	Input.action_press("move_right")
	for frame: int in range(900):
		await physics_frame
		var center: Vector2 = camera.get_screen_center_position()
		var screen_position: Vector2 = (player.global_position - center) * camera.zoom + Vector2(viewport.size) * 0.5
		always_visible = always_visible and screen_position.x >= 20.0 and screen_position.x <= float(viewport.size.x) - 20.0
		always_visible = always_visible and screen_position.y >= 35.0 and screen_position.y <= float(viewport.size.y) - 15.0
		if player.global_position.x >= 1490.0:
			break
	Input.action_release("move_right")
	check(player.global_position.x >= 1490.0, "physical route reaches right end")
	check(always_visible, "Player remains visible while moving right")
	Input.action_press("move_left")
	for frame: int in range(900):
		await physics_frame
		var center: Vector2 = camera.get_screen_center_position()
		var screen_position: Vector2 = (player.global_position - center) * camera.zoom + Vector2(viewport.size) * 0.5
		always_visible = always_visible and screen_position.x >= 20.0 and screen_position.x <= float(viewport.size.x) - 20.0
		always_visible = always_visible and screen_position.y >= 35.0 and screen_position.y <= float(viewport.size.y) - 15.0
		if player.global_position.x <= 110.0:
			break
	Input.action_release("move_left")
	check(player.global_position.x <= 110.0, "physical route returns to left end")
	check(always_visible, "Player remains visible on complete round trip")
	viewport.queue_free()
	await process_frame
