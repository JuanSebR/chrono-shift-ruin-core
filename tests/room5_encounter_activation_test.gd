extends "res://tests/core_guardian_phase_two_test.gd"

var encounter_data: Dictionary = {}
var intro_frame: int = 0
var active_frame: int = 0
var start_frame: int = 0
var unlock_frame: int = 0
var room4_start_frame: int = 0
var arrival_frame: int = 0
var fixtures_running: bool = false

func capture(label: String) -> void:
	if not captures:
		return
	if fixtures_running and label != "06_salida_bloqueada":
		return
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var directory: String = "res://artifacts/room5_stage_k1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var prefix: String = "fixture_" if fixtures_running else ""
	check(picture.save_png("%s/%s%s_%dx%d.png" % [directory,prefix,label,picture.get_width(),picture.get_height()]) == OK,"Captura K1 " + label)

func adopt_room5() -> void:
	room = current_scene
	player = room.get_node("Player")
	boss = room.get_node("CoreGuardian")
	manager = room.get_node("DimensionManager")

func setup_progress() -> void:
	var progress: Node = root.get_node("GameProgress")
	progress.has_cronal_sword = true
	progress.has_temporal_lens = true
	progress.has_reactor_key = true
	for key: String in progress.completed_tutorials:
		progress.completed_tutorials[key] = true

func travel(action: String, expected: String) -> bool:
	var old_scene: Node = current_scene
	Input.action_press(action)
	for step: int in range(700):
		if current_scene != old_scene and current_scene != null:
			Input.action_release(action)
			await ticks(8)
			return current_scene.scene_file_path == "res://scenes/%s.tscn" % expected
		await ticks(1)
	Input.action_release(action)
	check(false,"Transición física " + expected)
	return false

func enter_from_room4() -> void:
	setup_progress()
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		await ticks(3)
	var initial: Node2D = load("res://scenes/Room4.tscn").instantiate()
	root.add_child(initial)
	current_scene = initial
	# Initial progress/arrival fixture only: legitimate exit ledge in Room4.
	# No position or health is reassigned after crossing ToRoom5.
	player = initial.get_node("Player")
	player.position = initial.get_node("EntryMarkers/FromRoom5").position
	player.velocity = Vector2.ZERO
	await ticks(20)
	check(player.is_on_floor() and initial.get_node("RoomTransitions/ToRoom5").monitoring,"Perfil aislado preparado en repisa legítima de salida Room4")
	room4_start_frame = Engine.get_physics_frames()
	check(await travel("move_right","Room5"),"Entrada real por ToRoom5")
	adopt_room5()
	arrival_frame = Engine.get_physics_frames()
	check(player.position.distance_to(Vector2(180,600)) < 5 and player.health == 3,"Llegada segura real en Room5")
	check(root.get_node("GameProgress").has_reactor_key and root.get_node("GameProgress").has_cronal_sword and root.get_node("GameProgress").has_temporal_lens,"Llegada conserva Llave, espada y Lente")
	var arrival_state: bool = room.room_cleared if root.get_node("GameProgress").core_guardian_defeated else room.encounter_state == room.EncounterState.INACTIVE
	check(arrival_state and not boss.cycle_running and not room.get_node("BossHUD").anchor.visible and room.get_node("RoomTransitions/ToRoom4").monitoring,"Llegada inmóvil pasiva o ya superada, HUD oculto y salida disponible")
	await ticks(25)
	check(room.encounter_activation_count == 0,"Permanecer en llegada no activa encuentro")

