extends SceneTree

var room: Node2D
var player: CharacterBody2D
var manager: Node
var failures: int = 0
var route: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func shift() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = KEY_SHIFT
	Input.parse_input_event(event)

func walk(x: float) -> void:
	var action: String = "move_right" if x > player.position.x else "move_left"
	Input.action_press(action)
	for i: int in range(250):
		if absf(player.position.x-x) < 16:
			break
		await ticks(1)
	Input.action_release(action)
	await ticks(12)

func jump_to(x: float, top: float, change: bool, running_edge: float = -1) -> void:
	if running_edge > 0:
		var right: bool = x > player.position.x
		Input.action_press("move_right" if right else "move_left")
		for i: int in range(180):
			if (right and player.position.x >= running_edge) or (not right and player.position.x <= running_edge):
				break
			await ticks(1)
	Input.action_press("jump")
	var apex: float = player.position.y
	for i: int in range(100):
		if change and i == 15:
			shift()
		if absf(player.position.x-x) > 10:
			Input.action_press("move_right" if player.position.x < x else "move_left")
		else:
			Input.action_release("move_right")
			Input.action_release("move_left")
		apex = minf(apex,player.position.y)
		await ticks(1)
		if i > 4 and player.is_on_floor():
			break
	Input.action_release("jump")
	Input.action_release("move_right")
	Input.action_release("move_left")
	await ticks(8)
	check(player.is_on_floor() and absf(player.position.y-(top-20)) < 2,"Salto físico a (%.1f, %.1f), dimensión%d" % [player.position.x,player.position.y,manager.active_dimension])
	route.append({"position":str(player.position),"dimension":manager.active_dimension,"apex_y":apex})

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/room5_dimensional_redesign/"+label+".png")

func run() -> void:
	if not OS.get_user_data_dir().contains("layout_work"):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/room5_dimensional_redesign"))
	var progress: Node = root.get_node("GameProgress")
	progress.has_cronal_sword = true
	progress.has_temporal_lens = true
	progress.has_reactor_key = true
	progress.core_guardian_defeated = false
	for key: String in progress.completed_tutorials:
		progress.completed_tutorials[key] = true
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	await ticks(20)
	check(player.is_on_floor() and player.position.distance_to(Vector2(140,600)) < 1,"Entrada segura sin suelo continuo")
	await capture("presente")
	await walk(300)
	await jump_to(300,550,true)
	check(manager.active_dimension == 1,"Shift durante ascenso activa Pasado")
	await capture("pasado")
	await jump_to(300,480,true)
	await jump_to(550,550,true,390)
	await jump_to(640,480,true)
	await jump_to(890,550,true,730)
	await jump_to(980,480,true)
	await walk(1120)
	await ticks(50)
	check(player.is_on_floor() and absf(player.position.y-570) < 2,"Llegada física al apoyo del núcleo")
	check(room.fall_recovery_count == 0,"Ruta sin caídas ni teletransportaciones")
	await capture("plataforma_jefe")
	# Start the real60s/6s cycle only after completing the geometric route.
	var boss: Node2D = room.get_node("CoreGuardian")
	check(boss.start_combat_cycle(),"Ciclo60s por API después de ruta geométrica")
	await ticks(3600)
	await ticks(2)
	for hit: int in range(3):
		Input.action_press("attack")
		await ticks(2)
		Input.action_release("attack")
		await ticks(30)
		print("SWORD_PROBE hp=",boss.health," player=",player.position," core=",boss.weakpoint.global_position," state=",boss.state," exposed=",boss.core_exposed)
	check(boss.health == 0,"Tres golpes reales de espada dentro del sobrecalentamiento6s")
	boss.stop_combat_cycle()
	await jump_to(980,550,true)
	shift()
	await ticks(40)
	check(player.is_on_floor() and absf(player.position.y-600) < 2,"P3 inferior alcanzable")
	await jump_to(980,550,true)
	await jump_to(730,550,false,880)
	shift()
	await ticks(40)
	check(player.is_on_floor() and absf(player.position.y-600) < 2,"P2 inferior alcanzable")
	await jump_to(640,550,true)
	await jump_to(390,550,false,540)
	shift()
	await ticks(40)
	await walk(180)
	check(player.is_on_floor() and room.fall_recovery_count == 0,"Regreso físico a entrada desde plataforma del jefe sin recuperaciones")
	# Isolated occupied-destination fixture, not part of the physical route.
	player.set_physics_process(false)
	player.position = Vector2(300,540)
	shift()
	await ticks(4)
	check(manager.active_dimension == 0,"Shift rechaza aparición dentro de T1")
	player.position = Vector2(140,600)
	player.set_physics_process(true)
	await ticks(5)
	shift()
	await ticks(20)
	# Falling safety fixture: walk off the top level into an intentional gap.
	player.position = Vector2(500,650)
	player.velocity = Vector2(0,200)
	await ticks(25)
	check(room.fall_recovery_count == 1 and player.position.distance_to(Vector2(140,600)) < 2 and manager.active_dimension == 0,"Caída recupera entrada/Presente sin pérdida de salud")
	check(player.health == 3 and boss.max_health == 3,"Salud Player3 y nuevo máximo del jefe3")
	# Actual doorway round trip; no scene handoff is synthesized.
	Input.action_press("move_left")
	for i: int in range(100):
		if current_scene != room:
			break
		await ticks(1)
	Input.action_release("move_left")
	await ticks(10)
	check(current_scene.scene_file_path == "res://scenes/Room4.tscn","Salida física a Room4")
	Input.action_press("move_right")
	for i: int in range(150):
		if current_scene.scene_file_path == "res://scenes/Room5.tscn":
			break
		await ticks(1)
	Input.action_release("move_right")
	await ticks(10)
	room = current_scene
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	check(player.position.distance_to(Vector2(180,600)) < 2 and player.is_on_floor(),"Llegada real desde Room4 segura")
	# Enable the production trigger after the separate diagnostic traversal.
	room.encounter_activation_enabled = true
	room._arm_encounter()
	await walk(300)
	await jump_to(300,550,true)
	await jump_to(300,480,true)
	await jump_to(550,550,true,390)
	await ticks(75)
	check(room.encounter_cycle_starts == 1 and room.encounter_state == room.EncounterState.ACTIVE and room.exit_blocked and room.get_node("BossHUD").anchor.visible,"Cruce físico conserva intro, ciclo único, BossHUD y bloqueo")
	var old_id: int = room.get_instance_id()
	player.take_damage(3) # Defeat-flow fixture; not a claim of natural boss damage.
	for i: int in range(240):
		if current_scene != null and current_scene.get_instance_id() != old_id:
			break
		await ticks(1)
	await ticks(15)
	room = current_scene
	player = room.get_node("Player")
	check(room.get_instance_id() != old_id and player.health == 3 and player.is_on_floor() and room.get_node("CoreGuardian").health == 3,"Reintento heredado reconstruye geometría y entrada segura")
	var file: FileAccess = FileAccess.open("res://artifacts/room5_dimensional_redesign/route.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(route,"\t"))
	file.close()
	room.queue_free()
	await ticks(3)
	print("LAYOUT_RESULT failures=",failures)
	quit(0 if failures == 0 else 1)
