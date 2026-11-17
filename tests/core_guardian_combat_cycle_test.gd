extends SceneTree

var room: Node2D
var player: CharacterBody2D
var boss: Node2D
var manager: Node
var checks: int = 0
var failures: int = 0
var captures: bool = false

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

func wait_state(value: int, limit: int = 900) -> void:
	for index: int in range(limit):
		if boss.state == value:
			return
		await ticks(1)
	check(false, "Estado alcanzado " + str(value))

func wait_age(value: float) -> void:
	for index: int in range(200):
		if boss.beam_elapsed >= value:
			return
		await ticks(1)
	check(false, "Edad alcanzada " + str(value))

func capture(label: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var directory: String = "res://artifacts/room5_stage_h3"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	check(picture.save_png("%s/%s_%dx%d.png" % [directory,label,picture.get_width(),picture.get_height()]) == OK, "Captura real " + label)

func shift() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.location = KEY_LOCATION_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.location = KEY_LOCATION_LEFT
	Input.parse_input_event(event)

func fresh() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("attack")
	if is_instance_valid(room):
		room.queue_free()
		await ticks(3)
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	boss = room.get_node("CoreGuardian")
	manager = room.get_node("DimensionManager")
	await ticks(20)

func fixture(position: Vector2) -> void:
	player.position = position
	player.velocity = Vector2.ZERO
	await ticks(12)

func safe() -> bool:
	return not boss.cycle_running and not boss.beam_running and not boss.arc_running and not boss.core_exposed and not boss.get_node("ArcAttack").visible and not boss.get_node("BeamAttack").visible

func sword(jump: bool, label: String = "") -> void:
	if jump:
		Input.action_press("jump")
		await ticks(20)
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	await ticks(13)
	if label != "":
		await capture(label)
	await ticks(15)
	Input.action_release("jump")

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_h3_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	root.get_node("GameProgress").has_temporal_lens = true
	root.get_node("GameProgress").has_cronal_sword = true
	await fresh()
	check(boss.state == boss.State.IDLE and safe(), "Carga pasiva sin encuentro automático")
	await capture("01_reposo")
	var start: Vector2 = player.position
	print("ROUTE normal_spawn=",start)
	check(start == Vector2(140,600) or start == Vector2(180,600), "Inicio normal de Room5 sin recolocación")
	check(boss.start_combat_cycle() and not boss.start_combat_cycle(), "Inicio explícito único")
	check(not boss.request_arc() and not boss.request_beam() and not boss.core_exposed, "API externa no interrumpe descanso del ciclo")
	await wait_state(boss.State.CANNON_AIM)
	check(boss.cycle_last_attack == &"arc" and boss.cycle_attacks == 1, "F0 selecciona arco tras descanso inicial")
	await capture("02_arco_seleccionado")
	await wait_age(1.01)
	var arc: Node2D = boss.get_node("ArcAttack")
	await wait_age(1.0 + arc.duration - .28)
	Input.action_press("jump")
	await ticks(25)
	Input.action_release("jump")
	check(player.health == 3, "Recorrido: evasión desde aparición con salto real")
	await wait_state(boss.State.RECOVER)
	check(not boss.core_exposed and not is_instance_valid(arc.packet), "Recuperación espera vuelo y disipación, núcleo cerrado")
	await capture("03_recuperacion")
	await wait_state(boss.State.APPROACH)
	check(not boss.core_exposed and not arc.visible, "Aproximación sin peligros")
	await capture("04_aproximacion")
	var route_start: Vector2 = player.position
	var travel_ticks: int = 0
	shift()
	await ticks(18)
	check(manager.active_dimension == 1, "Recorrido permite Pasado durante aproximación")
	Input.action_press("move_right")
	for index: int in range(280):
		if player.position.x >= 1044:
			break
		await ticks(1)
		travel_ticks += 1
	Input.action_release("move_right")
	await ticks(8)
	print("ROUTE from=",route_start," to=",player.position," seconds=",float(travel_ticks)/60.0," health=",player.health)
	check(player.position.x > 1040 and player.position.x < 1070 and boss.state == boss.State.APPROACH and player.health == 3, "Aproximación física cabe en 4.75s, sin teletransporte ni daño")
	shift()
	await ticks(18)
	check(manager.active_dimension == 0, "Recorrido regresa a Presente con Shift real antes de golpear")
	await wait_state(boss.State.CORE_OPENING)
	check(not boss.core_exposed and not boss.can_receive_damage(), "Descenso no cuenta como exposición")
	await ticks(12)
	await capture("05_descenso")
	await wait_state(boss.State.VULNERABLE)
	var open_frame: int = Engine.get_physics_frames()
	check(boss.sprite.frame == 5 and boss.weakpoint.global_position.distance_to(Vector2(1081.092875,566)) < .1 and boss.beam_elapsed < .04, "Ventana empieza en pose baja final y collider alineado")
	await capture("06_nucleo_expuesto")
	var before: int = boss.health
	await sword(true,"07_espada_real")
	check(boss.health == before - 1, "Recorrido: tajo real hace exactamente un daño")
	await sword(true)
	check(boss.health == before - 2, "Dos saltos y tajos independientes caben en ventana de 2s")
	await wait_state(boss.State.CORE_CLOSING)
	var exposed_steps: int = Engine.get_physics_frames() - open_frame
	print("WINDOW physics_steps=",exposed_steps," hits=",before-boss.health," player_hp=",player.health)
	check(absi(exposed_steps - 120) <= 2, "Exposición efectiva medida: 120 pasos físicos aproximadamente")
	check(not boss.core_exposed and boss.beam_elapsed < .04 and player.health == 3, "Cierre lógico tras 2s efectivos sin daño al Player")
	await capture("08_cierre")
	await wait_state(boss.State.CYCLE_WAIT)
	check(not boss.can_receive_damage() and not boss.request_arc(), "Recuperación de cierre precede siguiente descanso")
	before = boss.health
	await sword(true)
	check(boss.health == before, "Tajo real después del cierre no resta salud")
	await wait_state(boss.State.CANNON_AIM)
	check(boss.cycle_attacks == 2 and boss.cycle_windows == 1, "Siguiente ataque solamente después de ventana, cierre y descanso")
	await capture("09_siguiente_ciclo")
	boss.stop_combat_cycle()
	boss.stop_combat_cycle()
	await ticks(40)
	check(safe() and boss.state == boss.State.IDLE, "Stop idempotente sin reinicio")
	await capture("10_detenido")
	# Separate controlled fixtures below; they are not part of the continuous route.
	await fresh()
	await fixture(Vector2(380,540))
	check(boss.beam_eligible() and boss.select_cycle_attack() == &"beam", "R1 en Presente intersecta volumen real del haz")
	boss.start_combat_cycle()
	await wait_state(boss.State.BEAM_PREPARE)
	await capture("11_haz_seleccionado")
	shift()
	await ticks(18)
	check(manager.active_dimension == 1 and not boss.beam_eligible(), "Pasado confirmado vuelve inelegible el haz")
	await wait_state(boss.State.APPROACH)
	check(player.health == 3 and boss.cycle_last_attack == &"beam", "Haz conserva inmunidad en Pasado y recuperación completa")
	shift()
	await ticks(18)
	check(manager.active_dimension == 0 and boss.select_cycle_attack() == &"arc", "Regreso real a Presente y alternancia tras haz")
	boss.cycle_last_attack = &"arc"
	check(boss.select_cycle_attack() == &"beam", "Alternancia permite haz tras arco si ambos elegibles")
	boss.stop_combat_cycle()
	await fixture(Vector2(580,480))
	var p1_eligible: bool = boss.beam_eligible()
	boss.request_beam()
	await ticks(170)
	print("P1_FIXTURE position=",player.position," eligible=",p1_eligible," hp=",player.health)
	check(p1_eligible == (player.health < 3), "Elegibilidad P1 coincide con contacto real del haz, sin asumir altura segura")
	player.set_physics_process(false)
	player.position = Vector2(580,440)
	await ticks(2)
	check(not boss.beam_eligible() and boss.select_cycle_attack() == &"arc", "Fixture alto fuera de banda no fuerza haz inútil")
	player.set_physics_process(true)
	await fixture(Vector2(1150,600))
	check(not boss.beam_eligible() and boss.select_cycle_attack() == &"arc", "Detrás del cuerpo no fuerza haz izquierdo")
	await fixture(Vector2(400,600))
	boss.cycle_last_attack = &"arc"
	check(boss.select_cycle_attack() == &"arc", "Repite arco válido en F0 sin forzar alternancia inútil")
	# Open naturally, with Player fixture placed out of arc target during the warning.
	boss.start_combat_cycle()
	await wait_state(boss.State.CANNON_AIM)
	await wait_age(.4)
	await fixture(Vector2(1049,600))
	await wait_state(boss.State.VULNERABLE)
	before = boss.health
	await sword(false)
	check(boss.health == before, "Espada en suelo no alcanza núcleo")
	shift()
	await ticks(18)
	check(boss.state == boss.State.VULNERABLE and not boss.can_receive_damage(), "Pasado confirmado durante ventana efectiva")
	await sword(true)
	check(manager.active_dimension == 1 and boss.health == before, "Espada real rechazada en Pasado expuesto")
	await wait_state(boss.State.CYCLE_WAIT)
	shift()
	await ticks(18)
	boss.stop_combat_cycle()
	check(manager.active_dimension == 0, "Shift devuelve dimensión confirmada antes de nueva apertura")
	# Stop in each local state, using unaltered timing.
	for state_name: String in ["CYCLE_WAIT","BEAM_ACTIVE","CANNON_RELEASE","APPROACH","CORE_OPENING","VULNERABLE","CORE_CLOSING"]:
		await fresh()
		await fixture(Vector2(380,540) if state_name == "BEAM_ACTIVE" else Vector2(1150,600))
		boss.start_combat_cycle()
		await wait_state(boss.State.get(state_name))
		boss.stop_combat_cycle()
		await ticks(4)
		check(safe() and boss.state == boss.State.IDLE, "Stop limpia " + state_name)
	await fresh()
	await fixture(Vector2(1150,600))
	boss.start_combat_cycle()
	await wait_state(boss.State.CANNON_AIM)
	await wait_age(.4)
	await fixture(Vector2(1049,600))
	await wait_state(boss.State.VULNERABLE)
	before = boss.health
	player.set_physics_process(false)
	player.position = Vector2(780,490)
	await ticks(2)
	shift()
	await ticks(2)
	check(manager.active_dimension == 0 and boss.can_receive_damage() and not player.is_temporally_protected(), "Shift rechazado durante apertura conserva matriz de Presente")
	await sword(false)
	check(boss.health == before, "Espada fuera de alcance no resta salud durante ventana")
	player.set_physics_process(true)
	boss.stop_combat_cycle()
	await fresh()
	await fixture(Vector2(1150,600))
	boss.start_combat_cycle()
	await wait_state(boss.State.CANNON_AIM)
	await wait_age(.4)
	await fixture(Vector2(1049,600))
	await wait_state(boss.State.VULNERABLE)
	boss.health = 1 # Lethal-health fixture; the final damage itself must come from the real sword.
	await sword(true)
	check(boss.health == 0 and boss.state == boss.State.DEFEATED and safe(), "Tajo real letal confirma derrota y cancela ciclo")
	await fresh()
	player.health = 0
	check(not boss.start_combat_cycle(), "No inicia con Player derrotado")
	await fresh()
	await fixture(Vector2(1150,600))
	player.health = 1
	boss.start_combat_cycle()
	for index: int in range(200):
		if player.health == 0:
			break
		await ticks(1)
	check(player.health == 0 and safe(), "Impacto letal real del arco cancela ciclo sin referencias liberadas")
	await fresh()
	boss.start_combat_cycle()
	await wait_state(boss.State.CANNON_RELEASE)
	boss.health = 0 # Separate controlled terminal fixture, not proof of sword damage.
	await ticks(3)
	check(safe() and boss.state == boss.State.DEFEATED and not boss.start_combat_cycle(), "Derrota jefe cancela y bloquea reinicio")
	await fresh()
	boss.start_combat_cycle()
	await wait_state(boss.State.CANNON_RELEASE)
	var weak_boss: WeakRef = weakref(boss)
	var weak_packet: WeakRef = weakref(boss.get_node("ArcAttack").packet)
	room.queue_free()
	await ticks(3)
	check(weak_boss.get_ref() == null and weak_packet.get_ref() == null, "Liberación Room5 elimina ciclo y paquete")
	await fresh()
	check(safe() and boss.state == boss.State.IDLE and boss.health == 6, "Instancia nueva pasiva y sin referencias heredadas")
	boss.start_combat_cycle()
	await wait_state(boss.State.CANNON_RELEASE)
	weak_boss = weakref(boss)
	weak_packet = weakref(boss.get_node("ArcAttack").packet)
	Input.action_press("move_left")
	for index: int in range(100):
		if current_scene != room:
			break
		await ticks(1)
	Input.action_release("move_left")
	await ticks(3)
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/Room4.tscn" and weak_boss.get_ref() == null and weak_packet.get_ref() == null, "Salida real Room5 a Room4 con ciclo activo libera jefe y paquete")
	room = current_scene
	check(not FileAccess.file_exists("user://progress_v1.json"), "Sin victoria ni escritura de progreso")
	room.queue_free()
	await ticks(3)
	print("CYCLE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
