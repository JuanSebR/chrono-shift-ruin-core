extends "res://tests/room4_route_test.gd"

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func capture(label: String) -> void:
	if not capture_enabled:
		return
	await RenderingServer.frame_post_draw
	var directory: String = "res://artifacts/room4_stage_g"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var image: Image = root.get_texture().get_image()
	check(image.save_png("%s/%s_%dx%d.png" % [directory, label, image.get_width(), image.get_height()]) == OK, label)

func _run() -> void:
	capture_enabled = DisplayServer.get_name() != "headless"
	if capture_enabled:
		root.size = Vector2i(1280, 720) if "1280" in OS.get_cmdline_user_args() else Vector2i(1024, 572)
	var progress: Node = root.get_node("GameProgress")
	progress.has_temporal_lens = true
	var room: Node2D = load("res://scenes/Room4.tscn").instantiate()
	root.add_child(room)
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	var hints: CanvasLayer = room.get_node("TutorialHints")
	for tick: int in range(8):
		await physics_frame
	check(hints.active_id == "room4_shift", "Shift inicial")
	await capture("tutorial_shift")
	player.dialogue_controls_locked = true
	await physics_frame
	await physics_frame
	check(hints.active_id.is_empty(), "Aviso oculto con controles bloqueados")
	player.dialogue_controls_locked = false
	player.set_physics_process(false)
	player.position = Vector2(450, 405)
	shift()
	for tick: int in range(6):
		await physics_frame
	check(not progress.tutorial_completed("room4_shift") and manager.active_dimension == 0, "Rechazo no completa Shift")
	player.position = Vector2(64, 396)
	player.set_physics_process(true)
	for tick: int in range(8):
		await physics_frame
	var landed: bool = await jump(0, 1, -1, 5, 40)
	check(landed and progress.tutorial_completed("room4_present") and hints.active_id == "room4_shift", "MetalLeft se registra antes de Shift")
	await capture("metal_left")
	var past_landed: bool = await jump(1, 2, 21, 5, 40)
	check(past_landed and progress.tutorial_completed("room4_shift") and progress.tutorial_completed("room4_past"), "Shift en vuelo y aterrizaje real completan el tutorial")
	check(hints.active_id.is_empty(), "No reaparecen avisos completados")
	if capture_enabled and past_landed:
		var on_rest: bool = await jump(2, 3, -1, 5, 40)
		if on_rest:
			shift()
			await create_timer(0.25).timeout
			var on_metal: bool = await jump(3, 4, -1, 5, 40)
			if on_metal and await jump(4, 5, 21, 5, 40) and await jump(5, 6, -1, 40, 40):
				await capture("future_exit")
	check(progress.load_progress() and progress.tutorial_completed("room4_shift") and progress.tutorial_completed("room4_present") and progress.tutorial_completed("room4_past"), "Continuar restaura los tres avisos")
	room.queue_free()
	await process_frame
	var revisit: Node2D = load("res://scenes/Room4.tscn").instantiate()
	root.add_child(revisit)
	await physics_frame
	await physics_frame
	check(revisit.get_node("TutorialHints").active_id.is_empty(), "Reingreso sin avisos repetidos")
	check(progress.new_game() and not progress.tutorial_completed("room4_shift") and not progress.tutorial_completed("room4_present") and not progress.tutorial_completed("room4_past"), "Nueva Partida reinicia avisos")
	progress.has_temporal_lens = true
	player = revisit.get_node("Player")
	manager = revisit.get_node("DimensionManager")
	Input.action_press(&"jump")
	for tick: int in range(16):
		await physics_frame
	shift()
	for tick: int in range(36):
		await physics_frame
	Input.action_release(&"jump")
	check(manager.active_dimension == 1 and support() == "EntryLedge" and not progress.tutorial_completed("room4_past"), "Shift en vuelo hacia apoyo compartido no completa Pasado")
	quit(0 if failures == 0 else 1)
