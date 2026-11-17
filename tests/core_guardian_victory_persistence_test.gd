extends "res://tests/room5_encounter_activation_test.gd"

var stage: String = "win"
var victory_signals: int = 0
var terminal_snapshot: Dictionary = {}
var capture_names: Dictionary = {
	"01_llegada_pasiva":"01_antes_de_vencer",
	"04_guardian_incorporandose":"02_intro",
	"05_combate_activo_HUD":"03_etapa1",
	"phase_transition":"04_sobrecarga",
	"09_etapa2":"05_etapa2",
	"13_jefe_derrotado":"06_derrota_real",
	"14_destruccion_BossHUD":"07_destruccion_HUD",
	"15_salida_desbloqueada":"08_salida_libre",
	"room4_return":"09_regreso_Room4",
	"cleared_reentry":"10_reingreso_arena_HUD",
	"cleared_past":"11_pasado_tras_victoria",
	"new_game_boss_available":"fixture_12_nueva_partida",
}

func capture(label: String) -> void:
	if not captures or not capture_names.has(label) or stage not in ["win","new_game"]:
		return
	if stage == "new_game" and label != "new_game_boss_available":
		return
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/room5_stage_k2"))
	check(picture.save_png("res://artifacts/room5_stage_k2/%s_%dx%d.png" % [capture_names[label],picture.get_width(),picture.get_height()]) == OK,"Captura K2 " + label)

func progress() -> Node:
	return root.get_node("GameProgress")

func on_victory_recorded() -> void:
	victory_signals += 1

func saved_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("user://progress_v1.json")) as Dictionary

func dispose_scene() -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await ticks(3)

func fresh_room5() -> void:
	await dispose_scene()
	var instance: Node2D = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(instance)
	current_scene = instance
	adopt_room5()
	await ticks(15)

func seed_profile() -> void:
	setup_progress()
	progress().completed_dialogues["k2_continuity"] = true

func snapshot_terminal() -> void:
	terminal_snapshot = {"frame":Engine.get_physics_frames(),"persisted":room.victory_persisted,"field":progress().core_guardian_defeated,"disk":saved_data().get("core_guardian_defeated",false),"hud_finished":room.get_node("BossHUD").destruction_completed,"attempts":room.victory_save_attempts}

func combat_route() -> void:
	await enter_from_room4()
	await activate_naturally()
	boss.defeated.connect(snapshot_terminal,CONNECT_ONE_SHOT)
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
		await evade_arc()
		await wait_state(boss.State.APPROACH)
		await approach_core()
		await wait_state(boss.State.VULNERABLE)
		await sword()
		if window < 2:
			await wait_state(boss.State.CYCLE_WAIT)
	check(boss.health == 3 and boss.phase_transition_pending and not progress().core_guardian_defeated,"Umbral3 no concede victoria")
	await wait_state(boss.State.PHASE_TRANSITION)
	await capture("phase_transition")
	await wait_state(boss.State.CANNON_AIM)
	check(boss.combat_phase == 2 and not progress().core_guardian_defeated,"Sobrecarga real no concede victoria")
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
		check(boss.state == boss.State.BEAM_PREPARE and boss.cycle_beam_was_eligible,"Selector conserva haz elegible Etapa2")
		await shift()
		await wait_state(boss.State.APPROACH)
		await approach_core()
		await wait_state(boss.State.VULNERABLE)
		await sword()
		if boss.health == 0:
			break
		await climb_r2()
	recording = false
	check(boss.health == 0 and boss.state == boss.State.DEFEATED and player.health == 3 and room.encounter_state == room.EncounterState.BOSS_DEFEATED,"Victoria continua legítima, espada real6 a0 sin alterar HP ni posiciones")
	check(metrics["hits"] == 6 and metrics["arcs"] == 6 and metrics["beams"] == 3 and metrics["windows"] == 6 and metrics["shifts"] == 6,"Combate conserva conteos K1")
	await capture("13_jefe_derrotado")
	await ticks(8)
	await capture("14_destruccion_BossHUD")

func wait_exit() -> void:
	for step: int in range(120):
		if not room.exit_blocked:
			break
		await ticks(1)
	await ticks(1)
	check(not room.exit_blocked and room.get_node("RoomTransitions/ToRoom4").monitoring and room.get_node("BossHUD").destruction_completed,"Desbloqueo depende de presentación original, no del guardado")
	await capture("15_salida_desbloqueada")

