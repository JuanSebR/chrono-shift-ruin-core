extends SceneTree

var room: Node2D
var player: CharacterBody2D
var boss: Node2D
var manager: Node
var trial: Dictionary = {}
var results: Array[Dictionary] = []
var frames: int = 0
var failures: int = 0
var checks: int = 0
var recording: bool = false
var captures: bool = false
var previous_state: int = -1
var previous_player_hp: int = 3
var i2: bool = false
var fixed_approach: bool = false

func output_directory() -> String:
	return "res://artifacts/room5_stage_i2" if i2 else "res://artifacts/room5_stage_i1"

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

func observe() -> void:
	if not recording or not is_instance_valid(boss):
		return
	frames += 1
	var name: String = boss.State.keys()[boss.state]
	trial["state_steps"][name] = int(trial["state_steps"].get(name,0)) + 1
	if player.is_on_floor() and player.position.y < 579:
		trial["platform_steps"] += 1
	if player.health < previous_player_hp:
		trial["damage_received"] += previous_player_hp - player.health
	previous_player_hp = player.health
	if boss.state != previous_state:
		trial["events"].append({"seconds":float(frames)/60.0,"state":name,"boss_hp":boss.health,"player_hp":player.health,"position":[player.position.x,player.position.y],"approach_budget":boss.approach_selected_duration if i2 else 4.75})
		if boss.state == boss.State.BEAM_PREPARE:
			trial["beams"] += 1
		if boss.state == boss.State.CANNON_AIM:
			trial["arcs"] += 1
		if boss.state == boss.State.VULNERABLE:
			trial["windows"] += 1
		previous_state = boss.state
		if i2 and captures:
			if name == "CANNON_AIM" and trial["arcs"] == 1:
				capture("04_ataque")
			elif name == "CANNON_AIM" and trial["arcs"] == 2:
				capture("09_siguiente_ciclo")
			elif name == "APPROACH" and trial["arcs"] == 1:
				capture("05_approach_lejos")
			elif name == "APPROACH" and trial["arcs"] == 2:
				capture("06_approach_cerca")
			elif name == "CORE_OPENING" and trial["windows"] == 0:
				capture("07_descenso")
			elif name == "VULNERABLE" and trial["windows"] == 1:
				capture("08_nucleo_expuesto")

func alive() -> bool:
	return is_instance_valid(boss) and boss.health > 0 and player.health > 0 and current_scene == room

func wait_state(value: int) -> bool:
	for index: int in range(1000):
		if not alive():
			return false
		if boss.state == value:
			return true
		await ticks(1)
	return false

func wait_age(age: float) -> bool:
	for index: int in range(200):
		if not alive():
			return false
		if boss.beam_elapsed >= age:
			return true
		await ticks(1)
	return false

func shift() -> void:
	trial["shift_requests"] += 1
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
	recording = false
	for action: String in ["jump","attack","move_left","move_right"]:
		Input.action_release(action)
	if is_instance_valid(room):
		room.queue_free()
		await ticks(3)
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	boss = room.get_node("CoreGuardian")
	if OS.get_cmdline_user_args().has("--phase-one-only"):
		boss.cycle_phase_two_enabled = false
	if i2:
		boss.cycle_adaptive_approach_enabled = not fixed_approach
	manager = room.get_node("DimensionManager")
	await ticks(20)

func capture(label: String) -> void:
	if not captures or trial.get("id","") != "A":
		return
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var directory: String = output_directory()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	check(picture.save_png("%s/%s_%dx%d.png" % [directory,label,picture.get_width(),picture.get_height()]) == OK,"Captura diagnóstica " + label)

func sword() -> void:
	trial["sword_input_requests"] += 1
	Input.action_press("jump")
	await ticks(20)
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	await ticks(13)
	if trial["windows"] == 1 and trial["hits"] == 1:
		await capture("02_impacto_continuo")
	await ticks(15)
	Input.action_release("jump")

