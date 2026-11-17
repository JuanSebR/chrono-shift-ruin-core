extends SceneTree

var failures: int = 0
var checks: int = 0
var room: Node2D
var player: CharacterBody2D
var camera: Camera2D
var captures: bool = false
var requested_size: Vector2i = Vector2i(1280, 720)
var results: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	results.append({"pass": ok, "label": label})
	print(("PASS " if ok else "FAIL ") + label)


func ticks(count: int) -> void:
	for tick: int in range(count):
		await physics_frame


func support() -> String:
	if not player.is_on_floor():
		return ""
	for index: int in range(player.get_slide_collision_count()):
		var contact: KinematicCollision2D = player.get_slide_collision(index)
		if contact.get_normal().y < -0.9:
			return str(contact.get_collider().name)
	# Floor snapping can retain floor state without a slide contact while touching a wall.
	for offset: float in [0.0, -10.0, 10.0]:
		var feet: Vector2 = player.global_position + Vector2(offset, 20)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(feet - Vector2(0, 2), feet + Vector2(0, 3), 1)
		var hit: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.normal.y < -0.9:
			return str(hit.collider.name)
	return ""


func capture(label: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	check(frame.get_size() == requested_size, "Render físico de " + str(requested_size))
	var target: String = "res://artifacts/room5_stage_c/%s_%dx%d.png" % [label, frame.get_width(), frame.get_height()]
	check(frame.save_png(target) == OK, "Captura real " + label)


func walk_to(target: float, budget: int = 400) -> void:
	var direction: float = signf(target - player.position.x)
	var action: StringName = &"move_right" if direction > 0 else &"move_left"
	Input.action_press(action)
	for tick: int in range(budget):
		await physics_frame
		if (player.position.x - (target - 12.0 * direction)) * direction >= 0.0:
			break
	Input.action_release(action)
	await ticks(12)
	var grounded_correctly: bool = support() == "F0" if player.position.y > 580.0 else player.is_on_floor()
	check(absf(player.position.x - target) < 18.0 and grounded_correctly, "Movimiento real hacia X=%.0f; posición=%s apoyo=%s" % [target, player.position, support()])


func jump_to(target_x: float, expected: String) -> void:
	var from: String = support()
	var origin: Vector2 = player.position
	var action: StringName = &"move_right" if target_x > player.position.x else &"move_left"
	var direction: float = 1.0 if target_x > player.position.x else -1.0
	var airborne: bool = false
	Input.action_press(action)
	Input.action_press("jump")
	for tick: int in range(130):
		await physics_frame
		if (player.position.x - target_x) * direction >= 0:
			Input.action_release(action)
		if not player.is_on_floor():
			airborne = true
		if airborne and player.is_on_floor():
			break
	Input.action_release(action)
	Input.action_release("jump")
	await ticks(12)
	check(airborne and support() == expected, "%s → %s salto real: %s → %s; cuerpo=%s" % [from, expected, origin, player.position, support()])


func _run() -> void:
	# APPDATA must point outside the real Godot profile before this process starts.
	if not OS.get_user_data_dir().replace("\\", "/").contains("phase_c_work"):
		push_error("C.O.R.E.-9: Perfil de pruebas sin aislar. No pienso ensuciar otro guardado.")
		quit(2)
		return
	print("ISOLATED_PROFILE ", OS.get_user_data_dir())
	captures = OS.get_cmdline_user_args().has("--capture")
	# Headless Window has no physical display; explicitly reproduce the requested viewport.
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--viewport="):
			var dimensions: PackedStringArray = argument.trim_prefix("--viewport=").split("x")
			requested_size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	if DisplayServer.get_name() == "headless":
		root.size = requested_size
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_size = requested_size
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/room5_stage_c"))
	var progress: Node = root.get_node("GameProgress")
	progress.set("has_cronal_sword", true)
	progress.set("has_temporal_lens", true)
	var packed: PackedScene = load("res://scenes/Room5.tscn") as PackedScene
	check(packed != null and packed.can_instantiate(), "Room5 y recursos cargan")
	if packed == null:
		quit(1)
		return
	room = packed.instantiate() as Node2D
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player") as CharacterBody2D
	camera = player.get_node("Camera2D") as Camera2D
	check(player.position == Vector2(140, 600) and player.velocity == Vector2.ZERO, "Spawn y velocidad inicial")
	check(not (player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h, "Orientación derecha")
	check(room.find_children("*", "CharacterBody2D", true, false).size() == 1, "Player único original")
	check(room.find_children("*", "Camera2D", true, false).size() == 1 and root.get_camera_2d() == camera, "Cámara única activa")
	check(room.find_children("CombatHUD", "", true, false).size() == 1, "CombatHUD único")
	check(room.get_node("Visuals/Present").visible and not room.get_node("Visuals/Past").visible, "Presente inicial / Pasado preparado oculto")
	check(room.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Nearest local")
	var scale_factor: float = 1280.0 / 1672.0
	for dimension: String in ["Present", "Past"]:
		var background: Sprite2D = room.get_node("Visuals/" + dimension + "/Background")
		var architecture: Sprite2D = room.get_node("Visuals/" + dimension + "/Architecture")
		check(background.scale.is_equal_approx(Vector2.ONE * scale_factor) and background.position == Vector2.ZERO and architecture.transform == background.transform, dimension + " fondo/marco uniformes y alineados")
		check(background.texture.get_size() == Vector2(1672, 941) and architecture.texture.get_image().get_pixel(836, 470).a < 0.01, dimension + " fondo completo, contorno transparente sin tapón opaco")
		for id: String in ["P1", "T1"]:
			var visual: Sprite2D = room.get_node("Visuals/" + dimension + "/" + id)
			check(visual.texture is AtlasTexture and visual.texture.get_image().get_pixel(0, 0).a == 0.0, dimension + "/" + id + " atlas RGBA válido")
	var geometry: Dictionary = {"F0": Vector3(80, 1200, 620), "R1": Vector3(300, 460, 560), "R2": Vector3(780, 940, 560), "P1": Vector3(500, 660, 500), "T1": Vector3(700, 860, 500)}
	var identities: Dictionary = {}
	for id: String in geometry:
		var group: String = "PresentCollision" if id == "P1" else ("PastCollision" if id == "T1" else "SharedCollision")
		var body: StaticBody2D = room.get_node("WorldCollision/" + group + "/" + id)
		var shape: CollisionShape2D = body.get_node("Shape")
		var rectangle: RectangleShape2D = shape.shape as RectangleShape2D
		var spec: Vector3 = geometry[id]
		identities[rectangle.get_instance_id()] = true
		check(rectangle.size == Vector2(spec.y - spec.x, 8) and shape.global_position == Vector2((spec.x + spec.y) * 0.5, spec.z + 4) and body.global_scale == Vector2.ONE, id + " cotas sin escala física")
		check(body.collision_layer == 1 and body.collision_mask == 0 and shape.disabled == (id == "T1") and shape.one_way_collision == (id != "F0"), id + " capa/estado/tipo de apoyo")
	check(identities.size() == 5, "Cinco Shape2D independientes")
	check(room.get_node("Visuals").find_children("*", "CollisionObject2D", true, false).is_empty() and room.find_children("*", "StaticBody2D", true, false).size() == 7, "Solo cinco superficies y dos contornos físicos; decoraciones sin colisión")
	check(player.collision_layer == 2 and player.collision_mask == 1, "Máscaras originales del Player")
	check(Vector4i(camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom) == Vector4i(0, 0, 1280, 720), "Límites cámara 1280×720")
	await ticks(15)
	check(support() == "F0" and player.position.distance_to(Vector2(140, 600)) < 0.5 and player.velocity == Vector2.ZERO, "Apoyo estable real F0")
	check(player.get("health") == 3, "Salud inicial de tres células")
	Input.action_press("crouch_down")
	await ticks(20)
	Input.action_release("crouch_down")
	await ticks(2)
	check(support() == "F0" and player.position.y < 601, "Descender no atraviesa F0 firme")
	var viewport_size: Vector2 = root.get_visible_rect().size
	check(root.size == requested_size if captures else viewport_size == Vector2(requested_size), "Resolución efectiva solicitada " + str(requested_size))
	print("WINDOW physical=", root.size, " logical=", viewport_size, " content_scale=", root.content_scale_size, " stretch=", root.get_stretch_transform())
	var expected_zoom: float = maxf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	check(camera.zoom.is_equal_approx(Vector2.ONE * expected_zoom) and camera.get_screen_center_position().distance_to(Vector2(640, 360)) < 0.1, "Viewport=%s zoom=%s centro=%s" % [viewport_size, camera.zoom, camera.get_screen_center_position()])
	var effective_zoom: float = camera.zoom.x * root.get_stretch_transform().x.length()
	var target_zoom: float = float(requested_size.x) / 1280.0
	check(is_equal_approx(effective_zoom, target_zoom), "Zoom efectivo en píxeles=%.3f" % effective_zoom)
	var boss: Marker2D = room.get_node("EntryMarkers/FutureBossSpawn")
	check(boss.position == Vector2(1070, 620) and boss.get_child_count() == 0, "Solo marcador del jefe con espacio de 194,25px")
	check(Rect2(Vector2.ZERO, viewport_size).has_point(boss.get_global_transform_with_canvas().origin), "Futuro apoyo del jefe dentro del encuadre")
	var lens: Control = room.get_node("CombatHUD/TemporalLensHUD")
	check(lens.visible and lens.get("manager") == room.get_node("DimensionManager") and lens.get("recharge_frame") == -1 and lens.get_node("Status").text == "PRESENTE", "Lente poseída y HUD dinámico disponible")
	var hud_position: Vector2 = (room.get_node("CombatHUD/HealthAnchor") as Control).get_global_transform_with_canvas().origin
	await capture("01_general_spawn_hud")
	await walk_to(280)
	await jump_to(340, "R1")
	await capture("02_R1")
	await walk_to(440)
	await jump_to(520, "P1")
	await capture("03_P1")
	Input.action_press("crouch_down")
	await ticks(8)
	Input.action_release("crouch_down")
	await ticks(45)
	check(support() == "F0", "P1 → F0 mediante descenso real compatible")
	await walk_to(760)
	await jump_to(820, "R2")
	await capture("04_R2")
	var airborne: bool = false
	var min_feet: float = player.position.y + 20.0
	Input.action_press("jump")
	for tick: int in range(90):
		await physics_frame
		min_feet = minf(min_feet, player.position.y + 20.0)
		if not player.is_on_floor():
			airborne = true
		if airborne and player.is_on_floor():
			break
	Input.action_release("jump")
	await ticks(10)
	check(airborne and min_feet < 490 and support() == "R2", "T1 atravesada desde abajo y arriba; pies mínimos=%.2f, aterrizaje R2" % min_feet)
	Input.action_press("crouch_down")
	await ticks(8)
	Input.action_release("crouch_down")
	await ticks(35)
	check(support() == "F0", "R2 → F0 descenso real")
	await walk_to(1070)
	await capture("05_future_boss")
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	check(player.get("presentation") == &"attack", "Ataque original disponible en F0")
	await ticks(45)
	var before_shift: Vector2 = player.position
	var event: InputEventAction = InputEventAction.new()
	event.action = &"dimension_shift"
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(20)
	event = InputEventAction.new()
	event.action = &"dimension_shift"
	event.pressed = false
	Input.parse_input_event(event)
	check(not room.get_node("Visuals/Present").visible and room.get_node("Visuals/Past").visible and not room.get_node("WorldCollision/PastCollision/T1/Shape").disabled and player.position.distance_to(before_shift) < 0.1, "Shift real cambia a Pasado conservando posición")
	room.get_node("DimensionManager").call("restore_present_at_checkpoint")
	room.get_node("RoomTransitions/ToRoom4").set_deferred("monitoring", false)
	for action: StringName in [&"move_right", &"move_left"]:
		Input.action_press(action)
		await ticks(340)
		Input.action_release(action)
		await ticks(12)
		print("BOUND_CONTACT floor=", player.is_on_floor(), " support=", support(), " velocity=", player.velocity)
		for index: int in range(player.get_slide_collision_count()):
			var contact: KinematicCollision2D = player.get_slide_collision(index)
			print("  ", contact.get_collider().name, " normal=", contact.get_normal(), " point=", contact.get_position())
		check(support() == "F0" and player.position.x > 68 and player.position.x < 1213, str(action) + " límite visible estable: " + str(player.position) + " apoyo=" + support())
		var screen_position: Vector2 = player.get_global_transform_with_canvas().origin
		check(Rect2(Vector2.ZERO, viewport_size).has_point(screen_position), "Player visible en " + str(action))
		await capture("06_right_limit" if action == &"move_right" else "07_left_limit")
		Input.action_press(action)
		Input.action_press("jump")
		await ticks(65)
		Input.action_release("jump")
		Input.action_release(action)
		await ticks(15)
		check(player.is_on_floor() and player.position.y < 601 and player.position.x > 60 and player.position.x < 1220, "Salto contra contorno visible estable " + str(action) + " posición=" + str(player.position) + " apoyo=" + support())
		await walk_to(1120 if action == &"move_right" else 140)
		await ticks(25)
		check(support() == "F0", "Regreso desde moldura visible a F0 " + str(action))
	await walk_to(140)
	check(support() == "F0", "Regreso físico al spawn")
	check((room.get_node("CombatHUD/HealthAnchor") as Control).get_global_transform_with_canvas().origin == hud_position, "HUD fijo tras recorrido completo")
	check(room.find_children("DimensionManager", "", true, false).size() == 1 and room.find_children("*", "Area2D", true, false).size() == 4 and room.get_node("RoomTransitions/ToRoom4").next_scene_path == "res://scenes/Room4.tscn" and not room.get_node("CoreGuardian").core_exposed, "Gestor único, retorno real y núcleo pasivo autorizado")
	progress.set("has_temporal_lens", false)
	lens.call("sync_from_progress")
	check(not lens.visible, "Lente ausente se oculta sin inventar posesión")
	Input.parse_input_event(event)
	await ticks(4)
	check(room.get_node("DimensionManager").active_dimension == 0, "Sin Lente no cambia dimensión")
	progress.set("has_temporal_lens", true)
	lens.call("sync_from_progress")
	player.call("take_damage", 1)
	await ticks(5)
	check(room.get_node("CombatHUD/HealthAnchor/HealthValue").text == "INTEGRIDAD  2/3", "HUD sincroniza daño real")
	player.set("invulnerability_frames_remaining", 0)
	player.call("take_damage", 1)
	await ticks(5)
	check(room.get_node("CombatHUD/HealthAnchor/HealthValue").text == "INTEGRIDAD  1/3", "HUD conserva estado crítico")
	await capture("08_hud_critical")
	# Exercise the existing ephemeral handoff without creating a transition or a save.
	progress.call("prepare_room_arrival", "res://scenes/Room5.tscn", &"EntryMarkers/FutureFromRoom4", player)
	room.queue_free()
	await process_frame
	room = packed.instantiate() as Node2D
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	check(player.position == Vector2(180, 600) and player.get("health") == 1 and player.velocity == Vector2.ZERO and progress.get("has_cronal_sword") and progress.get("has_temporal_lens"), "Llegada futura conserva salud/progreso con contrato existente")
	check(not FileAccess.file_exists("user://progress_v1.json"), "Prueba no escribió progreso ni siquiera en perfil aislado")
	var report: FileAccess = FileAccess.open("res://artifacts/room5_stage_c/results_%dx%d%s.json" % [requested_size.x, requested_size.y, "_render" if captures else "_physics"], FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks": checks, "failures": failures, "requested_window": [requested_size.x, requested_size.y], "logical_viewport": [viewport_size.x, viewport_size.y], "results": results}, "\t"))
	report.close()
	print("ROOM5_RESULT checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