func assert_cleared() -> void:
	check(room.room_cleared and room.victory_persisted and room.encounter_activation_count == 0 and room.encounter_cycle_starts == 0,"Reentrada reconoce victoria antes de cualquier activación")
	check(not boss.visible and boss.process_mode == Node.PROCESS_MODE_DISABLED and boss.core_shape.disabled and boss.weakpoint.collision_layer == 0 and not boss.weakpoint.monitorable,"Entidad oculta y desactivada, sin núcleo/collider invisible activo")
	check(not boss.cycle_running and not boss.arc_running and not boss.beam_running and not boss.get_node("ArcAttack").visible and not boss.get_node("BeamAttack").visible,"Arena superada no contiene peligros")
	check(not room.get_node("EncounterTrigger").monitoring and not room.exit_blocked and room.get_node("RoomTransitions/ToRoom4").monitoring,"Trigger inactivo y salida disponible")
	check(not room.get_node("BossHUD").anchor.visible and room.get_node("BossHUD").destruction_plays == 0 and not room.get_node("GuardianHint").panel.visible and not room.get_node("ExitBlockHint").panel.visible,"Sin BossHUD, destrucción repetida ni instrucciones activas")
	check(progress().has_cronal_sword and progress().has_temporal_lens and progress().has_reactor_key,"Posesiones conservadas en arena superada")

func exercise_cleared() -> void:
	assert_cleared()
	await capture("cleared_reentry")
	var hp: int = player.health
	await move_to(600)
	await ticks(80)
	check(room.encounter_activation_count == 0 and not boss.cycle_running and player.health == hp,"Cruce físico del trigger y espera no reactivan jefe ni dañan")
	await shift()
	check(manager.active_dimension == 1 and manager.switch_cooldown_remaining == 0.0,"Shift físico funciona tras victoria con recarga terminada")
	check(room.get_node("WorldCollision/PresentCollision/P1/Shape").disabled and not room.get_node("WorldCollision/PastCollision/T1/Shape").disabled,"P1 y T1 conservan colisiones alternadas")
	await capture("cleared_past")
	await shift()
	await climb_r2()
	check(player.is_on_floor() and absf(player.position.y-540) < 1,"R2 compartida explorable con salto real tras vencer")
	check(manager.SWITCH_COOLDOWN == .20 and player.TEMPORAL_PROTECTION_DURATION == .16,"Constantes dimensionales originales")

func win_stage() -> void:
	check(progress().new_game() and not progress().core_guardian_defeated,"Nueva Partida comienza sin victoria")
	seed_profile()
	check(progress().save_progress(),"Fixture aislado de progresión previa guardado")
	progress().core_guardian_victory_recorded.connect(on_victory_recorded)
	await combat_route()
	check(terminal_snapshot["field"] and terminal_snapshot["disk"] and terminal_snapshot["persisted"] and not terminal_snapshot["hud_finished"] and terminal_snapshot["attempts"] == 1,"Victoria guardada en señal DEFEATED antes de terminar BossHUD")
	check(victory_signals == 1 and saved_data()["version"] == 1,"Una confirmación, mismo formato y archivo v1")
	var disk: String = FileAccess.get_file_as_string("user://progress_v1.json")
	var backup: String = FileAccess.get_file_as_string("user://progress_v1.json.bak")
	boss.defeated.emit() # Duplicate notification after an actual sword victory.
	check(progress().record_core_guardian_victory(),"Registrar victoria ya confirmada es idempotente")
	await wait_exit()
	check(victory_signals == 1 and room.victory_save_attempts == 1 and disk == FileAccess.get_file_as_string("user://progress_v1.json") and backup == FileAccess.get_file_as_string("user://progress_v1.json.bak"),"Notificación repetida y espera no reescriben principal ni backup")
	check(await travel("move_left","Room4"),"Regreso físico a Room4 tras victoria persistida")
	check(current_scene.get_node("Player").health == 3 and current_scene.get_node("Player").position.distance_to(Vector2(1160,264)) < 5,"Transición conserva salud y marcador")
	await capture("room4_return")
	check(await travel("move_right","Room5"),"Reingreso real por ToRoom5")
	adopt_room5()
	await exercise_cleared()
	var terminal_seconds: float = 0.0
	for event: Dictionary in metrics["events"]:
		if event["state"] == "DEFEATED":
			terminal_seconds = event["seconds"]
	write_report("combat",{"terminal_seconds":terminal_seconds,"intro_seconds":float(active_frame-intro_frame)/60.0,"combat":metrics,"terminal_snapshot":terminal_snapshot,"victory_signals":victory_signals,"player_final_hp":player.health,"reentry_cleared":room.room_cleared})
	progress().core_guardian_victory_recorded.disconnect(on_victory_recorded)
	var files: PackedStringArray = DirAccess.get_files_at("user://")
	check(files.size() == 2 and files.has("progress_v1.json") and files.has("progress_v1.json.bak"),"Persistencia usa solo el archivo v1 y su backup existente")

