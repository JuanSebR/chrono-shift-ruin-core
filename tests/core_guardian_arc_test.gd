extends SceneTree

var checks: int = 0
var failures: int = 0
var room: Node2D
var player: CharacterBody2D
var boss: Node2D
var arc: Node2D
var manager: Node
var captures: bool = false
var poses: Array[int] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame
		if is_instance_valid(boss) and boss.arc_running:
			var pose: int = boss.sprite.frame
			if not poses.has(pose):
				poses.append(pose)

func until_age(age: float) -> void:
	for index: int in range(400):
		if boss.beam_elapsed >= age:
			return
		await ticks(1)
	check(false, "Reloj alcanza " + str(age))

func idle() -> void:
	for index: int in range(400):
		if not boss.arc_running and not boss.beam_running:
			return
		await ticks(1)
	check(false, "Acción finaliza sin bloqueo")

func shift() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.location = KEY_LOCATION_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.location = KEY_LOCATION_LEFT
	event.pressed = false
	Input.parse_input_event(event)

func capture(label: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var directory: String = "res://artifacts/room5_stage_h2"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	check(image.save_png("%s/%s_%dx%d.png" % [directory,label,image.get_width(),image.get_height()]) == OK, "Render real " + label)

func fixture(position: Vector2, past: bool = false) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	manager.restore_present_at_checkpoint()
	player.set_physics_process(true)
	player.position = position
	player.velocity = Vector2.ZERO
	player.health = 3
	player.invulnerability_frames_remaining = 0
	player.health_changed.emit(3)
	if past:
		shift()
	await ticks(20)

func impact(position: Vector2, label: String, past: bool = false) -> void:
	await fixture(position, past)
	var contacts_before: int = arc.contacts
	boss.request_arc()
	await idle()
	check(player.health == 2 and arc.contacts == contacts_before + 1, "Impacto físico único " + label)

func evade(x: float, direction: String, jumping: bool = false) -> bool:
	await fixture(Vector2(x,600))
	boss.request_arc()
	await until_age(0.30)
	var fixed_target: Vector2 = boss.arc_target
	if not jumping:
		Input.action_press(direction)
	else:
		var t: float = maxf(0.45, 2.0 * maxf(arc.p0.distance_to(arc.p1), arc.p1.distance_to(arc.p2)) / 1400.0)
		await until_age(1.0 + t - (0.50 if x > 1070.0 else 0.28))
		Input.action_press("jump")
	for index: int in range(300):
		if not boss.arc_running:
			break
		await ticks(1)
		if captures and x == 600.0 and jumping and boss.arc_emitted and arc.last_age > arc.duration * 0.65 and arc.last_age < arc.duration * 0.72:
			await capture("08_evasion_salto_F0")
	Input.action_release(direction)
	Input.action_release("jump")
	var safe: bool = player.health == 3
	print("EVASION x=",x," jump=",jumping," end=",player.position," hp=",player.health," target=",fixed_target," fixed=",arc.p2 == fixed_target)
	if not safe:
		print("LIMITATION contact=",arc.last_contact_position," flight_age=",arc.finish_age," duration=",arc.duration)
	check(arc.p2 == fixed_target, "Objetivo inmutable durante evasión " + str(x))
	return safe

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_h2_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	root.get_node("GameProgress").has_temporal_lens = true
	root.get_node("GameProgress").has_cronal_sword = true
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	boss = room.get_node("CoreGuardian")
	arc = boss.get_node("ArcAttack")
	manager = room.get_node("DimensionManager")
	# Only this fixture instance: prevents edge placement from loading Room4.
	for node: Node in room.get_children():
		if node is Area2D and node.get_script() == load("res://LevelTransition.gd"):
			(node as Area2D).set_deferred("monitoring", false)
	await ticks(20)
	check(boss.state == boss.State.IDLE and not arc.visible and not boss.arc_running, "Carga pasiva sin IA")
	await fixture(Vector2(400,600))
	await capture("01_idle_Repose")
	var initial: Vector2 = player.get_node("CollisionShape2D").global_position
	check(boss.request_arc() and not boss.request_arc() and not boss.request_beam(), "Solicitud exclusiva; haz y duplicación rechazados")
	check(boss.arc_target.distance_to(initial) < 0.1 and boss.arc_direction == -1.0 and boss.sprite.flip_h, "Centro físico y orientación izquierda")
	check(boss.arc_frames.get_frame_count(&"attack3") == 6, "Attack3 carga sus seis poses originales")
	Input.action_press("move_right")
	await ticks(8)
	check(boss.arc_target.x > initial.x and absf(boss.arc_target.y - initial.y) < 1.0 and arc.warning and not arc.locked, "Seguimiento inicial y aviso sin daño")
	await capture("02_tracking_Attack3_pose0")
	await until_age(0.30)
	var fixed: Vector2 = boss.arc_target
	await until_age(0.60)
	check(boss.arc_target == fixed and player.position.x > fixed.x and player.health == 3 and arc.locked, "Fijación a 0.25s: movimiento posterior no reajusta ni daña")
	await capture("03_fixed_pose1")
	Input.action_release("move_right")
	await until_age(1.01)
	check(arc.emissions == 1 and boss.sprite.frame == 2 and not arc.warning, "Emisión única al entrar pose 2")
	check(arc.p0.distance_to(Vector2(1018.106375,537.2765)) < 0.02 and arc.p1 == arc.p0 + Vector2(-60,0), "Boca transformada izquierda y tangente inicial")
	check(arc.packet.scale == Vector2(0.75,0.75) and arc.circle.radius == 8.0, "Escala uniforme .75 y círculo radio8")
	var expected: float = maxf(.45,2.0 * maxf(arc.p0.distance_to(arc.p1),arc.p1.distance_to(arc.p2))/1400.0)
	check(is_equal_approx(arc.duration,expected) and arc.point(.5).distance_to(arc.p0.lerp(arc.p2,.5)) > 5.0, "Curva cuadrática y duración calculada")
	await capture("04_release_pose2")
	var origin: Vector2 = arc.p0
	await ticks(9)
	check(arc.p0 == origin and arc.emissions == 1 and boss.sprite.frame == 3, "Retroceso no arrastra origen ni duplica paquete")
	await capture("05_flight_pose3")
	await idle()
	check(poses == [0,1,2,3,4,5], "Seis poses en orden, un solo reloj")
	check(not is_instance_valid(arc.packet) and boss.sprite.sprite_frames == boss.base_frames and boss.sprite.flip_h, "Limpieza y retorno al Repose seguro")
	await impact(Vector2(400,600), "F0 Presente")
	await impact(Vector2(380,540), "R1")
	await impact(Vector2(860,540), "R2")
	await impact(Vector2(580,480), "P1 Presente")
	await impact(Vector2(780,480), "T1 Pasado", true)
	await impact(Vector2(400,600), "F0 Pasado", true)
	await impact(Vector2(1049,600), "proximidad izquierda al cuerpo")
	await impact(Vector2(1100,600), "proximidad derecha al cuerpo")
	await fixture(Vector2(600,600))
	Input.action_press("jump")
	await ticks(8)
	boss.request_arc()
	await until_age(.30)
	var airborne_target: Vector2 = boss.arc_target
	await until_age(.80)
	check(airborne_target.y < 570 and boss.arc_target == airborne_target, "Objetivo aéreo conserva Y real aunque Player descienda")
	Input.action_release("jump")
	boss.cancel_arc()
	await fixture(Vector2(400,600))
	player.set_physics_process(false)
	await ticks(2)
	var swept: Dictionary = arc.sweep(Vector2(360,600),Vector2(440,600))
	check(not swept.is_empty() and swept.get("body") == player and float(swept.get("fraction",1.0)) > 0.0 and float(swept.get("fraction",1.0)) < 1.0, "Barrido radio8 detecta Player aunque ambos extremos estén fuera")
	await impact(Vector2(80,600), "extremo izquierdo (fixture aislado)")
	await impact(Vector2(1200,600), "extremo derecho (fixture aislado)")
	await fixture(Vector2(1150,600))
	boss.request_arc()
	await until_age(.60)
	await capture("14_derecha_aviso")
	await until_age(1.01)
	check(boss.arc_direction == 1.0 and not boss.sprite.flip_h and arc.p0.distance_to(Vector2(1121.893625,537.2765)) < .02, "Player detrás: espejo derecho y boca correspondiente")
	await capture("15_derecha_emision")
	await idle()
	check(player.health == 2 and boss.sprite.flip_h, "Impacto derecho y restauración izquierda")
	await fixture(Vector2(400,600))
	boss.request_arc()
	await until_age(1.01)
	await until_age(1.0 + arc.duration * .75)
	var before_age: float = arc.last_age
	var frozen: Vector2 = arc.p2
	shift()
	await ticks(2)
	check(manager.active_dimension == 1 and player.is_temporally_protected() and arc.last_age > before_age and arc.p2 == frozen, "Shift válido protege sin reiniciar trayectoria")
	await capture("09_Pasado_proteccion")
	var contact_before: int = arc.contacts
	for index: int in range(80):
		if arc.contacts > contact_before:
			break
		await ticks(1)
	check(arc.consumed and arc.contacts == contact_before + 1 and player.health == 3, "Contacto temporal protegido consume paquete sin daño")
	await capture("10_contacto_protegido_disipacion")
	await idle()
	await ticks(65)
	check(player.health == 3 and not is_instance_valid(arc.packet) and not arc.visible, "No espera fin de protección ni causa daño residual")
	await fixture(Vector2(400,600), true)
	boss.request_arc()
	await until_age(.60)
	await capture("16_aviso_Pasado")
	boss.cancel_arc()
	await fixture(Vector2(400,600))
	boss.request_arc()
	await until_age(1.0 + arc.duration * .70)
	player.take_damage(1)
	var normal_contacts: int = arc.contacts
	await idle()
	check(player.health == 2 and arc.contacts == normal_contacts + 1, "Invulnerabilidad normal consume contacto sin daño adicional")
	await fixture(Vector2(780,490))
	player.set_physics_process(false)
	player.position = Vector2(780,490)
	await ticks(2)
	boss.request_arc()
	await until_age(.4)
	shift()
	await ticks(2)
	check(manager.active_dimension == 0 and not player.is_temporally_protected(), "Shift rechazado no concede inmunidad")
	await idle()
	check(player.health == 2, "Paquete impacta tras Shift rechazado")
	for x: float in [600.0,140.0,1180.0]:
		var lateral_safe: bool = await evade(x, "move_left" if x > 1070 else "move_right")
		if x == 140.0:
			check(not lateral_safe, "LIMITACIÓN reproducida: correr hacia centro desde x140 cruza arco; salto requerido")
		else:
			check(lateral_safe, "Evasión lateral real desde F0 x=" + str(x))
		check(await evade(x, "move_right", true), "Evasión salto real desde F0 x=" + str(x))
	await fixture(Vector2(400,600))
	boss.request_arc()
	await until_age(1.0 + .70)
	await capture("06_cerca_F0")
	var hit_before: int = arc.contacts
	for index: int in range(60):
		if arc.contacts > hit_before:
			break
		await ticks(1)
	check(player.health == 2 and arc.consumed, "Contacto ofensivo visible se disipa sin segunda región de daño")
	await capture("07_contacto_real_F0")
	await ticks(7)
	await capture("07b_disipacion")
	for index: int in range(150):
		if boss.state == boss.State.RECOVER:
			break
		await ticks(1)
	check(boss.state == boss.State.RECOVER and not boss.request_arc() and not boss.request_beam(), "Recuperación exclusiva espera fin del peligro y disipación")
	await capture("11_recover_pose5")
	await idle()
	await ticks(40)
	check(player.health == 2 and boss.state == boss.State.IDLE, "Sin impactos duplicados ni ataques automáticos")
	boss.set_core_exposed(true)
	check(not boss.request_arc() and boss.can_receive_damage(), "Vulnerabilidad explícita conserva matriz y bloquea arco")
	boss.set_core_exposed(false)
	check(not boss.can_receive_damage(), "Núcleo protegido sin ventana automática")
	boss.play_diagnostic(&"starting")
	check(not boss.request_arc(), "Intro rechaza arco sin alterar estado")
	await ticks(100)
	boss.request_arc()
	boss.cancel_arc()
	check(not arc.warning and not arc.visible and boss.state == boss.State.IDLE, "Cancelación de aviso limpia estado")
	boss.request_arc()
	await until_age(1.05)
	boss.cancel_arc()
	check(not is_instance_valid(arc.packet) and not boss.arc_running, "Cancelación explícita durante vuelo")
	await capture("12_cancelado")
	check(boss.request_beam() and not boss.request_arc(), "Haz original disponible con exclusividad inversa")
	await idle()
	boss.request_arc()
	await until_age(1.05)
	boss.health = 0
	await ticks(3)
	check(boss.state == boss.State.DEFEATED and not arc.visible and not is_instance_valid(arc.packet) and not boss.request_arc(), "Derrota cancela paquete y conserva estado terminal")
	await capture("13_derrota_cancelacion")
	room.queue_free()
	await ticks(3)
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	boss = room.get_node("CoreGuardian")
	arc = boss.get_node("ArcAttack")
	await ticks(20)
	boss.request_arc()
	await until_age(1.05)
	var weak_packet: WeakRef = weakref(arc.packet)
	var weak_arc: WeakRef = weakref(arc)
	room.queue_free()
	await ticks(3)
	check(weak_packet.get_ref() == null and weak_arc.get_ref() == null, "Liberación Room5 elimina paquete y referencias")
	check(not FileAccess.file_exists("user://progress_v1.json"), "Sin escrituras de progreso")
	print("ARC_RESULT checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
