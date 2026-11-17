extends SceneTree

const ROOM_PATH: String = "res://scenes/Room5.tscn"
const OUTPUT: String = "res://artifacts/room5_stage_d"
const MANAGER_SCRIPT: Script = preload("res://DimensionManager.gd")

class ShiftProbe:
	extends Node
	var player: CharacterBody2D
	var position_before: Vector2
	var velocity_before: Vector2
	var physics_frame_before: int = -1

	func _physics_process(_delta: float) -> void:
		position_before = player.position
		velocity_before = player.velocity
		physics_frame_before = Engine.get_physics_frames()

var failures: int = 0
var checks: int = 0
var accepted: int = 0
var rejected: int = 0
var starts: int = 0
var ends: int = 0
var room: Node2D
var player: CharacterBody2D
var manager: Node
var lens: Control
var camera: Camera2D
var capture_enabled: bool = false
var requested_size: Vector2i = Vector2i(1280, 720)
var results: Array[Dictionary] = []
var trace: Array[Dictionary] = []
var recharge_frames: Dictionary = {}
var protection_frames: Dictionary = {}
var geometry_snapshot: Dictionary = {}
var camera_snapshot: Dictionary = {}
var request_position: Vector2
var request_velocity: Vector2
var request_pending: bool = false
var matrix_error_reported: bool = false
var start_frame: int = -1
var end_frame: int = -1
var end_cooldown: float = -1.0
var probe: ShiftProbe
var first_start_frame: int = -1
var first_cooldown_end_frame: int = -1


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	results.append({"pass": ok, "label": label})
	print(("PASS " if ok else "FAIL ") + label)


func mark(label: String) -> void:
	var state: Dictionary = {
		"label": label, "frame": Engine.get_process_frames(),
		"position": [player.position.x, player.position.y],
		"velocity": [player.velocity.x, player.velocity.y],
		"dimension": manager.active_dimension, "cooldown": manager.switch_cooldown_remaining,
		"protection": player.call("is_temporally_protected"),
		"protection_remaining": player.call("get_temporal_protection_remaining"),
		"support": support() if player.is_physics_processing() else "fixture_physics_paused",
		"accepted": accepted, "rejected": rejected,
	}
	trace.append(state)
	print("STATE ", JSON.stringify(state))


func sample() -> void:
	if not is_instance_valid(room):
		return
	var recharge: int = int(lens.get("recharge_frame"))
	var protection: int = int(lens.get("protection_frame"))
	if recharge >= 0:
		recharge_frames[recharge] = true
	if protection >= 0:
		protection_frames[protection] = true
	if first_start_frame >= 0 and first_cooldown_end_frame < 0 and manager.switch_cooldown_remaining == 0.0:
		first_cooldown_end_frame = Engine.get_process_frames()
	var present: bool = manager.active_dimension == 0
	var correct: bool = (
		room.get_node("Visuals/Present").visible == present
		and room.get_node("Visuals/Past").visible != present
		and room.get_node("Visuals/SharedPlatforms").visible
		and room.get_node("WorldCollision/PresentCollision/P1/Shape").disabled != present
		and room.get_node("WorldCollision/PastCollision/T1/Shape").disabled == present
	)
	for id: String in ["F0", "R1", "R2"]:
		correct = correct and not room.get_node("WorldCollision/SharedCollision/" + id + "/Shape").disabled
	if not correct and not matrix_error_reported:
		matrix_error_reported = true
		check(false, "Matriz visual/física coherente en cada paso observado")


func ticks(count: int) -> void:
	for tick: int in range(count):
		await physics_frame
		sample()


func support() -> String:
	if not player.is_on_floor():
		return ""
	for index: int in range(player.get_slide_collision_count()):
		var contact: KinematicCollision2D = player.get_slide_collision(index)
		if contact.get_normal().y < -0.9:
			return str(contact.get_collider().name)
	for offset: float in [0.0, -10.0, 10.0]:
		var feet: Vector2 = player.global_position + Vector2(offset, 20)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(feet - Vector2(0, 2), feet + Vector2(0, 3), 1)
		var hit: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.normal.y < -0.9:
			return str(hit.collider.name)
	return ""