func activate_naturally() -> void:
	start_frame = Engine.get_physics_frames()
	await capture("01_llegada_pasiva")
	await move_to(300)
	check(room.encounter_state == room.EncounterState.INACTIVE,"Aproximación anterior al trigger sigue pasiva")
	await capture("02_aproximacion_trigger")
	Input.action_press("move_right")
	for step: int in range(200):
		if room.encounter_state == room.EncounterState.INTRO:
			break
		await ticks(1)
	Input.action_release("move_right")
	intro_frame = Engine.get_physics_frames()
	check(room.encounter_state == room.EncounterState.INTRO and room.encounter_activation_count == 1 and not boss.cycle_running,"Entrada física activa INTRO una vez sin iniciar ciclo")
	var exit_area: Area2D = room.get_node("RoomTransitions/ToRoom4")
	check(room.exit_blocked and not exit_area.is_connected("body_entered",Callable(exit_area,"_on_body_entered")) and not room.get_node("BossHUD").anchor.visible,"Intro bloquea despacho de ToRoom4 inmediatamente, HUD oculto")
	await ticks(1)
	check(not exit_area.monitoring,"Desactivación diferida de monitoring completa sin cambiar geometría")
	check(boss.sprite.animation == &"starting" and not boss.core_exposed,"Intro original Starting sin exposición")
	await capture("03_inicio_intro")
	await ticks(24)
	check(player.health == 3 and boss.health == 6 and not boss.beam_running and not boss.arc_running,"INTRO no causa daño ni ofensivas")
	await capture("04_guardian_incorporandose")
	for step: int in range(120):
		if room.encounter_state == room.EncounterState.ACTIVE:
			break
		await ticks(1)
	active_frame = Engine.get_physics_frames()
	check(room.encounter_state == room.EncounterState.ACTIVE and boss.cycle_running and room.encounter_cycle_starts == 1,"Final fiable de Starting inicia un único ciclo")
	check(absi(active_frame-intro_frame-60) <= 2,"Introducción medida aproximadamente1s, ocho poses a8fps")
	check(boss.health == 6 and boss.combat_phase == 1 and not boss.core_exposed and room.get_node("BossHUD").anchor.visible,"Ciclo inicia Etapa1 y BossHUD sincronizado")
	await capture("05_combate_activo_HUD")

func main_route() -> void:
	await enter_from_room4()
	await activate_naturally()
	metrics = {"phase_1_steps":0,"phase_2_steps":0,"arcs":0,"beams":0,"windows":0,"hits":0,"slashes":0,"damage_received":0,"shifts":0,"rejected_shifts":0,"events":[]}
	elapsed_steps = Engine.get_physics_frames()-active_frame
	previous_state = -1
	previous_phase = -1
	previous_hp = player.health
	boss.damage_accepted.connect(func(amount: int) -> void: metrics["hits"] += amount)
	player.energy_slash_used.connect(func() -> void: metrics["slashes"] += 1)
	manager.dimension_changed.connect(func(_present: bool) -> void: metrics["shifts"] += 1)
	recording = true
	for window: int in range(3):
		if window == 0:
			await wait_state(boss.State.CANNON_AIM)
			await wait_age(.60)
			await capture("08_ataque_del_guardian")
		await evade_arc()
		await wait_state(boss.State.APPROACH)
		await approach_core()
		await wait_state(boss.State.VULNERABLE)
		await sword()
		if window < 2:
			await wait_state(boss.State.CYCLE_WAIT)
	check(boss.health == 3 and boss.phase_transition_pending,"Flujo natural conserva umbral3 y espada real")
	await wait_state(boss.State.PHASE_TRANSITION)
	await wait_state(boss.State.CANNON_AIM)
	await capture("09_etapa2")
	await wait_age(.30)
	await climb_r2()
	await wait_state(boss.State.CYCLE_WAIT)
	for window: int in range(3):
		for step: int in range(1000):
			if boss.state == boss.State.BEAM_PREPARE:
				break
			if boss.state == boss.State.CANNON_AIM:
				await evade_arc()
				await wait_state(boss.State.CYCLE_WAIT)
			else:
				await ticks(1)
		check(boss.state == boss.State.BEAM_PREPARE and boss.cycle_beam_was_eligible,"Haz natural elegible Etapa2")
		await shift()
		await wait_state(boss.State.APPROACH)
		await approach_core()
		await wait_state(boss.State.VULNERABLE)
		if window == 0:
			await capture("10_nucleo_expuesto")
		await sword()
		if boss.health == 0:
			break
		await climb_r2()
	recording = false
	var defeat_frame: int = Engine.get_physics_frames()
	check(boss.health == 0 and boss.state == boss.State.DEFEATED and room.encounter_state == room.EncounterState.BOSS_DEFEATED and player.health == 3,"Room4 a victoria6 a0 sin teletransportes ni alterar HP")
	check(room.encounter_activation_count == 1 and room.encounter_cycle_starts == 1,"Recruzar el área durante combate no reinicia encuentro")
	await capture("13_jefe_derrotado")
	await ticks(8)
	await capture("14_destruccion_BossHUD")
	for step: int in range(100):
		if not room.exit_blocked:
			break
		await ticks(1)
	unlock_frame = Engine.get_physics_frames()
	check(not room.exit_blocked and room.get_node("RoomTransitions/ToRoom4").monitoring and room.get_node("BossHUD").destruction_completed,"Salida liberada después de animaciones reales")
	await capture("15_salida_desbloqueada")
	encounter_data = {"intro_seconds":float(active_frame-intro_frame)/60.0,"combat_trial_seconds":float(defeat_frame-active_frame)/60.0,"activation_to_defeat_seconds":float(defeat_frame-intro_frame)/60.0,"unlock_delay_after_trial_seconds":float(unlock_frame-defeat_frame)/60.0,"combat":metrics,"player_final_hp":player.health,"boss_final_hp":boss.health,"activation_count":room.encounter_activation_count,"cycle_starts":room.encounter_cycle_starts}
	encounter_data["room4_departure_to_trial_end_seconds"] = float(defeat_frame-room4_start_frame)/60.0
	encounter_data["room5_arrival_to_trial_end_seconds"] = float(defeat_frame-arrival_frame)/60.0
	check(await travel("move_left","Room4"),"Regreso físico a Room4 tras victoria provisional")
	check(current_scene.get_node("Player").position.distance_to(Vector2(1160,264)) < 5,"Regreso Room4 sin bucle de transición")
	check(await travel("move_right","Room5"),"Nueva entrada Room5 tras victoria guardada")
	adopt_room5()
	check(room.room_cleared and room.victory_persisted and not boss.visible and not boss.cycle_running and not room.get_node("EncounterTrigger").monitoring and not room.get_node("BossHUD").anchor.visible,"Nueva instancia reconoce victoria persistente sin reiniciar jefe")
	var directory: String = "res://artifacts/room5_stage_k1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var suffix: String = "_%dx%d" % [root.size.x,root.size.y] if captures else ""
	var file: FileAccess = FileAccess.open(directory+"/activation"+suffix+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(encounter_data,"\t"))
	file.close()
	print("ENCOUNTER_METRICS ",JSON.stringify({"intro":encounter_data["intro_seconds"],"combat":encounter_data["combat_trial_seconds"],"arcs":metrics["arcs"],"beams":metrics["beams"],"hits":metrics["hits"],"player_hp":player.health}))

