extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func shift() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"dimension_shift"
	event.pressed = true
	Input.parse_input_event(event)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var directory: String = "res://artifacts/temporal_protection_visual"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var shot: Image = root.get_texture().get_image()
	var path: String = "%s/%s_%dx%d.png" % [directory, label, shot.get_width(), shot.get_height()]
	check(shot.save_png(path) == OK, "Captura " + label)

func _run() -> void:
	root.size = Vector2i(1280, 720) if "1280" in OS.get_cmdline_user_args() else Vector2i(1024, 572)
	var progress: Node = root.get_node("GameProgress")
	progress.has_temporal_lens = false
	var room: Node2D = (load("res://scenes/Room4.tscn") as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player")
	var manager: Node = room.get_node("DimensionManager")
	var lens: Control = room.get_node("CombatHUD/TemporalLensHUD")
	var icon: TextureRect = lens.get_node("LensIcon")
	await create_timer(0.05).timeout
	check(not lens.visible and lens.protection_frame == -1, "Sin Lente el efecto está oculto")
	shift()
	await create_timer(0.05).timeout
	check(manager.active_dimension == 0 and not player.is_temporally_protected(), "Shift sin Lente no activa efecto")
	progress.has_temporal_lens = true
	lens.sync_from_progress()
	check(lens.visible and lens.protection_frame == -1, "Presente disponible")
	await capture("present_ready")
	shift()
	await manager.dimension_changed
	check(player.is_temporally_protected() and lens.protection_frame >= 0 and lens.recharge_frame == 0, "Cambio válido muestra protección y recarga real")
	check(icon.texture == lens.protection_frames[lens.protection_frame], "Pose visible proviene de la protección")
	await capture("past_protected_start")
	shift()
	await create_timer(0.06).timeout
	check(manager.active_dimension == 1 and player.is_temporally_protected() and lens.protection_frame >= 0, "Shift durante cooldown no reinicia efecto")
	await capture("past_protected_mid")
	await create_timer(0.10).timeout
	check(not player.is_temporally_protected() and lens.protection_frame == -1 and lens.recharge_frame >= 0, "Protección termina antes de recarga")
	await capture("past_recharge_only")
	await create_timer(0.09).timeout
	check(lens.recharge_frame == -1 and lens.protection_frame == -1 and lens.status.text == "PASADO", "Pasado disponible después de recarga")
	await capture("past_ready")
	shift()
	await manager.dimension_changed
	check(manager.active_dimension == 0 and player.is_temporally_protected() and lens.protection_frame >= 0 and lens.status.text.begins_with("PRESENTE"), "Destello también funciona al regresar a Presente")
	await capture("present_protected")
	await create_timer(0.23).timeout
	player.take_damage(1)
	check(player.health == 2 and player.invulnerability_frames_remaining > 0 and lens.protection_frame == -1, "Daño normal no muestra efecto temporal")
	manager.restore_present_at_checkpoint()
	player.position = Vector2(450, 405)
	player.set_physics_process(false)
	shift()
	await manager.dimension_change_rejected
	check(lens.protection_frame == -1 and not player.is_temporally_protected(), "Cambio rechazado sin efecto")
	await capture("present_rejected")
	player.position = Vector2(64, 396)
	player.set_physics_process(true)
	shift()
	await manager.dimension_changed
	check(player.is_temporally_protected() and lens.protection_frame >= 0, "Efecto reactiva con otro cambio válido")
	player.position = Vector2(350, 700)
	await create_timer(0.06).timeout
	check(not player.is_temporally_protected() and lens.protection_frame == -1 and manager.active_dimension == 0, "Caída cancela efecto")
	shift()
	await manager.dimension_changed
	player.health = 0
	player.defeated.emit()
	check(not player.is_temporally_protected() and lens.protection_frame == -1, "Derrota cancela efecto")
	room.queue_free()
	await process_frame
	var room3: Node2D = (load("res://scenes/Room3.tscn") as PackedScene).instantiate()
	root.add_child(room3)
	check(room3.get_node("CombatHUD/TemporalLensHUD").protection_frame == -1, "Cambio de sala no conserva efecto")
	room3.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
