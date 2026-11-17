extends "res://tests/guardian_three_attacks_test.gd"
## Exercises the actual development entry and F9 through Godot input dispatch.

const OUTPUT: String = "user://practice_verification/"
var trace: Array[Dictionary] = []
var offensive_frame: int = -1
var opening_frame: int = -1
var closing_frame: int = -1
var intro_seen: bool = false

func capture(label: String) -> void:
	if not captures or shots.has(label):
		return
	shots[label] = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + label + ".png")

func record_state(value: int) -> void:
	trace.append({"frame":Engine.get_physics_frames(),"state":boss.State.keys()[value]})
	if value == boss.State.INTRO:
		intro_seen = true
		call_deferred("capture","02_introduccion")
	if value == boss.State.EXITING and offensive_frame < 0:
		offensive_frame = Engine.get_physics_frames()
	if value == boss.State.VULNERABLE and opening_frame < 0:
		opening_frame = Engine.get_physics_frames()
	if value == boss.State.CORE_CLOSING and closing_frame < 0:
		closing_frame = Engine.get_physics_frames()

func press_restart() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_F9
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(2)
	event.pressed = false
	Input.parse_input_event(event)
	await ticks(18)

func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/ChronoShiftDev/Room5/"):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	captures = OS.get_cmdline_user_args().has("--capture")
	var progress: Node = root.get_node("GameProgress")
	var entry: Node = load("res://tools/dev/Room5Practice.tscn").instantiate()
	root.add_child(entry)
	current_scene = entry
	await ticks(20)
	room = current_scene
	var controller: Node = root.get_node("PracticeController")
	check(controller.restart_count == 1 and controller._isolated_profile(),"Acceso confirma user:// aislado antes de escribir")
	player = room.get_node("Player")
	check(player.health == 3 and player.position.is_equal_approx(Vector2(140,600)) and room.get_node("DimensionManager").active_dimension == 0,"Entrada normal con3HP en Presente")
	check(progress.record_core_guardian_victory(),"Victoria de prueba se guarda por API de produccion")
	var stored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://progress_v1.json"))
	check(stored.core_guardian_defeated,"Victoria escrita exclusivamente en perfil aislado")
	await press_restart()
	room = current_scene
	check(controller.restart_count == 2 and not progress.core_guardian_defeated and room.get_node("Player").health == 3,"F9 restaura encuentro aun despues de guardar victoria")
	var backup: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://progress_v1.json.bak"))
	check(backup.core_guardian_defeated,"Rotacion .bak permanece dentro del perfil de pruebas")
	check(progress.has_cronal_sword and progress.has_temporal_lens and progress.has_reactor_key,"Espada, Lente y Llave desbloqueadas")
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	boss = room.get_node("CoreGuardian")
	vertical = boss.get_node("VerticalBurst")
	horizontal = boss.get_node("HorizontalLaser")
	direct = boss.get_node("DirectProjectile")
	check(boss.visible and boss.idle_visual.is_visible_in_tree() and not boss.cycle_running,"Guardian visible y quieto antes del trigger")
	check(room.encounter_activation_enabled and room.get_node("EncounterTrigger").monitoring,"Activacion natural de produccion habilitada")
	await capture("01_entrada")
	boss.state_changed.connect(record_state)
	physics_frame.connect(sample)
	await walk(300)
	await jump_to(373,550,true)
	await jump_to(373,480,true)
	await jump_to(550,550,true,390)
	await jump_to(373,550,false,550)
	var last_burst: int = -1
	var projectile_seen: bool = false
	var lasers_seen: bool = false
	for i: int in range(4300):
		if horizontal.phase == &"warning" and last_burst != vertical.burst_index:
			lasers_seen = true
			last_burst = vertical.burst_index
			await evade_height()
		elif direct.phase == &"prepare":
			projectile_seen = true
			await ticks(39)
			await evade_height()
			for wait_frame: int in range(150):
				if not direct.owned:
					break
				await ticks(1)
			break
		else:
			await ticks(1)
	check(intro_seen and room.encounter_activation_count == 1 and room.encounter_cycle_starts == 1,"Cruce fisico inicia intro y ciclo una sola vez")
	check(lasers_seen and projectile_seen and direct.emissions == 1,"Los tres ataques se ejecutan")
	check(not simultaneous_danger and not direction_changed,"Peligros y direccion del proyectil conservados")
	check(player.health == 3 and room.fall_recovery_count == 0,"Evasion por movimiento, salto y Shift sin caidas ni dano")
	if manager.active_dimension == 1:
		await jump_to(373,480,true)
	await jump_to(550,550,true,390)
	await jump_to(640,480,true)
	await jump_to(890,550,true,730)
	await jump_to(980,480,true)
	await walk(1120)
	await ticks(12)
	check(boss.state == boss.State.VULNERABLE and opening_frame-offensive_frame == 2700,"Ofensiva dura45s y regresa a plataforma vulnerable")
	await capture("06_sobrecalentamiento")
	for i: int in range(400):
		if boss.state != boss.State.VULNERABLE:
			break
		await ticks(1)
	check(closing_frame-opening_frame == 360 and not boss.core_exposed,"Sobrecalentamiento dura6s")
	await ticks(50)
	check(boss.cycle_running and boss.state == boss.State.EXITING,"Sin golpes reinicia ofensiva")
	await press_restart()
	room = current_scene
	check(controller.restart_count == 3 and room.get_node("CoreGuardian").visible and not room.get_node("CoreGuardian").cycle_running and room.get_node("Player").health == 3 and room.get_node("DimensionManager").active_dimension == 0,"F9 durante ofensiva restaura encuentro, salud y Presente")
	check(not room.get_node("CoreGuardian/VerticalBurst").enabled and not room.get_node("CoreGuardian/HorizontalLaser").enabled and not room.get_node("CoreGuardian/DirectProjectile").owned,"Reinicio elimina efectos de los tres ataques")
	await capture("07_reinicio_F9")
	var report: FileAccess = FileAccess.open(OUTPUT+"result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"user_data_dir":OS.get_user_data_dir(),"offensive_frames":opening_frame-offensive_frame,"overheat_frames":closing_frame-opening_frame,"restarts":controller.restart_count,"states":trace},"\t"))
	report.close()
	room.queue_free()
	controller.queue_free()
	await ticks(3)
	print("ROOM5_PRACTICE_RESULT failures=",failures)
	quit(0 if failures == 0 else 1)
