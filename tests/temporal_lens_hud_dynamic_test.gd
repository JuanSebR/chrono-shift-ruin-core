extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		failures += 1

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var directory: String = "res://artifacts/room4_stage_d"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var image: Image = root.get_texture().get_image()
	check(image.save_png("%s/%s_%dx%d.png" % [directory, label, image.get_width(), image.get_height()]) == OK, label)

func shift() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"dimension_shift"
	event.pressed = true
	Input.parse_input_event(event)

func _run() -> void:
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 720) if "1280" in OS.get_cmdline_user_args() else Vector2i(1024, 572)
	var progress: Node = root.get_node("GameProgress")
	progress.has_temporal_lens = false
	var room: Node2D = load("res://scenes/Room4.tscn").instantiate()
	root.add_child(room)
	var lens: Control = room.get_node("CombatHUD/TemporalLensHUD")
	var status: Label = lens.get_node("Status")
	var manager: Node = room.get_node("DimensionManager")
	check(not lens.visible, "Sin Lente")
	await capture("hidden")
	progress.has_temporal_lens = true
	progress.temporal_lens_acquired.emit()
	await create_timer(0.35).timeout
	check(lens.visible and status.text == "PRESENTE", "Adquisición y Presente")
	await capture("present")
	shift()
	await manager.dimension_changed
	check(lens.recharge_frame == 0 and manager.switch_cooldown_remaining == 0.2, "Recarga nace del gestor")
	await capture("recharge_start")
	shift()
	await create_timer(0.09).timeout
	check(manager.active_dimension == 1 and lens.recharge_frame in range(1, 6), "Recarga avanza sin reinicio")
	await capture("recharge_mid")
	await create_timer(0.16).timeout
	check(lens.recharge_frame == -1 and status.text == "PASADO", "Pasado disponible")
	await capture("past_ready")
	shift()
	await manager.dimension_changed
	await create_timer(0.24).timeout
	check(status.text == "PRESENTE", "Vuelta a Presente")
	var player: CharacterBody2D = room.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector2(450, 405)
	shift()
	await manager.dimension_change_rejected
	check(status.text.contains("CAMBIO BLOQUEADO") and lens.recharge_frame == -1 and manager.switch_cooldown_remaining == 0, "Rechazo sin recarga falsa")
	await capture("rejected")
	room.queue_free()
	await process_frame
	var room3: Node2D = load("res://scenes/Room3.tscn").instantiate()
	root.add_child(room3)
	var neutral: Control = room3.get_node("CombatHUD/TemporalLensHUD")
	check(neutral.visible and neutral.get_node("Status").text == "LENTE INSTALADA", "Room3 neutral al volver")
	await capture("neutral")
	quit(0 if failures == 0 else 1)
