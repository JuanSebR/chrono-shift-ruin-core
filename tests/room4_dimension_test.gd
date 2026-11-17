extends SceneTree

var failures: int = 0
var accepted: int = 0
var rejected: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func shift() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.location = KEY_LOCATION_LEFT
	key.pressed = true
	Input.parse_input_event(key)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var directory: String = "res://artifacts/room4_stage_c"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var image: Image = root.get_texture().get_image()
	var size: Vector2i = image.get_size()
	check(image.save_png("%s/%s_%dx%d.png" % [directory, label, size.x, size.y]) == OK, "Captura " + label)

func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "1024":
			root.size = Vector2i(1024, 572)
		elif argument == "1280":
			root.size = Vector2i(1280, 720)
	var progress: Node = root.get_node("GameProgress")
	var room: Node2D = (load("res://scenes/Room4.tscn") as PackedScene).instantiate()
	progress.set("has_temporal_lens", false)
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player")
	var manager: Node = room.get_node("DimensionManager")
	var sword: bool = progress.has_cronal_sword
	manager.dimension_changed.connect(func(_present: bool) -> void: accepted += 1)
	manager.dimension_change_rejected.connect(func() -> void: rejected += 1)
	shift()
	await create_timer(0.1).timeout
	check(accepted == 0 and manager.active_dimension == 0 and manager.switch_cooldown_remaining == 0, "Shift bloqueado sin Lente")
	progress.set("has_temporal_lens", true)
	room.get_node("CombatHUD/TemporalLensHUD").sync_from_progress()
	await capture("present")
	shift()
	await create_timer(0.05).timeout
	check(accepted == 1 and manager.active_dimension == 1 and manager.past_visuals.visible and not manager.present_visuals.visible, "Shift sobre repisa compartida")
	for shape: CollisionShape2D in manager.present_shapes:
		check(shape.disabled, "Presente sin colisión en Pasado")
	for shape: CollisionShape2D in manager.past_shapes:
		check(not shape.disabled, "Pasado con colisión")
	shift()
	await create_timer(0.05).timeout
	check(accepted == 1 and manager.switch_cooldown_remaining < 0.15, "Recarga no reiniciada")
	await capture("past")
	await create_timer(0.22).timeout
	shift()
	await create_timer(0.05).timeout
	check(accepted == 2 and manager.active_dimension == 0, "Vuelta después de recarga")
	await create_timer(0.23).timeout
	player.set_physics_process(false)
	player.position = Vector2(450, 405)
	player.velocity = Vector2(75, -20)
	shift()
	await create_timer(0.05).timeout
	check(rejected == 1 and accepted == 2 and manager.active_dimension == 0 and manager.switch_cooldown_remaining == 0, "Rechazo por solapamiento sin recarga")
	check(player.position == Vector2(450, 405) and player.velocity == Vector2(75, -20), "Rechazo conserva posición y velocidad")
	player.position = Vector2(275, 407)
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	await create_timer(0.10).timeout
	check(player.is_on_floor(), "Apoyo inicial sobre MetalLeft")
	Input.action_press("move_right")
	Input.action_press("jump")
	await create_timer(0.22).timeout
	var rising: bool = player.velocity.y < 0.0
	shift()
	await create_timer(0.04).timeout
	await capture("air_past")
	await create_timer(0.49).timeout
	Input.action_release("jump")
	Input.action_release("move_right")
	check(rising and manager.active_dimension == 1 and player.is_on_floor() and absf(player.position.y - 384.0) < 1.0, "Salto real, cambio en ascenso y aterrizaje en PastLeft")
	shift()
	await create_timer(0.12).timeout
	check(manager.active_dimension == 0 and not player.is_on_floor() and player.velocity.y > 0.0, "Caída al retirar apoyo")
	await create_timer(0.12).timeout
	shift()
	await create_timer(0.05).timeout
	check(manager.active_dimension == 1 and player.velocity.y > 0.0, "Cambio durante caída")
	check(player.health == 3 and progress.has_cronal_sword == sword, "Salud y espada conservadas")
	check(root.get_camera_2d() == player.get_node("Camera2D") and room.get_node("CombatHUD/TemporalLensHUD").visible, "Cámara y HUD activos")
	room.free()
	var legacy: Node2D = (load("res://scenes/Room1_Tutorial.tscn") as PackedScene).instantiate()
	root.add_child(legacy)
	var legacy_manager: Node = legacy.get_node("DimensionManager")
	var legacy_player: CharacterBody2D = legacy.get_node("Player")
	legacy_manager.toggle_dimension(legacy_player)
	check(legacy_manager.active_dimension == 1 and legacy_manager.past_tilemap.collision_enabled and not legacy_manager.present_tilemap.collision_enabled, "Room1 conserva TileMapLayer")
	quit(0 if failures == 0 else 1)