func load_menu() -> Node:
	await dispose_scene()
	var menu: Node = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await ticks(3)
	return menu

func block_temp_path() -> void:
	# Exact empty directory in the guarded isolated profile; no permissions changed.
	check(OS.get_user_data_dir().contains("phase_k2_work"),"Fallo IO limitado al perfil K2")
	check(DirAccess.make_dir_absolute("user://progress_v1.json.tmp") == OK,"Inyección real: directorio impide abrir el archivo temporal")

func unblock_temp_path() -> void:
	check(DirAccess.remove_absolute("user://progress_v1.json.tmp") == OK,"Retirada del directorio vacío de inyección")

func resume_stage() -> void:
	check(progress().core_guardian_defeated and saved_data()["core_guardian_defeated"],"Proceso nuevo restaura victoria del disco al arrancar")
	check(progress().dialogue_completed("k2_continuity") and progress().tutorial_completed("move"),"Proceso nuevo conserva diálogos y tutoriales")
	var menu: Node = await load_menu()
	var continue_destination: String = progress().get_continue_scene()
	menu.call("_on_continue_pressed")
	await ticks(8)
	check(current_scene.scene_file_path == continue_destination and progress().core_guardian_defeated,"Continuar real conserva victoria y checkpoint o destino histórico v1")
	check(progress().has_cronal_sword and progress().has_temporal_lens and progress().has_reactor_key,"Continuar conserva las tres posesiones")
	# Arrival fixture after checking the actual Continue destination; not a six-room run.
	await enter_from_room4()
	assert_cleared()
	await move_to(600)
	check(room.encounter_cycle_starts == 0,"Reingreso por transición después de Continuar sigue superado")
	write_report("resume",{"loaded_from_disk":true,"continue_destination":continue_destination,"room4_arrival_fixture":true,"cleared_after_continue":room.room_cleared})

func new_game_stage() -> void:
	check(progress().core_guardian_defeated,"Nueva Partida parte de victoria real restaurada")
	var before: Dictionary = saved_data()
	block_temp_path()
	var failed_menu: Node = await load_menu()
	failed_menu.call("_on_new_game_pressed")
	await ticks(3)
	check(current_scene == failed_menu and not failed_menu._transitioning and progress().core_guardian_defeated and progress().has_reactor_key and progress().has_temporal_lens and progress().has_cronal_sword and progress().dialogue_completed("k2_continuity") and progress().tutorial_completed("move") and saved_data() == before,"Nueva Partida fallida revierte victoria y todo el progreso, sin transición ni modificar disco")
	unblock_temp_path()
	failed_menu.call("_on_new_game_pressed")
	await ticks(8)
	check(current_scene.scene_file_path == "res://scenes/Room1_Tutorial.tscn" and not progress().core_guardian_defeated and not progress().has_cronal_sword and not progress().has_temporal_lens and not progress().has_reactor_key and progress().completed_dialogues.is_empty() and not progress().tutorial_completed("move"),"Nueva Partida real restablece todos los estados según contrato")
	check(not saved_data()["core_guardian_defeated"],"Nueva Partida guarda victoria false en disco")
	await enter_from_room4() # Explicit new-run progression fixture, no victory grant.
	check(boss.visible and boss.health == 6 and boss.combat_phase == 1 and not room.room_cleared and room.get_node("EncounterTrigger").monitoring,"Fixture de progresión nueva recupera jefe6, Etapa1 y trigger")
	await capture("new_game_boss_available")
	await activate_naturally()
	check(boss.cycle_running and room.encounter_cycle_starts == 1 and not progress().core_guardian_defeated,"Jefe disponible nuevamente por entrada física")
	room.cancel_encounter()
	check(not progress().core_guardian_defeated,"Cancelación no concede victoria")
	write_report("new_game",{"menu_rollback_io_failure":true,"new_game_reset":true,"boss_available":true})

