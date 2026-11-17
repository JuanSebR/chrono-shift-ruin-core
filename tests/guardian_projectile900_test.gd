extends "res://tests/guardian_three_attacks_test.gd"

var observing: bool = false
var shot_locked: Vector2 = Vector2.ZERO
var trajectory_changed: bool = false
var passed_player: bool = false
var near_protection: bool = false
var emit_elapsed: float = -1.0
var case_results: Array[Dictionary] = []

func observe_projectile() -> void:
	if not observing or not is_instance_valid(direct) or not is_instance_valid(player):
		return
	if direct.phase == &"flight" and is_instance_valid(direct.packet):
		if shot_locked == Vector2.ZERO:
			shot_locked = direct.direction
			emit_elapsed = direct.elapsed
		trajectory_changed = trajectory_changed or not shot_locked.is_equal_approx(direct.direction)
		passed_player = passed_player or direct.packet.global_position.x < player.global_position.x-70.0
		if direct.packet.global_position.distance_to(player.global_position) < 120.0:
			near_protection = near_protection or player.is_temporally_protected() or player.invulnerability_frames_remaining > 0

func prepare_case(at: Vector2) -> void:
	observing = false
	await fresh_fixture()
	vertical.process_mode = Node.PROCESS_MODE_DISABLED
	horizontal.process_mode = Node.PROCESS_MODE_DISABLED
	# Initial fixture placement only; all subsequent evasions use Player inputs.
	player.position = at
	await ticks(15)
	check(player.is_on_floor(),"Apoyo inicial real "+str(player.position))
	check(boss.start_combat_cycle(),"Ciclo inicia para proyectil aislado")
	for i: int in range(2700):
		if direct.phase == &"prepare":
			break
		await ticks(1)
	check(direct.phase == &"prepare" and direct.emissions == 0 and player.health == 3,"Aviso visible antes de emitir o causar dano")
	shot_locked = Vector2.ZERO
	trajectory_changed = false
	passed_player = false
	near_protection = false
	emit_elapsed = -1.0
	observing = true

func key_event(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(2)
	event.pressed = false
	Input.parse_input_event(event)
	await ticks(18)

func run() -> void:
	if not OS.get_user_data_dir().contains("projectile900_work"):
		quit(2)
		return
	var progress: Node = root.get_node("GameProgress")
	check(progress.new_game(),"Perfil de proyectil aislado")
	physics_frame.connect(observe_projectile)
	var definitions: Array[Dictionary] = [
		{"name":"caminar_P4_a_entrada","position":Vector2(210,458),"delay":15},
		{"name":"salto_P5","position":Vector2(640,458),"delay":18},
		{"name":"Shift_P5_a_T2","position":Vector2(640,458),"delay":24},
		{"name":"salto_P6","position":Vector2(980,458),"delay":33},
	]
	for definition: Dictionary in definitions:
		await prepare_case(definition.position)
		await ticks(definition.delay)
		check(not direct.emitted and player.health == 3,"Tiempo real para reaccionar al aviso "+definition.name)
		if definition.name == "caminar_P4_a_entrada":
			Input.action_press("move_left")
		elif String(definition.name).begins_with("salto_"):
			Input.action_press("jump")
		else:
			shift()
		for i: int in range(200):
			if definition.name == "caminar_P4_a_entrada" and player.position.x <= 165.0:
				Input.action_release("move_left")
			if String(definition.name).begins_with("salto_") and i == 45:
				Input.action_release("jump")
			if not direct.owned:
				break
			await ticks(1)
		Input.action_release("move_left")
		Input.action_release("jump")
		await ticks(10)
		check(player.health == 3 and direct.damage_events == 0 and room.fall_recovery_count == 0,"Evasion fisica sin dano ni recuperaciones "+definition.name)
		check(passed_player and not near_protection,"El paquete pasa de largo sin depender de proteccion "+definition.name)
		check(not trajectory_changed and emit_elapsed >= 0.6-0.0001,"Direccion fija y preparacion completa0,6s")
		check(not direct.owned and not is_instance_valid(direct.packet) and boss.cycle_elapsed < boss.OPENING_START,"Paquete y recuperacion terminan antes de abrir cuerpo")
		check(direct.shape.size == Vector2(32,16) and direct.SPEED == 900.0,"Sprite32x16 e hitbox originales,900unidades/s")
		case_results.append({"case":definition.name,"reaction_seconds":float(definition.delay)/60.0,"emit_elapsed":emit_elapsed,"passed_player":passed_player,"near_protection":near_protection,"player_hp":player.health,"player_position":player.position,"finished_at":boss.cycle_elapsed,"direction_changed":trajectory_changed})
		print("PROJECTILE_CASE ",JSON.stringify(case_results[-1]))
	# Swept collision under a deliberately large physics step: endpoints skip Player.
	await prepare_case(Vector2(640,458))
	for i: int in range(60):
		if direct.phase == &"flight":
			break
		await ticks(1)
	check(direct.phase == &"flight" and player.health == 3,"Fixture de barrido alcanza disparo")
	direct._move_packet(0.65)
	check(player.health == 2 and direct.damage_events == 1 and direct.phase == &"recovery","Subpasos detectan Player atravesado por un salto de0,65s y causan solo1HP")
	await ticks(90)
	check(player.health == 2 and direct.damage_events == 1 and not direct.owned and not is_instance_valid(direct.packet),"Sin dano repetido ni paquete residual")
	observing = false
	# Use the actual F9 controller while the packet is still flying.
	check(change_scene_to_file("res://tools/dev/Room5Practice.tscn") == OK,"Carga acceso F9 real")
	await ticks(30)
	room = current_scene
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	boss = room.get_node("CoreGuardian")
	vertical = boss.get_node("VerticalBurst")
	horizontal = boss.get_node("HorizontalLaser")
	direct = boss.get_node("DirectProjectile")
	room.encounter_activation_enabled = false
	vertical.process_mode = Node.PROCESS_MODE_DISABLED
	horizontal.process_mode = Node.PROCESS_MODE_DISABLED
	check(boss.start_combat_cycle(),"F9 fixture inicia reloj real")
	for i: int in range(2700):
		if direct.phase == &"flight":
			break
		await ticks(1)
	var old_packet: Sprite2D = direct.packet
	check(is_instance_valid(old_packet),"Proyectil existe antes de F9")
	await key_event(KEY_F9)
	room = current_scene
	check(not is_instance_valid(old_packet) and not room.get_node("CoreGuardian/DirectProjectile").owned and room.get_node("Player").health == 3,"F9 elimina proyectil en vuelo y restaura Player")
	var report: FileAccess = FileAccess.open("res://artifacts/guardian_projectile900/cases.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"cases":case_results,"swept_collision":true,"F9_in_flight":true},"\t"))
	report.close()
	room.queue_free()
	root.get_node("PracticeController").queue_free()
	await ticks(3)
	print("PROJECTILE900_RESULT failures=",failures)
	quit(0 if failures == 0 else 1)
