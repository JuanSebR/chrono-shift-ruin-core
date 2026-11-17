extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var directory: String = "res://artifacts/room4_stage_g"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var image: Image = root.get_texture().get_image()
	check(image.save_png("%s/%s_%dx%d.png" % [directory, label, image.get_width(), image.get_height()]) == OK, label)

func _run() -> void:
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 720) if "1280" in OS.get_cmdline_user_args() else Vector2i(1024, 572)
	var progress: Node = root.get_node("GameProgress")
	progress.has_temporal_lens = false
	progress.has_cronal_sword = true
	change_scene_to_file("res://scenes/Room3.tscn")
	await scene_changed
	var room: Node2D = current_scene
	var player: CharacterBody2D = room.get_node("Player")
	player.position = Vector2(1630, 703)
	await ticks(8)
	check(current_scene == room and not room.get_node("RoomTransitions/ToRoom4").monitoring, "Acceso cerrado sin Lente")
	player.position = Vector2(1150, 703)
	await ticks(8)
	var event: InputEventAction = InputEventAction.new()
	event.action = &"dialogue_advance"
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(10)
	check(room.acquisition_running and not room.get_node("RoomTransitions/ToRoom4").monitoring, "Salida cerrada durante la adquisición")
	await ticks(90)
	check(progress.has_temporal_lens and not room.acquisition_running and room.get_node("RoomTransitions/ToRoom4").monitoring, "Adquisición real abre la salida")
	player.health = 2
	player.health_changed.emit(2)
	Input.action_press(&"jump")
	Input.action_press(&"move_right")
	await ticks(38)
	Input.action_release(&"jump")
	check(player.position.x > 1213, "Paso real por encima del pedestal")
	for index: int in range(150):
		if player.position.x >= 1540 or current_scene != room:
			break
		await physics_frame
	if current_scene != room or player.position.x < 1540:
		Input.action_release(&"move_right")
		check(false, "Acceso derecho alcanzable")
		quit(1)
		return
	Input.action_release(&"move_right")
	await ticks(10)
	await capture("room3_access")
	Input.action_press(&"move_right")
	for index: int in range(150):
		if current_scene != room:
			break
		await physics_frame
	Input.action_release(&"move_right")
	await ticks(6)
	check(current_scene != null and current_scene.name == &"Room4", "Llegada real desde Room3")
	if current_scene == null or current_scene.name != &"Room4":
		quit(1)
		return
	room = current_scene
	player = room.get_node("Player")
	check(player.is_on_floor() and player.health == 2 and progress.has_cronal_sword and progress.has_temporal_lens, "Apoyo y progreso conservados")
	check(room.checkpoint.name == &"Spawn" and room.get_node("DimensionManager").active_dimension == 0, "Checkpoint y Presente iniciales")
	await capture("room4_entry")
	event = InputEventAction.new()
	event.action = &"dimension_shift"
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(6)
	check(room.get_node("DimensionManager").active_dimension == 1, "Salida desde Pasado")
	Input.action_press(&"move_left")
	await scene_changed
	Input.action_release(&"move_left")
	room = current_scene
	player = room.get_node("Player")
	check(room.name == &"Room3" and player.position == Vector2(1570, 703) and player.velocity == Vector2.ZERO, "Marcador y velocidad inmediatos de regreso")
	check(player.get_node("AnimatedSprite2D").flip_h and not room.get_node("TemporalModule/ModuleVisual").visible and player.health == 2, "Regreso orientado al interior con pedestal vacío")
	await ticks(10)
	await capture("room3_return")
	Input.action_press(&"move_right")
	await scene_changed
	Input.action_release(&"move_right")
	room = current_scene
	player = room.get_node("Player")
	check(room.name == &"Room4" and player.position == Vector2(64, 396) and player.velocity == Vector2.ZERO, "Reingreso inmediato en marcador")
	check(room.checkpoint.name == &"Spawn" and not player.get_node("AnimatedSprite2D").flip_h, "Orientación y checkpoint al reingresar")
	await ticks(20)
	check(current_scene == room and room.get_node("CombatHUD/TemporalLensHUD/Status").text == "PRESENTE", "Sin rebote y HUD en Presente")
	quit(0 if failures == 0 else 1)