func blockage_fixtures() -> void:
	fixtures_running = true
	# Separate new-run fixture: the preceding real victory now persists in K.2.
	check(root.get_node("GameProgress").new_game(),"Nueva Partida aislada para fixture de bloqueo")
	setup_progress()
	check(await travel("move_left","Room4"),"Salida pasiva funciona antes de activar")
	check(await travel("move_right","Room5"),"Regreso para fixture de bloqueo")
	adopt_room5()
	Input.action_press("move_right")
	for step: int in range(200):
		if room.encounter_state == room.EncounterState.INTRO:
			break
		await ticks(1)
	Input.action_release("move_right")
	var exit_area: Area2D = room.get_node("RoomTransitions/ToRoom4")
	exit_area.body_entered.emit(player) # Queued-event fixture; not a physical crossing.
	await ticks(2)
	check(not exit_area.transition_pending and current_scene == room,"Evento residual no puede despachar transición durante INTRO")
	# Release braking ends about 14 units left of the requested coordinate.
	# Aim at 116 so the stopped collider still overlaps the exit at x=100.
	await move_to(116)
	await ticks(6)
	check(current_scene == room and room.exit_blocked and not exit_area.transition_pending,"Acercamiento físico al acceso bloqueado no abandona Room5")
	check(room.get_node("ExitBlockHint").panel.visible and room.get_node("ExitBlockHint").label.text.contains("ACCESO BLOQUEADO"),"Feedback local legible al intentar salir")
	await capture("06_salida_bloqueada")
	await shift()
	check(manager.active_dimension == 1 and room.encounter_activation_count == 1,"Bloqueo no interfiere con Shift ni duplica introducción")
	room.cancel_encounter()
	for step: int in range(100):
		if current_scene != room:
			break
		await ticks(1)
	check(current_scene != room and current_scene.scene_file_path == "res://scenes/Room4.tscn","Cancelación libera salida y no deja combate bloqueado")
	room = current_scene

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_k1_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	physics_frame.connect(observe)
	await main_route()
	await blockage_fixtures()
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await ticks(3)
	print("ACTIVATION_RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