func shift() -> void:
	request_position = player.position
	request_velocity = player.velocity
	request_pending = true
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.location = KEY_LOCATION_LEFT
	key.pressed = true
	Input.parse_input_event(key)
	key = InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.location = KEY_LOCATION_LEFT
	key.pressed = false
	Input.parse_input_event(key)
	mark("KEY_SHIFT request")


func observe_change(_present: bool) -> void:
	accepted += 1
	if accepted == 1:
		first_start_frame = Engine.get_process_frames()
	if request_pending:
		check(probe.physics_frame_before == Engine.get_physics_frames() and player.position.is_equal_approx(probe.position_before) and player.velocity.is_equal_approx(probe.velocity_before), "Shift confirmado conserva posición y velocidad exactas del paso físico observado")
	request_pending = false
	check(manager.switch_cooldown_remaining == 0.20 and player.call("is_temporally_protected"), "Confirmación inicia recarga 0,20 y protección real")
	check(camera_state() == camera_snapshot, "Shift conserva cámara, viewport y posición del HUD")
	mark("accepted")


func observe_rejection() -> void:
	rejected += 1
	check(player.position.is_equal_approx(request_position) and player.velocity.is_equal_approx(request_velocity), "Rechazo conserva posición y velocidad")
	check(manager.switch_cooldown_remaining == 0.0 and not player.call("is_temporally_protected"), "Rechazo sin cooldown ni protección")
	request_pending = false
	mark("rejected")


func observe_start(duration: float) -> void:
	starts += 1
	start_frame = Engine.get_process_frames()
	check(duration == 0.16, "Duración de protección recibida del Player = 0,16")


func observe_end() -> void:
	ends += 1
	end_frame = Engine.get_process_frames()
	end_cooldown = float(manager.get("switch_cooldown_remaining"))


func camera_state() -> Dictionary:
	return {
		"transform": camera.global_transform, "zoom": camera.zoom,
		"limits": Vector4i(camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom),
		"viewport": root.get_visible_rect(), "center": camera.get_screen_center_position(),
		"hud": (room.get_node("CombatHUD/HealthAnchor") as Control).get_global_transform_with_canvas(),
		"lens": lens.get_global_transform_with_canvas(),
	}


func geometry_state() -> Dictionary:
	var state: Dictionary = {}
	for node: Node in room.find_children("*", "StaticBody2D", true, false):
		var body: StaticBody2D = node as StaticBody2D
		state[str(room.get_path_to(body))] = [body.global_transform, body.collision_layer, body.collision_mask]
		for child: Node in body.get_children():
			if child is CollisionShape2D:
				var shape: CollisionShape2D = child as CollisionShape2D
				state[str(room.get_path_to(shape))] = [shape.shape.get_instance_id(), (shape.shape as RectangleShape2D).size, shape.global_transform, shape.one_way_collision]
			elif child is CollisionPolygon2D:
				var polygon: CollisionPolygon2D = child as CollisionPolygon2D
				state[str(room.get_path_to(polygon))] = [polygon.polygon, polygon.global_transform, polygon.disabled]
	for node: Node in room.get_node("Visuals").find_children("*", "Sprite2D", true, false):
		var sprite: Sprite2D = node as Sprite2D
		state[str(room.get_path_to(sprite))] = [sprite.global_transform, sprite.texture.get_instance_id(), sprite.offset, sprite.modulate]
	return state


func load_room() -> void:
	room = (load(ROOM_PATH) as PackedScene).instantiate() as Node2D
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player") as CharacterBody2D
	manager = room.get_node("DimensionManager")
	lens = room.get_node("CombatHUD/TemporalLensHUD") as Control
	camera = player.get_node("Camera2D") as Camera2D
	# Read-only instrumentation immediately before manager (-10), before Player (0).
	probe = ShiftProbe.new()
	probe.player = player
	probe.process_physics_priority = -11
	room.add_child(probe)
	manager.dimension_changed.connect(observe_change)
	manager.dimension_change_rejected.connect(observe_rejection)
	player.temporal_protection_started.connect(observe_start)
	player.temporal_protection_ended.connect(observe_end)
	await ticks(12)
	camera_snapshot = camera_state()
	geometry_snapshot = geometry_state()


