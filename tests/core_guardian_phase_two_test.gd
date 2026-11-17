extends SceneTree

var room: Node2D
var player: CharacterBody2D
var boss: Node2D
var manager: Node
var checks: int = 0
var failures: int = 0
var captures: bool = false
var recording: bool = false
var elapsed_steps: int = 0
var previous_state: int = -1
var previous_phase: int = -1
var previous_hp: int = 3
var metrics: Dictionary = {}

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

func wait_state(value: int) -> bool:
	for index: int in range(1200):
		if boss.state == value:
			return true
		if player.health <= 0 or boss.health <= 0:
			return false
		await ticks(1)
	check(false,"Estado alcanzado " + str(value))
	return false

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
	await ticks(18)

func fresh() -> void:
	for action: String in ["move_left","move_right","jump","attack"]:
		Input.action_release(action)
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

func move_to(x: float) -> void:
	var right: bool = player.position.x < x
	var action: String = "move_right" if right else "move_left"
	Input.action_press(action)
	for index: int in range(400):
		if (right and player.position.x >= x) or (not right and player.position.x <= x) or player.health <= 0:
			break
		await ticks(1)
	Input.action_release(action)
	await ticks(8)

func climb_r2() -> void:
	await move_to(900 if player.position.x < 900 else 910)
	Input.action_press("jump")
	await ticks(44)
	Input.action_release("jump")
	check(player.is_on_floor() and absf(player.position.y-540) < 1 and player.position.x > 860 and player.position.x < 940,"Subida real F0 a R2 compartida")

func approach_core() -> void:
	if player.position.x < 1044:
		await move_to(1044)
	if manager.active_dimension == 1:
		await shift()

func sword(label: String = "") -> void:
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

func wait_age(age: float) -> void:
	for index: int in range(250):
		if boss.beam_elapsed >= age:
			return
		await ticks(1)
	check(false,"Edad alcanzada " + str(age))

