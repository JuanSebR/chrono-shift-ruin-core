extends SceneTree

var room: Node2D
var player: CharacterBody2D
var boss: Node2D
var manager: Node
var checks: int = 0
var failures: int = 0
var routes: Array[Dictionary] = []

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

func wait_state(value: int) -> void:
	for index: int in range(900):
		if boss.state == value:
			return
		await ticks(1)
	check(false,"Estado alcanzado " + str(value))

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
	for action: String in ["move_right","move_left","jump","attack"]:
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

func prepare(position: Vector2, past: bool = false, fixed: bool = false) -> void:
	await fresh()
	boss.cycle_adaptive_approach_enabled = not fixed
	# Independent fixture: freeze the attack target on the right before placing the
	# route start. After APPROACH begins, all movement below is real Input/physics.
	player.position = Vector2(1150,600)
	player.velocity = Vector2.ZERO
	await ticks(12)
	boss.start_combat_cycle()
	await wait_state(boss.State.CANNON_AIM)
	await ticks(23)
	if past:
		shift()
		await ticks(18)
	player.position = position
	player.velocity = Vector2.ZERO
	await ticks(20)
	await wait_state(boss.State.APPROACH)

func sword() -> void:
	Input.action_press("jump")
	await ticks(20)
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	await ticks(28)
	Input.action_release("jump")

func route(label: String, position: Vector2, expected: float, past: bool = false, paired_shift: bool = false) -> void:
	await prepare(position,past)
	var budget: float = boss.beam_duration
	var reason: String = String(boss.approach_reason)
	var sample: Vector2 = boss.approach_sample_position
	var start_frame: int = Engine.get_physics_frames()
	check(absf(budget - expected) < .03 and boss.approach_samples == 1 and not boss.core_exposed,"Presupuesto y muestra única " + label)
	if paired_shift:
		shift()
		await ticks(18)
	var direction: String = "move_left" if player.position.x > 1062 else "move_right"
	Input.action_press(direction)
	for index: int in range(300):
		if (direction == "move_right" and player.position.x >= 1044) or (direction == "move_left" and player.position.x <= 1062):
			break
		await ticks(1)
	Input.action_release(direction)
	await ticks(8)
	if manager.active_dimension == 1:
		shift()
		await ticks(18)
	# Face the actual core after the rear-route fixture.
	Input.action_press("move_right")
	await ticks(1)
	Input.action_release("move_right")
	var arrival: float = float(Engine.get_physics_frames()-start_frame)/60.0
	check(boss.state == boss.State.APPROACH and boss.beam_duration == budget and boss.approach_sample_position == sample and boss.approach_samples == 1,"Llegada física antes del descenso sin recalcular " + label)
	await wait_state(boss.State.CORE_OPENING)
	var opening_frame: int = Engine.get_physics_frames()
	check(not boss.core_exposed,"Descenso protegido " + label)
	await wait_state(boss.State.VULNERABLE)
	var exposed_frame: int = Engine.get_physics_frames()
	check(absi(exposed_frame-opening_frame-45) <= 2,"Descenso original .75s " + label)
	var hp: int = boss.health
	await sword()
	var first: int = hp - boss.health
	await sword()
	var hits: int = hp - boss.health
	check(first == 1 and hits == 2 and manager.active_dimension == 0,"Dos tajos reales en Presente " + label)
	await wait_state(boss.State.CORE_CLOSING)
	check(absi(Engine.get_physics_frames()-exposed_frame-120) <= 2 and not boss.core_exposed,"Exposición original 2s y cierre " + label)
	var close_frame: int = Engine.get_physics_frames()
	await wait_state(boss.State.CYCLE_WAIT)
	check(absi(Engine.get_physics_frames()-close_frame-54) <= 2,"Retorn .5s más descanso .4s " + label)
	routes.append({"fixture":label,"sample":[sample.x,sample.y],"budget":budget,"reason":reason,"arrival_seconds":arrival,"hits":hits,"player_hp":player.health,"samples":boss.approach_samples})
	print("ROUTE ",JSON.stringify(routes.back()))
	await wait_state(boss.State.CANNON_AIM)
	check(boss.cycle_attacks == 2,"Siguiente ciclo completo " + label)
	boss.stop_combat_cycle()

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_i2_work"):
		quit(2)
		return
	root.get_node("GameProgress").has_temporal_lens = true
	root.get_node("GameProgress").has_cronal_sword = true
	await fresh()
	check(boss.state == boss.State.IDLE and not boss.cycle_running and boss.approach_samples == 0,"Carga pasiva sin muestra ni activación")
	check(boss.cycle_adaptive_approach_enabled and boss.cycle_approach_time == 4.75 and boss.cycle_approach_min_time == 1.25,"Configuración adaptativa y límites originales")
	var candidate_spawn: float = absf(140.0 - 1049.092875)/240.0 + .85
	check(candidate_spawn > 4.63 and candidate_spawn < 4.65,"Candidato spawn 4.638s: margen estrecho, se conserva 4.75s")
	await prepare(Vector2(1049,600),false,true)
	check(boss.beam_duration == 4.75 and boss.approach_reason == &"fixed","Compatibilidad fija sin restaurar código")
	boss.stop_combat_cycle()
	await route("spawn_fixture",Vector2(140,600),4.75,false,true)
	await route("central",Vector2(600,600),2.7212,false,true)
	await route("near_core",Vector2(1049,600),1.25,false,true)
	await route("R1",Vector2(380,540),4.75)
	await route("R2",Vector2(860,540),4.75)
	await route("P1_present",Vector2(580,480),4.75)
	await route("T1_past",Vector2(780,480),4.75,true)
	await route("behind",Vector2(1150,600),4.75)
	await prepare(Vector2(1049,600))
	var duration: float = boss.beam_duration
	var initial_age: float = boss.beam_elapsed
	shift()
	await ticks(2)
	check(manager.active_dimension == 1 and player.is_temporally_protected() and boss.beam_elapsed > initial_age and boss.beam_duration == duration,"Shift real no reinicia reloj ni presupuesto")
	Input.action_press("move_left")
	await ticks(28)
	Input.action_release("move_left")
	shift()
	await ticks(2)
	check(manager.active_dimension == 0 and boss.beam_duration == duration and boss.approach_samples == 1,"Movimiento y regreso a Presente no recalculan")
	boss.stop_combat_cycle()
	boss.stop_combat_cycle()
	await ticks(4)
	check(boss.state == boss.State.IDLE and not boss.core_exposed and not boss.arc_running and not boss.beam_running and not player.is_connected("defeated",Callable(boss,"_on_cycle_player_defeated")),"Stop limpia APPROACH y señal del ciclo, idempotente")
	await prepare(Vector2(1049,600))
	player.take_damage(3)
	await ticks(2)
	check(not boss.cycle_running and not boss.core_exposed,"Derrota real del Player cancela aproximación")
	await prepare(Vector2(1049,600))
	boss.health = 0 # Independent terminal fixture, not continuous-combat proof.
	await ticks(2)
	check(boss.state == boss.State.DEFEATED and not boss.cycle_running and not boss.core_exposed,"Derrota jefe cancela aproximación")
	var file: FileAccess = FileAccess.open("res://artifacts/room5_stage_i2/routes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(routes,"\t"))
	file.close()
	check(not FileAccess.file_exists("user://progress_v1.json"),"Sin escritura de progreso")
	room.queue_free()
	await ticks(3)
	print("ADAPTIVE_RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
