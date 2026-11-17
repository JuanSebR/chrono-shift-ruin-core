extends "res://tests/room5_encounter_activation_test.gd"

func capture(label: String) -> void:
	if label in ["11_player_derrotado","12_reintento_limpio"]:
		await super.capture("retry_" + label)

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_k1_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	await enter_from_room4()
	await activate_naturally()
	var old_room: WeakRef = weakref(room)
	var old_player: WeakRef = weakref(player)
	var old_boss: WeakRef = weakref(boss)
	var old_hud: WeakRef = weakref(room.get_node("BossHUD"))
	var old_scene_id: int = room.get_instance_id()
	var damage_events: Array[int] = []
	player.damage_taken.connect(func(hp: int) -> void: damage_events.append(hp))
	for step: int in range(3500):
		if player.health == 0:
			break
		await ticks(1)
	check(player.health == 0 and damage_events == [2,1,0],"Tres impactos reales del Guardián derrotan al Player")
	await ticks(2)
	check(room.encounter_state == room.EncounterState.PLAYER_DEFEATED and not boss.cycle_running and not boss.arc_running and not boss.beam_running and not boss.core_exposed,"Derrota limpia selección, peligros y vulnerabilidad")
	check(boss.health == 6 and room.get_node("BossHUD").destruction_plays == 0 and not room.get_node("BossHUD").anchor.visible,"Derrota Player no simula victoria ni destrucción de BossHUD")
	check(player.presentation == &"defeat" and not room.get_node("GuardianHint").panel.visible,"Presentación de derrota original, sin nuevas instrucciones de ataque")
	await capture("11_player_derrotado")
	for step: int in range(300):
		if current_scene != null and current_scene.get_instance_id() != old_scene_id:
			break
		await ticks(1)
	check(current_scene != null and current_scene.get_instance_id() != old_scene_id and current_scene.scene_file_path == "res://scenes/Room5.tscn","Reintento automático heredado recarga Room5 localmente")
	adopt_room5()
	await ticks(20)
	check(old_room.get_ref() == null and old_player.get_ref() == null and old_boss.get_ref() == null and old_hud.get_ref() == null,"Instancia anterior y señales se liberan")
	check(player.health == 3 and boss.health == 6 and boss.combat_phase == 1 and not boss.core_exposed,"Reintento restaura Player3, jefe6 y Etapa1 protegida")
	check(player.position.distance_to(Vector2(140,600)) < 1 and manager.active_dimension == 0 and manager.switch_cooldown_remaining == 0 and not manager.switch_requested and not player.is_temporally_protected(),"Spawn limpio en Presente sin Shift, cooldown o protección heredados")
	check(not boss.cycle_running and not room.get_node("BossHUD").anchor.visible and not boss.get_node("ArcAttack").visible and not boss.get_node("BeamAttack").visible,"HUD y peligros limpios")
	check(room.encounter_state == room.EncounterState.INACTIVE and room.encounter_activation_count == 0 and room.get_node("EncounterTrigger").monitoring and room.get_node("RoomTransitions/ToRoom4").monitoring,"Trigger rearmado y salida disponible antes del segundo intento")
	var progress: Node = root.get_node("GameProgress")
	check(progress.has_cronal_sword and progress.has_temporal_lens and progress.has_reactor_key,"Espada, Lente y Llave sobreviven sin guardar otra victoria")
	check(room.find_children("Player","",true,false).size() == 1 and room.find_children("CoreGuardian","",true,false).size() == 1,"Reintento no duplica Player ni Guardián")
	await capture("12_reintento_limpio")
	await activate_naturally()
	await wait_state(boss.State.CANNON_AIM)
	check(room.encounter_cycle_starts == 1 and room.encounter_activation_count == 1 and boss.cycle_attacks == 1,"Segundo intento se activa naturalmente y ejecuta primer ataque único")
	check(not FileAccess.file_exists("user://progress_v1.json"),"Reintento no escribe progreso permanente")
	room.cancel_encounter()
	room.queue_free()
	await ticks(3)
	print("RETRY_RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