func capture(label: String) -> void:
	if not capture_enabled:
		return
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	check(frame.get_size() == requested_size, "Captura con tamaño real " + str(requested_size))
	check(frame.save_png("%s/%s_%dx%d.png" % [OUTPUT, label, requested_size.x, requested_size.y]) == OK, "Render real " + label)


func walk_to(target: float) -> void:
	var direction: float = signf(target - player.position.x)
	var action: StringName = &"move_right" if direction > 0 else &"move_left"
	Input.action_press(action)
	for tick: int in range(400):
		await ticks(1)
		if (player.position.x - (target - direction * 12.0)) * direction >= 0:
			break
	Input.action_release(action)
	await ticks(12)
	check(absf(player.position.x - target) < 18 and player.is_on_floor(), "Caminar sin reposicionar hasta X=%.0f" % target)
	mark("walk")


func land_on(expected: String, budget: int = 100) -> void:
	var first_frame: int = Engine.get_process_frames()
	for tick: int in range(budget):
		await ticks(1)
		if support() == expected:
			break
	await ticks(8)
	check(support() == expected, "Aterrizaje físico sobre " + expected)
	mark("land " + expected + " elapsed=%.3fs" % (float(Engine.get_process_frames() - first_frame) / 60.0))


func jump_to(target: float, expected: String, change_tick: int = -1) -> void:
	var origin: String = support()
	var initial_frame: int = Engine.get_process_frames()
	var direction: float = signf(target - player.position.x)
	var action: StringName = &"move_right" if direction > 0 else &"move_left"
	var airborne: bool = false
	var highest_feet: float = player.position.y + 20
	if absf(target - player.position.x) > 1:
		Input.action_press(action)
	Input.action_press("jump")
	for tick: int in range(120):
		await ticks(1)
		highest_feet = minf(highest_feet, player.position.y + 20)
		if (player.position.x - target) * direction >= 0:
			Input.action_release(action)
		if not player.is_on_floor():
			airborne = true
		if tick == change_tick:
			check(not player.is_on_floor() and player.velocity.y < 0.0, "Shift solicitado durante ascenso real")
			shift()
		if tick == change_tick + 2 and change_tick >= 0:
			check(manager.active_dimension == 1, "Cambio aéreo a Pasado aceptado")
			await capture("05_air_shift")
		if airborne and player.is_on_floor():
			break
	Input.action_release(action)
	Input.action_release("jump")
	var flight: float = float(Engine.get_process_frames() - initial_frame) / 60.0
	await ticks(12)
	check(airborne and support() == expected, "%s → %s salto real; vuelo=%.3fs, pies mínimos=%.2f" % [origin, expected, flight, highest_feet])
	mark("jump " + origin + " -> " + expected)