func compatibility_and_negatives() -> void:
	await dispose_scene()
	var old: Dictionary = {"version":1,"has_cronal_sword":true,"has_temporal_lens":true,"has_reactor_key":true,"completed_tutorials":{"move":true,"room4_past":true},"completed_dialogues":{"old_dialogue":true}}
	var file: FileAccess = FileAccess.open("user://progress_v1.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	progress().core_guardian_defeated = true # Missing-field fallback must overwrite this.
	check(progress().load_progress() and not progress().core_guardian_defeated and progress().has_reactor_key and progress().has_temporal_lens and progress().has_cronal_sword and progress().tutorial_completed("move") and progress().tutorial_completed("room4_past") and progress().dialogue_completed("old_dialogue"),"v1 sin campo nuevo carga false conservando posesiones/tutoriales/diálogos")
	await fresh_room5()
	check(boss.visible and boss.health == 6 and not room.room_cleared,"Guardado antiguo mantiene encuentro disponible")
	boss.defeated.emit() # Invalid notification, no terminal health/state.
	boss.play_diagnostic(&"exit")
	await ticks(90)
	check(not progress().core_guardian_defeated and room.victory_save_attempts == 0 and room.encounter_state == room.EncounterState.INACTIVE,"Animación diagnóstica y señal falsa sin DEFEATED no conceden victoria")
	await dispose_scene()
	seed_profile()
	await fresh_room5()
	boss.health = 0 # Explicit visual-only fixture, no confirmed terminal event.
	await ticks(10)
	check(not progress().core_guardian_defeated and room.victory_save_attempts == 0,"Barra cero preparada visualmente no concede victoria")
	await dispose_scene()
	await enter_from_room4()
	await activate_naturally()
	room.queue_free() # Explicit scene-interruption fixture, no forced unlocked transition.
	await ticks(3)
	check(not progress().core_guardian_defeated,"Interrumpir/cerrar la sala durante combate no concede victoria")
	await enter_from_room4()
	await activate_naturally()
	# Terminal-order fixture: controlled damage inputs, not the continuous sword run.
	boss.health = 1
	boss.state = boss.State.VULNERABLE
	boss.core_exposed = true
	player.take_damage(3)
	boss.take_damage(1)
	check(player.health == 0 and boss.state == boss.State.DEFEATED and not progress().core_guardian_defeated,"Muerte Player primero: terminal posterior del jefe no concede victoria")
	await dispose_scene()
	await enter_from_room4()
	await activate_naturally()
	boss.health = 1
	boss.state = boss.State.VULNERABLE
	boss.core_exposed = true
	boss.take_damage(1)
	player.take_damage(3)
	check(boss.state == boss.State.DEFEATED and progress().core_guardian_defeated and saved_data()["core_guardian_defeated"],"DEFEATED del jefe primero con Player vivo: victoria confirmada sobrevive muerte posterior")
	await dispose_scene()

func failure_case(recover: bool) -> void:
	check(progress().new_game(),"Perfil nuevo para fallo IO de victoria")
	seed_profile()
	check(progress().save_progress(),"Progreso previo al fallo IO guardado")
	var before: Dictionary = saved_data()
	block_temp_path()
	await combat_route()
	check(not terminal_snapshot["persisted"] and not terminal_snapshot["disk"] and not progress().core_guardian_defeated and room.victory_save_attempts == 1 and saved_data() == before,"Fallo real de apertura temporal revierte victoria permanente y conserva derrota local")
	check(room.get_node("ExitBlockHint").panel.visible and room.get_node("ExitBlockHint").label.text.contains("NO SE PUDO GUARDAR"),"Fallo de persistencia informa discretamente sin éxito falso")
	if recover:
		unblock_temp_path()
	await ticks(130)
	await wait_exit()
	check(room.victory_save_attempts == 2,"Un único reintento acotado, sin bucle de escritura")
	if recover:
		check(progress().core_guardian_defeated and room.victory_persisted and saved_data()["core_guardian_defeated"],"Segundo intento confirma persistencia después de retirar fallo")
	else:
		check(not progress().core_guardian_defeated and not room.victory_persisted and boss.health == 0 and not boss.cycle_running and saved_data() == before,"Fallo persistente mantiene derrota local y salida libre sin conceder victoria guardada")
		unblock_temp_path()
		await fresh_room5()
		check(boss.visible and boss.health == 6 and not room.room_cleared,"Sin guardado confirmado, reconstruir permite reaparecer al jefe")
	await dispose_scene()

func write_report(label: String, data: Dictionary) -> void:
	var directory: String = "res://artifacts/room5_stage_k2"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var suffix: String = "_%dx%d" % [root.size.x,root.size.y] if captures else ""
	var file: FileAccess = FileAccess.open(directory+"/"+label+suffix+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"))
	file.close()

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_k2_work"):
		quit(2)
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--k2-stage="):
			stage = argument.trim_prefix("--k2-stage=")
	captures = OS.get_cmdline_user_args().has("--capture")
	physics_frame.connect(observe)
	match stage:
		"win": await win_stage()
		"resume": await resume_stage()
		"new_game": await new_game_stage()
		"failures":
			await compatibility_and_negatives()
			await failure_case(false)
			await failure_case(true)
			write_report("failures",{"old_v1":true,"terminal_order_fixtures":true,"real_io_failure_exhausted":true,"real_io_failure_recovered":true})
		_: check(false,"Etapa de prueba conocida")
	await dispose_scene()
	print("VICTORY_PERSISTENCE_RESULT stage=",stage," checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
