extends "res://tests/room4_route_test.gd"

var awards: int = 0

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var target: String = "res://artifacts/room5_stage_e"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target))
	var frame: Image = root.get_texture().get_image()
	frame.save_png("%s/%s_%dx%d.png" % [target, label, frame.get_width(), frame.get_height()])

func _run() -> void:
	await execute(false)

func execute(cycles: bool) -> void:
	if not OS.get_user_data_dir().contains("phase_d_work"):
		quit(2)
		return
	var progress: Node = root.get_node("GameProgress")
	progress.new_game()
	check(not progress.has_reactor_key, "Nueva Partida sin llave")
	var old: FileAccess = FileAccess.open("user://progress_v1.json", FileAccess.WRITE)
	old.store_string(JSON.stringify({"version":1,"has_cronal_sword":true,"has_temporal_lens":true,"completed_dialogues":{"old":true}}))
	old.close()
	progress.load_progress()
	check(not progress.has_reactor_key and progress.has_temporal_lens and progress.has_cronal_sword and progress.dialogue_completed("old"), "v1 antiguo conserva posesiones y diálogo sin llave")
	progress.reactor_key_acquired.connect(func() -> void: awards += 1)
	var fixture: Node2D = load("res://scenes/Room4.tscn").instantiate()
	root.add_child(fixture)
	var fixture_player: CharacterBody2D = fixture.get_node("Player")
	fixture_player.position = Vector2(1188, 200)
	await create_timer(0.05).timeout
	check(not progress.has_reactor_key, "En el aire no concede llave")
	fixture_player.position = Vector2(1188, 340)
	await create_timer(0.05).timeout
	check(not progress.has_reactor_key, "Pasar debajo no concede llave")
	fixture_player.position = Vector2(1188, 264)
	fixture_player.velocity = Vector2.ZERO
	await create_timer(0.1).timeout
	check(not progress.has_reactor_key, "Colocación artificial sobre repisa no concede llave")
	fixture.queue_free()
	await process_frame
	var room: Node2D = load("res://scenes/Room4.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	await create_timer(0.2).timeout
	check(not progress.has_reactor_key and not room.get_node("RoomTransitions/ToRoom5").monitoring, "Spawn no concede llave ni habilita acceso")
	for from: int in range(6):
		if from == 3:
			shift()
			await create_timer(0.25).timeout
		check(await jump(from, from + 1, 21 if from in [1,4] else -1, 5.0, 40), "Recorrido físico tramo " + str(from))
	await create_timer(0.05).timeout
	check(progress.has_reactor_key and awards == 1 and room.key_notice_remaining > 0, "Contacto final concede y notifica una sola vez")
	await capture("key_exit_ledge")
	var saved: String = FileAccess.get_file_as_string("user://progress_v1.json")
	await create_timer(0.2).timeout
	check(saved == FileAccess.get_file_as_string("user://progress_v1.json") and awards == 1, "Sin guardados repetidos")
	progress.has_reactor_key = false
	progress.load_progress()
	check(progress.has_reactor_key, "Continuar restaura llave")
	if cycles:
		player.health = 2
		for cycle: int in range(3):
			await travel("move_right", "Room5")
			check(player.position.distance_to(Vector2(180,600)) < 1 and player.health == 2 and manager.active_dimension == 0 and not player.is_temporally_protected(), "Llegada Room5 segura, salud y dimensión")
			await capture("room5_arrival")
			await create_timer(0.1).timeout
			shift()
			await create_timer(0.25).timeout
			await travel("move_left", "Room4")
			check(player.position.distance_to(Vector2(1160,264)) < 1 and player.health == 2 and manager.active_dimension == 0 and current_scene.checkpoint.name == &"Spawn", "Regreso seguro con checkpoint inicial")
			await capture("room4_return")
			await create_timer(0.1).timeout
			check(current_scene.name == &"Room4" and awards == 1 and progress.has_reactor_key, "Sin bucle ni readquisición ciclo " + str(cycle))
		var recovered: Array[bool] = [false]
		current_scene.fall_recovered.connect(func() -> void: recovered[0] = true)
		Input.action_press("move_left")
		for tick: int in range(180):
			await physics_frame
			if recovered[0]:
				break
		Input.action_release("move_left")
		check(recovered[0] and current_scene.checkpoint.name == &"Spawn" and player.health == 2 and progress.has_reactor_key, "Caída tras regreso recupera checkpoint inicial conservando progreso")
	else:
		player.health = 0
		player.defeated.emit()
		check(progress.has_reactor_key, "Derrota conserva llave")
	check(progress.new_game() and not progress.has_reactor_key, "Nueva Partida restablece llave")
	print("REACTOR_RESULT failures=", failures)
	quit(0 if failures == 0 else 1)

func travel(action: String, destination: String) -> void:
	Input.action_press(action)
	for tick: int in range(300):
		await physics_frame
		if current_scene != null and current_scene.name == destination:
			break
	Input.action_release(action)
	check(current_scene != null and current_scene.name == destination, "Transición real a " + destination)
	player = current_scene.get_node("Player")
	manager = current_scene.get_node("DimensionManager")
	check(current_scene.find_children("*", "CharacterBody2D", true, false).size() == 1 and current_scene.find_children("CombatHUD", "", true, false).size() == 1, "Player y HUD únicos")