func capture(label: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var directory: String = "res://artifacts/room5_stage_i3"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	check(picture.save_png("%s/%s_%dx%d.png" % [directory,label,picture.get_width(),picture.get_height()]) == OK,"Captura continua " + label)

func observe() -> void:
	if not recording or not is_instance_valid(boss):
		return
	elapsed_steps += 1
	var phase_key: String = "phase_%d_steps" % boss.combat_phase
	metrics[phase_key] += 1
	if player.health < previous_hp:
		metrics["damage_received"] += previous_hp-player.health
	previous_hp = player.health
	if boss.state != previous_state or boss.combat_phase != previous_phase:
		var name: String = boss.State.keys()[boss.state]
		metrics["events"].append({"seconds":float(elapsed_steps)/60.0,"state":name,"phase":boss.combat_phase,"boss_hp":boss.health,"player_hp":player.health,"position":[player.position.x,player.position.y],"eligible_beam_token":boss.cycle_beam_was_eligible,"shield_ready":boss.shield_discharge_ready})
		if boss.state == boss.State.CANNON_AIM:
			metrics["arcs"] += 1
		if boss.state == boss.State.BEAM_PREPARE:
			metrics["beams"] += 1
		if boss.state == boss.State.VULNERABLE:
			metrics["windows"] += 1
		previous_state = boss.state
		previous_phase = boss.combat_phase

func evade_arc() -> void:
	await wait_state(boss.State.CANNON_AIM)
	await wait_age(.30)
	var arc: Node2D = boss.get_node("ArcAttack")
	var duration: float = maxf(.45,2.0 * maxf(arc.p0.distance_to(arc.p1),arc.p1.distance_to(arc.p2))/1400.0)
	await wait_age(1.0 + duration - (.50 if player.position.x > 1000 else .28))
	Input.action_press("jump")
	await ticks(25)
	Input.action_release("jump")

func continuous() -> void:
	await fresh()
	metrics = {"phase_1_steps":0,"phase_2_steps":0,"arcs":0,"beams":0,"windows":0,"hits":0,"slashes":0,"damage_received":0,"shifts":0,"rejected_shifts":0,"events":[]}
	elapsed_steps = 0
	previous_state = -1
	previous_phase = -1
	previous_hp = 3
	boss.damage_accepted.connect(func(amount: int) -> void: metrics["hits"] += amount)
	player.energy_slash_used.connect(func() -> void: metrics["slashes"] += 1)
	manager.dimension_changed.connect(func(_present: bool) -> void: metrics["shifts"] += 1)
	manager.dimension_change_rejected.connect(func() -> void: metrics["rejected_shifts"] += 1)
	recording = true
	check(player.position == Vector2(140,600) and boss.health == 6 and boss.combat_phase == 1 and not boss.cycle_running,"Inicio continuo normal 6HP, Etapa1 pasiva")
	await capture("01_reposo_etapa1")
	check(boss.start_combat_cycle(),"Inicio continuo por API")
	for window: int in range(3):
		await evade_arc()
		await wait_state(boss.State.APPROACH)
		await approach_core()
		await wait_state(boss.State.VULNERABLE)
		var before: int = boss.health
		await sword()
		check(boss.health == before-1 and boss.combat_phase == 1,"Espada real Etapa1 ventana " + str(window+1))
		if boss.health != before-1:
			await finish_continuous("incomplete_phase_one_sword")
			return
		if window < 2:
			await wait_state(boss.State.CYCLE_WAIT)
	check(boss.health == 3 and boss.phase_transition_pending and boss.state == boss.State.VULNERABLE,"Umbral3 pendiente no interrumpe apertura ni tajo")
	await capture("02_umbral3")
	if not await wait_state(boss.State.PHASE_TRANSITION):
		await finish_continuous("incomplete_transition")
		return
	check(not boss.core_exposed and not boss.arc_running and not boss.beam_running and boss.health == 3 and boss.combat_phase == 1,"Transición tras Retorn, protegida y sin restaurar salud")
	check(room.get_node("GuardianHint").label.text == boss.guardian_hint_text() and room.get_node("GuardianHint").label.text.contains("REFORZADO"),"Mensaje visible real cambia al reforzar escudo")
	await capture("03_transicion_sobrecarga")
	if not await wait_state(boss.State.CANNON_AIM):
		await finish_continuous("incomplete_phase_two_arc")
		return
	check(boss.combat_phase == 2 and boss.phase_transition_count == 1 and not boss.phase_transition_pending,"Etapa2 activa una sola vez")
	check(boss.guardian_hint_text().contains("Provoca el haz") and not boss.shield_discharge_ready,"Instrucción contextual persiste sin descarga")
	await capture("04_escudo_reforzado")
	await wait_age(.30)
	var old_windows: int = boss.cycle_windows
	await move_to(910)
	await capture("05_aproximacion_R2")
	Input.action_press("jump")
	await ticks(44)
	Input.action_release("jump")
	check(player.is_on_floor() and absf(player.position.y-540)<1 and boss.beam_eligible(),"Ruta continua sube a R2 en Presente")
	await wait_state(boss.State.CYCLE_WAIT)
	check(boss.cycle_windows == old_windows and not boss.core_exposed and not boss.shield_discharge_ready,"Arco aislado de Etapa2 no abre ni descarga")
	for window: int in range(3):
		# The original selector alternates when both attacks are eligible on R2.
		# Observe and evade that real arc rather than waiting motionless for a beam.
		for step: int in range(1000):
			if boss.state == boss.State.BEAM_PREPARE:
				break
			if boss.state == boss.State.CANNON_AIM:
				var windows_before: int = boss.cycle_windows
				await evade_arc()
				await wait_state(boss.State.CYCLE_WAIT)
				check(boss.cycle_windows == windows_before and not boss.shield_discharge_ready,"Arco alternado sobre R2 tampoco concede apertura")
			else:
				await ticks(1)
		if boss.state != boss.State.BEAM_PREPARE:
			await finish_continuous("incomplete_beam_selection")
			return
		check(boss.cycle_beam_was_eligible and boss.beam_eligible() and player.is_on_floor() and absf(player.position.y-540)<1,"Haz realmente seleccionado sobre R2, apertura " + str(window+1))
		if window == 0:
			await capture("06_haz_elegible_R2")
		await shift()
		check(manager.active_dimension == 1 and absf(player.position.y-540)<1,"Pasado conserva apoyo compartido")
		if window == 0:
			await capture("07_pasado_defensa")
		await wait_state(boss.State.BEAM_ACTIVE)
		check(not boss.shield_discharge_ready and not boss.core_exposed,"Haz activo todavía no concede apertura")
		if not await wait_state(boss.State.APPROACH):
			await finish_continuous("incomplete_discharge")
			return
		check(boss.shield_discharge_ready and boss.get_node("BeamAttack").phase == &"off" and boss.beam_duration == 4.75 and player.health == 3,"Descarga solo tras disipación y recuperación, sin exigir daño")
		await approach_core()
		if not await wait_state(boss.State.VULNERABLE):
			await finish_continuous("incomplete_opening")
			return
		check(boss.can_receive_damage() and manager.active_dimension == 0 and not boss.guardian_hint_text().contains("Provoca"),"Exposición Etapa2 real en Presente; instrucción reducida")
		check(room.get_node("GuardianHint").label.text == boss.guardian_hint_text(),"Label local refleja condición real de daño")
		if window == 0:
			await capture("08_expuesto_etapa2")
		var before: int = boss.health
		await sword("09_espada_etapa2" if window == 0 else "")
		check(boss.health == before-1,"Un impacto real tras descarga " + str(window+1))
		if boss.health != before-1:
			await finish_continuous("incomplete_phase_two_sword")
			return
		if boss.health == 0:
			break
		await climb_r2()
	await finish_continuous("boss_defeated" if boss.health == 0 else "incomplete")

func finish_continuous(result: String) -> void:
	recording = false
	metrics["trial_seconds"] = float(elapsed_steps)/60.0
	metrics["boss_final_hp"] = boss.health
	metrics["player_final_hp"] = player.health
	metrics["result"] = result
	metrics["missed_slashes"] = int(metrics["slashes"])-int(metrics["hits"])
	check(boss.health == 0 and boss.state == boss.State.DEFEATED and not boss.cycle_running and boss.phase_transition_count == 1 and player.health == 3,"Victoria continua 6 a0 con dos etapas, prioridad terminal")
	await capture("10_derrota_continua")
	var directory: String = "res://artifacts/room5_stage_i3"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file: FileAccess = FileAccess.open(directory + ("/continuous_render_%dx%d.json" % [root.size.x,root.size.y] if captures else "/continuous.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t"))
	file.close()
	print("CONTINUOUS ",JSON.stringify({"result":metrics["result"],"seconds":metrics["trial_seconds"],"arcs":metrics["arcs"],"beams":metrics["beams"],"hits":metrics["hits"],"player_hp":player.health}))

func preflight() -> void:
	await fresh()
	check(player.position == Vector2(140,600) and boss.health == 6,"Preflight inicia spawn normal, jefe6")
	await climb_r2()
	check(manager.active_dimension == 0 and boss.beam_eligible(),"R2 Presente intersecta haz real")
	check(boss.start_combat_cycle(),"Preflight activación explícita")
	await wait_state(boss.State.BEAM_PREPARE)
	check(boss.cycle_last_attack == &"beam","Selector eligió haz sin llamadas diagnósticas")
	await shift()
	check(manager.active_dimension == 1 and player.is_on_floor() and absf(player.position.y-540)<1,"Shift conserva apoyo R2 en Pasado")
	await wait_state(boss.State.BEAM_ACTIVE)
	await wait_state(boss.State.APPROACH)
	check(player.health == 3 and not boss.get_node("BeamAttack").visible and boss.beam_duration == 4.75,"Haz completo, recuperación y presupuesto elevado seguro")
	await approach_core()
	await wait_state(boss.State.VULNERABLE)
	await sword()
	await sword()
	check(boss.health == 4 and player.health == 3 and manager.active_dimension == 0,"Ruta R2 descarga, regreso y dos tajos reales viables")
	boss.stop_combat_cycle()
	var directory: String = "res://artifacts/room5_stage_i3"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file: FileAccess = FileAccess.open(directory + "/preflight.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"boss_hp":boss.health,"player_hp":player.health,"production_phase_rule_implemented":false},"\t"))
	file.close()

func phase_two_fixture(position: Vector2 = Vector2(140,600)) -> void:
	await fresh()
	# Controlled initial-health/position fixture only; never used in continuous().
	boss.health = 3
	player.position = position
	player.velocity = Vector2.ZERO
	await ticks(12)
	boss.start_combat_cycle()
	await wait_state(boss.State.PHASE_TRANSITION)
	await wait_state(boss.State.CYCLE_WAIT)
	check(boss.combat_phase == 2 and boss.phase_transition_count == 1,"Fixture Etapa2 sin duplicar transición")

func safety_fixtures() -> void:
	await phase_two_fixture()
	check(not boss.request_beam() and not boss.shield_discharge_ready,"Petición diagnóstica de haz inelegible no descarga escudo")
	for attack: int in range(2):
		await evade_arc()
		await wait_state(boss.State.CYCLE_WAIT)
		check(boss.cycle_windows == 0 and boss.approach_samples == 0 and not boss.core_exposed and boss.health == 3,"Permanecer en F0 no regala apertura " + str(attack+1))
	check(player.health == 3 and boss.guardian_hint_text().contains("Provoca el haz"),"F0 conserva salida física e instrucción, sin timeout letal")
	boss.stop_combat_cycle()
	check(not boss.cycle_running and not boss.shield_discharge_ready and boss.guardian_hint_text().is_empty() and not room.get_node("GuardianHint").panel.visible,"Stop limpia ciclo, descarga e interfaz local")
	await phase_two_fixture(Vector2(900,540))
	await wait_state(boss.State.BEAM_PREPARE)
	var hp: int = player.health
	check(boss.cycle_beam_was_eligible,"Fixture físico: haz elegible antes de abandonar plataforma")
	await move_to(1044)
	await wait_state(boss.State.APPROACH)
	check(manager.active_dimension == 0 and player.health == hp and boss.shield_discharge_ready,"Evasión por movimiento real sin Shift también descarga escudo")
	boss.stop_combat_cycle()
	check(not boss.shield_discharge_ready and not boss.cycle_beam_was_eligible,"Cancelación invalida token de descarga, sin reutilizarlo")
	await fresh()
	boss.health = 3
	boss.start_combat_cycle()
	await wait_state(boss.State.PHASE_TRANSITION)
	boss.stop_combat_cycle()
	await ticks(90)
	check(boss.combat_phase == 1 and boss.phase_transition_count == 0 and not boss.cycle_running,"Stop durante transición impide activación tardía")
	boss.start_combat_cycle()
	await wait_state(boss.State.PHASE_TRANSITION)
	await wait_state(boss.State.CYCLE_WAIT)
	check(boss.combat_phase == 2 and boss.phase_transition_count == 1 and boss.health == 3,"Reanudación segura no restaura salud ni duplica fase")
	boss.stop_combat_cycle()
	await fresh()
	boss.health = 3
	boss.start_combat_cycle()
	await wait_state(boss.State.PHASE_TRANSITION)
	player.take_damage(3)
	await ticks(2)
	check(not boss.cycle_running and not boss.phase_transition_pending and boss.phase_transition_count == 0,"Derrota real Player cancela transición pendiente")
	await fresh()
	boss.health = 3
	boss.start_combat_cycle()
	await wait_state(boss.State.PHASE_TRANSITION)
	boss.health = 0
	await ticks(90)
	check(boss.state == boss.State.DEFEATED and boss.phase_transition_count == 0 and not boss.phase_transition_pending and not boss.start_combat_cycle(),"Derrota del jefe tiene prioridad absoluta sobre Etapa2")
	await fresh()
	check(boss.combat_phase == 1 and not boss.phase_two_activated and boss.health == 6 and boss.phase_two_health_threshold <= boss.max_health,"Instancia nueva conserva etapa y salud inicial, umbral acotado")
	check(not FileAccess.file_exists("user://progress_v1.json"),"Sin victoria persistente ni escrituras de progreso")

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_i3_work"):
		quit(2)
		return
	root.get_node("GameProgress").has_temporal_lens = true
	root.get_node("GameProgress").has_cronal_sword = true
	captures = OS.get_cmdline_user_args().has("--capture")
	physics_frame.connect(observe)
	if OS.get_cmdline_user_args().has("--preflight"):
		await preflight()
	else:
		await continuous()
		if metrics.get("result","") == "boss_defeated":
			await safety_fixtures()
	if is_instance_valid(room):
		room.queue_free()
	await ticks(3)
	print("PHASE_TWO_RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