func check_matrix(present: bool) -> void:
	check(manager.active_dimension == (0 if present else 1), "Dimensión confirmada " + ("Presente" if present else "Pasado"))
	check(room.get_node("Visuals/Present").visible == present and room.get_node("Visuals/Past").visible != present, "Fondo, arquitectura, sólidos y fantasmas del conjunto correcto")
	check(room.get_node("WorldCollision/PresentCollision/P1/Shape").disabled != present and room.get_node("WorldCollision/PastCollision/T1/Shape").disabled == present, "P1/T1 excluyentes")
	check(room.get_node("CombatHUD").get("is_present") == present, "Tema de salud sincronizado mediante API compartida")
	check(geometry_state() == geometry_snapshot, "Shapes, capas, cuerpos, contornos, texturas y transformaciones intactos")
	check(not matrix_error_reported, "Shared y matriz consistentes en todos los pasos observados")


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("phase_d_work"):
		push_error("C.O.R.E.-9: Perfil real rechazado. Mi memoria no es tu laboratorio.")
		quit(2)
		return
	capture_enabled = OS.get_cmdline_user_args().has("--capture")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--viewport="):
			var dimensions: PackedStringArray = argument.trim_prefix("--viewport=").split("x")
			requested_size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	if DisplayServer.get_name() == "headless":
		root.size = requested_size
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_size = requested_size
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var progress: Node = root.get_node("GameProgress")
	progress.set("has_temporal_lens", false)
	progress.set("has_cronal_sword", true)
	await load_room()
	check(manager.get_script() == MANAGER_SCRIPT and room.find_children("DimensionManager", "", true, false).size() == 1, "Único gestor compartido original")
	check(room.get_script().get_base_script().resource_path == "res://scripts/rooms/room2.gd", "Herencia room2 conservada")
	check(room.find_children("*", "CharacterBody2D", true, false).size() == 1 and player.scene_file_path == "res://scenes/Player.tscn", "Player original único")
	check(room.find_children("CombatHUD", "", true, false).size() == 1 and root.get_camera_2d() == camera and room.find_children("*", "Camera2D", true, false).size() == 1, "HUD y cámara únicos y activos")
	check(room.find_children("*", "StaticBody2D", true, false).size() == 7 and room.find_children("*", "Area2D", true, false).size() == 4 and room.get_node("RoomTransitions/ToRoom4").next_scene_path == "res://scenes/Room4.tscn" and not room.get_node("CoreGuardian").core_exposed, "Geometría y retorno conservados, núcleo del Guardián pasivo")
	var shape_ids: Dictionary = {}
	for shape: CollisionShape2D in manager.present_shapes + manager.past_shapes:
		shape_ids[shape.shape.get_instance_id()] = true
	for id: String in ["F0", "R1", "R2"]:
		shape_ids[room.get_node("WorldCollision/SharedCollision/" + id + "/Shape").shape.get_instance_id()] = true
	check(shape_ids.size() == 5, "Cinco Shape2D independientes")
	check_matrix(true)
	check(not lens.visible and manager.switch_cooldown_remaining == 0 and not player.call("is_temporally_protected"), "Sin Lente: HUD oculto, cooldown cero y sin protección inicial")
	shift()
	await ticks(4)
	check(accepted == 0 and rejected == 0 and manager.active_dimension == 0 and manager.switch_cooldown_remaining == 0 and starts == 0 and not lens.visible, "Shift físico sin Lente no activa nada")
	progress.set("has_temporal_lens", true)
	lens.call("sync_from_progress")
	check(lens.visible and lens.get("manager") == manager and lens.get_node("Status").text == "PRESENTE", "Lente real poseída: HUD enlazado y Presente disponible")
	check(lens.get_node("LensIcon").texture == lens.get("PRESENT_ICON"), "Icono disponible Presente")
	check(support() == "F0" and player.health == 3 and player.velocity == Vector2.ZERO, "Entrada estable sin alterar salud")
	var changed_connections: int = manager.get_signal_connection_list("dimension_changed").size()
	var rejected_connections: int = manager.get_signal_connection_list("dimension_change_rejected").size()
	check(changed_connections == 4 and rejected_connections == 2, "Observadores únicos: HUD temporal, tema de salud, núcleo y prueba")
	check(player.get_signal_connection_list("health_changed").size() == 1 and player.get_signal_connection_list("damage_taken").size() == 1, "Conexiones de salud heredadas sin duplicar")
	await capture("01_present_ready")
	shift()
	await ticks(2)
	check(accepted == 1 and starts == 1 and manager.active_dimension == 1, "Una pulsación acepta un único cambio")
	check_matrix(false)
	check(lens.get("protection_frame") >= 0 and lens.get_node("LensIcon").texture == lens.get("protection_frames")[lens.get("protection_frame")], "Destello HUD procede del estado real del Player")
	await capture("02_past_protected")
	player.call("take_damage", 1)
	var projectile: Area2D = (load("res://scenes/combat/EnemyProjectile.tscn") as PackedScene).instantiate()
	room.add_child(projectile)
	projectile.call("_on_body_entered", player)
	check(player.health == 3 and player.get("invulnerability_frames_remaining") == 0 and projectile.get("consumed"), "Daño normal y proyectil existente rechazados durante protección; prueba aislada")
	var original_start: int = start_frame
	shift()
	await ticks(2)
	check(accepted == 1 and starts == 1 and start_frame == original_start, "Shift durante cooldown no reinicia protección ni recarga")
	for pulse: int in range(4):
		shift()
		await ticks(1)
	check(accepted == 1 and starts == 1 and start_frame == original_start, "Ráfaga de Shift durante cooldown no duplica cambios ni señales")
	for tick: int in range(20):
		if not player.call("is_temporally_protected"):
			break
		await ticks(1)
	var measured_protection: float = float(end_frame - start_frame) / 60.0
	check(ends == 1 and absf(measured_protection - 0.16) <= 1.0 / 60.0 and end_cooldown > 0.0, "Protección medida %.4fs; termina antes de cooldown=%.4fs" % [measured_protection, end_cooldown])
	check(lens.get("protection_frame") == -1 and lens.get("recharge_frame") >= 0, "HUD vuelve a recarga tras terminar protección real")
	await capture("03_past_recharge")
	await ticks(18)
	check(manager.switch_cooldown_remaining == 0 and lens.get("recharge_frame") == -1 and lens.get_node("Status").text == "PASADO", "Recarga concluye y Pasado disponible")
	var measured_cooldown: float = float(first_cooldown_end_frame - first_start_frame) / 60.0
	check(absf(measured_cooldown - 0.20) <= 1.0 / 60.0 + 0.0001, "Cooldown medido %.4fs con reloj fijo de 60fps" % measured_cooldown)
	check(recharge_frames.size() == 6, "HUD recorrió los seis fotogramas existentes de recarga")
	check(lens.get_node("LensIcon").texture == lens.get("PAST_ICON"), "Icono disponible Pasado")
	shift()
	await ticks(18)
	check_matrix(true)
	check(lens.get_node("Status").text == "PRESENTE", "Cambio inverso restaura HUD Presente")
	mark("continuous_route_start")
	await walk_to(280)
	await jump_to(340, "R1")
	await walk_to(440)
	await jump_to(520, "P1")
	await capture("04_present_P1")
	var p1_origin: Vector2 = player.position
	shift()
	await ticks(4)
	check(manager.active_dimension == 1 and not player.is_on_floor() and player.velocity.y > 0 and player.position.y > p1_origin.y, "P1 desaparece: pérdida de apoyo y caída física sin reposición")
	await land_on("F0")
	await walk_to(760)
	await jump_to(820, "R2")
	check(manager.active_dimension == 1 and support() == "R2", "R2 sostiene al Player en Pasado")
	shift()
	await ticks(18)
	check(manager.active_dimension == 0 and support() == "R2", "R2 conserva apoyo al volver a Presente")
	await jump_to(player.position.x, "T1", 12)
	check(manager.active_dimension == 1 and support() == "T1", "Aterrizaje real sobre T1 activada durante el salto")
	await capture("06_past_T1")
	shift()
	await ticks(4)
	check(not player.is_on_floor() and player.velocity.y > 0, "T1 desaparece al regresar a Presente")
	await land_on("R2")
	Input.action_press("crouch_down")
	await ticks(8)
	Input.action_release("crouch_down")
	await land_on("F0")
	await walk_to(140)
	check(player.health == 3 and progress.get("has_cronal_sword") and progress.get("has_temporal_lens"), "Recorrido continuo conserva salud, espada y Lente")
	check_matrix(true)
	mark("continuous_route_end")
	# Additional Shared check uses movement, without teleporting the continuous route.
	await walk_to(280)
	await jump_to(340, "R1")
	shift()
	await ticks(18)
	check(manager.active_dimension == 1 and support() == "R1", "R1 permanece físicamente compartida en Pasado")
	Input.action_press("crouch_down")
	await ticks(8)
	Input.action_release("crouch_down")
	await land_on("F0")
	shift()
	await ticks(18)
	check_matrix(true)
	# Isolated occupancy fixtures start here. They are NOT counted as traversal.
	mark("isolated_occupancy_start")
	player.set_physics_process(false)
	player.position = Vector2(780, 490)
	player.velocity = Vector2(75, -20)
	var before_rejected: int = rejected
	shift()
	await ticks(3)
	check(rejected == before_rejected + 1 and manager.active_dimension == 0 and lens.get_node("Status").text.contains("CAMBIO BLOQUEADO"), "Ocupación de T1 one-way rechaza Pasado con feedback")
	await capture("07_rejected")
	check_matrix(true)
	player.position = Vector2(140, 600)
	player.velocity = Vector2.ZERO
	shift()
	await ticks(18)
	player.position = Vector2(580, 490)
	player.velocity = Vector2(-75, 20)
	before_rejected = rejected
	shift()
	await ticks(3)
	check(rejected == before_rejected + 1 and manager.active_dimension == 1 and lens.get_node("Status").text.contains("CAMBIO BLOQUEADO"), "Ocupación de P1 one-way rechaza Presente")
	check_matrix(false)
	player.position = Vector2(580, 480)
	player.velocity = Vector2.ZERO
	shift()
	await ticks(18)
	check(manager.active_dimension == 0 and lens.get_node("Status").text == "PRESENTE", "Contacto exacto de pies no se confunde con penetración; limpia rechazo")
	check(manager.get_signal_connection_list("dimension_changed").size() == changed_connections and manager.get_signal_connection_list("dimension_change_rejected").size() == rejected_connections, "Cambios sucesivos no duplican señales")
	check(camera_state() == camera_snapshot, "Cámara, encuadre y HUD intactos al final")
	check(lens.get("recharge_frame") == -1 and lens.get("protection_frame") == -1, "Sin efecto residual tras rechazos y cooldown")
	player.position = Vector2(140, 600)
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	await ticks(12)
	player.call("take_damage", 1)
	check(player.health == 2 and room.get_node("CombatHUD/HealthAnchor/HealthValue").text == "INTEGRIDAD  2/3" and not player.call("is_temporally_protected"), "Daño habitual: salud 2/3 sin protección temporal ficticia")
	await ticks(65)
	player.call("take_damage", 1)
	check(player.health == 1 and room.get_node("CombatHUD/HealthAnchor/HealthValue").text == "INTEGRIDAD  1/3", "Estado crítico 1/3 compartido")
	await ticks(65)
	player.call("take_damage", 1)
	check(player.health == 0 and room.get_node("CombatHUD/HealthAnchor/HealthValue").text == "INTEGRIDAD  0/3" and not player.call("is_temporally_protected"), "Derrota 0/3 usa señales heredadas y sin protección residual")
	var before_dead_shift: int = accepted
	shift()
	await ticks(2)
	check(accepted == before_dead_shift, "Shift con Player derrotado no cambia dimensión")
	room.queue_free()
	await process_frame
	await load_room()
	check(manager.active_dimension == 0 and manager.switch_cooldown_remaining == 0 and not player.call("is_temporally_protected"), "Instancia nueva: Presente, sin cooldown ni protección heredados")
	shift()
	await ticks(2)
	check(player.call("is_temporally_protected"), "Protección activa antes de cambio de instancia de prueba")
	room.queue_free()
	await process_frame
	await load_room()
	check(not player.call("is_temporally_protected") and lens.get("protection_frame") == -1 and lens.get("recharge_frame") == -1, "Cambio de instancia no conserva efectos temporales")
	check(not FileAccess.file_exists("user://progress_v1.json"), "Sin escrituras de progreso en perfil aislado")
	check(protection_frames.size() == 5, "HUD observó las cinco poses de protección existentes")
	var mode: String = "render" if capture_enabled else "physics"
	var file: FileAccess = FileAccess.open("%s/results_%dx%d_%s.json" % [OUTPUT, requested_size.x, requested_size.y, mode], FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "window": [requested_size.x, requested_size.y], "mode": mode, "accepted": accepted, "rejected": rejected, "recharge_frames": recharge_frames.keys(), "protection_frames": protection_frames.keys(), "results": results, "trace": trace}, "\t"))
	file.close()
	print("ROOM5_DIMENSION_RESULT checks=", checks, " failures=", failures, " accepted=", accepted, " rejected=", rejected)
	room.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