func attempt(id: String, hits_per_window: int, use_shift: bool, skips: Array[int], stationary: bool = false) -> void:
	await fresh()
	check(player.position == Vector2(140,600) and player.health == 3 and boss.health == 6 and boss.state == boss.State.IDLE,"Inicio íntegro intento " + id)
	trial = {"id":id,"hits_per_window_policy":hits_per_window,"shift_policy":use_shift,"planned_skips":skips,"stationary":stationary,"beams":0,"arcs":0,"windows":0,"hits":0,"sword_input_requests":0,"slashes_emitted":0,"damage_received":0,"shift_requests":0,"shift_confirmed":0,"shift_rejected":0,"platform_steps":0,"state_steps":{},"events":[],"travel_segments":[]}
	if i2:
		trial["approach_mode"] = "fixed" if fixed_approach else "adaptive"
	frames = 0
	previous_state = -1
	previous_player_hp = 3
	boss.damage_accepted.connect(func(amount: int) -> void: trial["hits"] += amount)
	player.energy_slash_used.connect(func() -> void: trial["slashes_emitted"] += 1)
	manager.dimension_changed.connect(func(_present: bool) -> void: trial["shift_confirmed"] += 1)
	manager.dimension_change_rejected.connect(func() -> void: trial["shift_rejected"] += 1)
	recording = true
	check(boss.start_combat_cycle(),"Activación explícita intento " + id)
	await capture("01_inicio_6HP")
	if stationary:
		for index: int in range(12000):
			if not alive():
				break
			await ticks(1)
	else:
		for cycle: int in range(16):
			if not await wait_state(boss.State.CANNON_AIM):
				break
			# Same approved attack, read-only prediction for the diagnostic input policy.
			var arc: Node2D = boss.get_node("ArcAttack")
			await wait_age(.30)
			var duration: float = maxf(.45,2.0 * maxf(arc.p0.distance_to(arc.p1),arc.p1.distance_to(arc.p2))/1400.0)
			var jump_age: float = 1.0 + duration - (.50 if player.position.x > 1000 else .28)
			await wait_age(jump_age)
			Input.action_press("jump")
			await ticks(25)
			Input.action_release("jump")
			if not await wait_state(boss.State.APPROACH):
				break
			var travel_start: int = frames
			var from_x: float = player.position.x
			if use_shift:
				await shift()
			Input.action_press("move_right")
			for index: int in range(280):
				if player.position.x >= 1044 or not alive():
					break
				await ticks(1)
			Input.action_release("move_right")
			await ticks(8)
			if use_shift:
				await shift()
			trial["travel_segments"].append({"window":cycle+1,"from_x":from_x,"to_x":player.position.x,"seconds_including_shift_braking":float(frames-travel_start)/60.0})
			if not await wait_state(boss.State.VULNERABLE):
				break
			if not skips.has(cycle+1):
				for hit: int in range(hits_per_window):
					if not alive():
						break
					await sword()
			if not alive():
				break
			if not await wait_state(boss.State.CYCLE_WAIT):
				break
	recording = false
	trial["duration_seconds"] = float(frames)/60.0
	trial["boss_final_hp"] = boss.health
	trial["player_final_hp"] = player.health
	trial["defeated_state"] = boss.state == boss.State.DEFEATED
	trial["result"] = "boss_defeated" if boss.health == 0 and boss.state == boss.State.DEFEATED else ("player_defeated" if player.health == 0 else "incomplete")
	trial["missed_slashes"] = int(trial["slashes_emitted"]) - int(trial["hits"])
	trial["integrity_max_health"] = boss.max_health
	results.append(trial.duplicate(true))
	print("ATTEMPT ",JSON.stringify(trial))
	await capture("03_resultado_" + trial["result"])
	check(boss.max_health == 6 and trial["hits"] == 6-boss.health,"Contabilidad de daño real " + id)
	boss.stop_combat_cycle()
	check(not boss.arc_running and not boss.beam_running and not boss.cycle_running,"Limpieza final " + id)

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_i1_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	i2 = OS.get_cmdline_user_args().has("--i2")
	fixed_approach = OS.get_cmdline_user_args().has("--fixed-approach")
	root.get_node("GameProgress").has_temporal_lens = true
	root.get_node("GameProgress").has_cronal_sword = true
	physics_frame.connect(observe)
	if OS.get_cmdline_user_args().has("--eligibility-only"):
		await probe_eligibility()
		return
	# Predeclared independent policies. No failure is retried within an attempt.
	await attempt("A",2,true,[])
	if not captures:
		await attempt("B",2,false,[])
		await attempt("C",1,false,[])
		await attempt("D",2,false,[3,6])
		await attempt("E",0,false,[],true)
	var directory: String = output_directory()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var suffix: String = "_fixed" if i2 and fixed_approach else ""
	var file: FileAccess = FileAccess.open(directory + ("/render_attempts" if captures else "/attempts") + suffix + ".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	file.close()
	check(not FileAccess.file_exists("user://progress_v1.json"),"Sin escritura permanente de progreso")
	if i2 and captures:
		# Independent cleanup fixture, after the continuous result is already saved.
		await fresh()
		boss.start_combat_cycle()
		await wait_state(boss.State.CANNON_AIM)
		await wait_age(.50)
		boss.stop_combat_cycle()
		await capture("10_stop_fixture_separado")
	room.queue_free()
	await ticks(3)
	print("PLAYTEST_RESULT checks=",checks," infrastructure_failures=",failures)
	quit(0 if failures == 0 else 1)

func probe_eligibility() -> void:
	await fresh()
	player.set_physics_process(false)
	var rows: Array[Dictionary] = []
	var samples: Dictionary = {"F0":Vector2(400,600),"R1":Vector2(380,540),"R2":Vector2(860,540),"P1":Vector2(580,480),"T1_location":Vector2(780,480),"air_high":Vector2(600,460),"behind":Vector2(1150,600),"upper_edge":Vector2(600,480),"lower_edge":Vector2(600,544),"below_band":Vector2(600,545)}
	for dimension: int in range(2):
		if dimension == 1:
			player.position = Vector2(400,600)
			trial = {"shift_requests":0}
			await shift()
		for label: String in samples:
			player.position = samples[label]
			await ticks(2)
			rows.append({"fixture":label,"position":[player.position.x,player.position.y],"dimension":manager.active_dimension,"beam_eligible":boss.beam_eligible(),"selection":String(boss.select_cycle_attack())})
	var directory: String = "res://artifacts/room5_stage_i1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file: FileAccess = FileAccess.open(directory + "/eligibility.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rows,"\t"))
	file.close()
	check(rows.size() == 20 and manager.active_dimension == 1,"Veinte fixtures de elegibilidad; Shift confirmado")
	room.queue_free()
	await ticks(3)
	print("PROBE_RESULT failures=",failures)
	quit(0 if failures == 0 else 1)
