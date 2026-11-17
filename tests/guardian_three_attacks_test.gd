extends "res://tests/room5_dimensional_layout_test.gd"

var boss: Node2D
var vertical: Node2D
var horizontal: Node2D
var direct: Node2D
var captures: bool = false
var shots: Dictionary = {}
var simultaneous_danger: bool = false
var projectile_direction: Vector2
var direction_changed: bool = false
var poses: Array[int] = []
var invalid_core_damage: bool = false
var invalid_core_activation: bool = false
var previous_core_state: int = -1
var previous_dimension: int = -1
var guarded_states: Dictionary = {}
var sword_damage: Array[int] = []
var strike_positions: Array[Vector2] = []

func capture(label: String) -> void:
	if not captures or shots.has(label):
		return
	shots[label] = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/guardian_three_attacks/"+label+".png")

func sample() -> void:
	if not is_instance_valid(boss):
		return
	if boss.state != boss.State.VULNERABLE or manager.active_dimension != 0:
		var protected_health: int = boss.health
		boss.take_damage(1)
		invalid_core_damage = invalid_core_damage or boss.health != protected_health
		guarded_states[boss.State.keys()[boss.state]] = true
		# Deferred shape changes settle by the following physics step.
		if boss.state == previous_core_state and manager.active_dimension == previous_dimension:
			invalid_core_activation = invalid_core_activation or not boss.core_shape.disabled
	previous_core_state = boss.state
	previous_dimension = manager.active_dimension
	if horizontal.danger_height() >= 6 and vertical.danger_bounds().y >= 6:
		simultaneous_danger = true
	if horizontal.phase == &"active":
		call_deferred("capture","03_horizontal_activo")
	if vertical.phase == &"active":
		call_deferred("capture","01_vertical64")
	if direct.owned:
		if not poses.has(boss.sprite.frame):
			poses.append(boss.sprite.frame)
		if direct.phase == &"flight":
			if projectile_direction == Vector2.ZERO:
				projectile_direction = direct.direction
			elif not projectile_direction.is_equal_approx(direct.direction):
				direction_changed = true
			call_deferred("capture","05_proyectil")

func fresh_fixture() -> void:
	if is_instance_valid(room):
		room.queue_free()
		await ticks(3)
	var progress: Node = root.get_node("GameProgress")
	progress.core_guardian_defeated = false
	progress.has_cronal_sword = true
	progress.has_temporal_lens = true
	for key: String in progress.completed_tutorials:
		progress.completed_tutorials[key] = true
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	room.encounter_activation_enabled = false # Fixtures use actual boss API.
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	boss = room.get_node("CoreGuardian")
	vertical = boss.get_node("VerticalBurst")
	horizontal = boss.get_node("HorizontalLaser")
	direct = boss.get_node("DirectProjectile")
	await ticks(20)

func evade_height() -> void:
	Input.action_release("jump")
	await ticks(2)
	for i: int in range(30):
		if player.is_on_floor():
			break
		await ticks(1)
	check(player.is_on_floor(),"Evasión comienza sobre apoyo firme")
	await jump_to(373,480 if manager.active_dimension == 1 else 550,true)

func run() -> void:
	if not OS.get_user_data_dir().contains("three_attacks_work") and not OS.get_user_data_dir().contains("cycle60_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/guardian_three_attacks"))
	var progress: Node = root.get_node("GameProgress")
	check(progress.new_game(),"Perfil aislado nuevo")
	await fresh_fixture()
	check(boss.core_shape.shape is RectangleShape2D,"Area vulnerable rectangular de cuerpo completo")
	check(not room.get_node("FinalAccessDoor").is_unlocked(),"Puerta final bloqueada antes de vencer")
	boss.damage_accepted.connect(func(amount: int) -> void: sword_damage.append(amount))
	physics_frame.connect(sample)
	await walk(300)
	await jump_to(373,550,true)
	room.encounter_activation_enabled = true
	room._arm_encounter()
	# Physical trigger on the first cross-column jump starts the legitimate encounter.
	await jump_to(373,480,true)
	await jump_to(550,550,true,390)
	# Return to a reachable left support while the introduction finishes.
	await jump_to(373,550,false,550)
	var last_burst: int = -1
	var dodged_direct: bool = false
	for i: int in range(4300):
		if boss.state == boss.State.VULNERABLE:
			break
		if horizontal.phase == &"warning" and last_burst != vertical.burst_index:
			last_burst = vertical.burst_index
			call_deferred("capture","02_horizontal_aviso")
			await evade_height()
		elif direct.phase == &"prepare" and not dodged_direct:
			dodged_direct = true
			call_deferred("capture","04_disparo_preparacion")
			await ticks(39) # React to the visible release after the full0.6s warning.
			await evade_height()
			for wait_frame: int in range(150):
				if not direct.owned:
					break
				await ticks(1)
			break # Use the remaining return/opening time to approach the boss.
		else:
			await ticks(1)
	check(player.health > 0 and room.fall_recovery_count == 0,"Evasiones reales sin caídas ni teletransportaciones")
	check(vertical.damage_events == 0 and horizontal.damage_events == 0 and direct.damage_events == 0,"Los tres ataques se esquivan físicamente sin recibir daño")
	check(not simultaneous_danger,"Horizontal peligroso nunca coincide con columnas verticales peligrosas")
	check(direct.emissions == 1 and not direct.owned and not is_instance_valid(direct.packet),"Proyectil termina antes de apertura/sobrecalentamiento")
	check(not direction_changed and projectile_direction != Vector2.ZERO,"Dirección del proyectil queda fija al disparar")
	check(not poses.has(4) and not poses.has(5) and poses.has(2) and poses.has(3),"Attack3 usa preparación/disparo y evita cuadros recortados4/5")
	check(vertical.WIDTH_SCALE == 2.5,"Vertical usa nearest2,5x:80px visibles maximos")
	check(horizontal.WIDTH_SCALE == 1.0,"Horizontal usa nearest1x:32px visibles maximos")
	# Reach the strike platform with real inputs during the actual6s opening.
	# After nine bursts the dodge can end in Past: cross directly to T2 there.
	await jump_to(550,550,manager.active_dimension == 0,390)
	await jump_to(640,480,true)
	await jump_to(890,550,true,730)
	# Approach Strike from the lower Past platform before switching on shared ground.
	await walk(1120)
	for i: int in range(30):
		if player.is_on_floor() and absf(player.position.y-570.0) < 1.0:
			break
		await ticks(1)
	shift()
	await ticks(4)
	check(boss.state == boss.State.VULNERABLE and absf(boss.cycle_elapsed-45) < .02,"Ciclo45 con los tres ataques integrados")
	check((boss.core_shape.shape as RectangleShape2D).size.is_equal_approx(Vector2(146.25,114.0)) and boss.weakpoint.global_position.is_equal_approx(Vector2(1161.375,566.375)),"Rectangulo cubre pose visible transformada a escala real")
	await capture("06_sobrecalentamiento")
	for i: int in range(3):
		# Walk forward between hits; no teleporting or extending the six-second window.
		Input.action_press("move_right")
		await ticks(2)
		Input.action_release("move_right")
		await ticks(5)
		strike_positions.append(player.position)
		check(player.is_on_floor() and absf(player.position.y-570.0) < 1.0,"Tajo desde apoyo Strike: "+str(player.position))
		var before_sword: int = boss.health
		print("BODY_STRIKE x=",player.position.x," window_seconds=",boss.window_elapsed," hp=",before_sword)
		Input.action_press("attack")
		await ticks(2)
		Input.action_release("attack")
		await ticks(30)
		check(boss.health == before_sword-1,"Cada tajo real causa exactamente1HP")
	check(sword_damage == [1,1,1],"Tres tajos sin impactos duplicados")
	check(boss.health == 0 and progress.core_guardian_defeated,"Ruta al núcleo y tres golpes reales mantienen victoria persistente")
	await capture("07_derrota")
	await ticks(70)
	check(not vertical.enabled and not horizontal.enabled and not direct.owned and not room.exit_blocked,"Derrota limpia los tres ataques y libera salida")
	check(room.get_node("FinalAccessDoor").is_unlocked(),"Victoria real desbloquea puerta final tras la derrota")
	if OS.get_cmdline_user_args().has("--verify-ending-access"):
		await walk(1190)
		await ticks(10)
		var event: InputEventKey = InputEventKey.new()
		event.keycode = KEY_E
		event.pressed = true
		Input.parse_input_event(event)
		await ticks(2)
		event.pressed = false
		Input.parse_input_event(event)
		await ticks(3)
		check(current_scene.scene_file_path == "res://scenes/FinalRoom.tscn" and current_scene.get_node_or_null("Stage/Door") == null,"E tras tres tajos y victoria real entra directo al final sin puerta")
		current_scene.queue_free()
		await ticks(3)
		print("VICTORY_ENDING_ACCESS_RESULT failures=",failures)
		quit(0 if failures == 0 else 1)
		return
	var report: FileAccess = FileAccess.open("res://artifacts/guardian_three_attacks/results"+("_render" if captures else "")+".json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"player_hp":player.health,"boss_hp":boss.health,"persistent_victory":progress.core_guardian_defeated,"simultaneous_laser_danger":simultaneous_danger,"projectile_emissions":direct.emissions,"projectile_direction_changed":direction_changed,"attack3_poses":poses,"body_size":(boss.core_shape.shape as RectangleShape2D).size,"strike_positions":strike_positions,"sword_damage":sword_damage},"\t"))
	report.close()
	if not captures:
		await fixtures()
	check(not invalid_core_damage and not invalid_core_activation and guarded_states.has("OFFSCREEN") and guarded_states.has("CORE_OPENING"),"Nucleo desactivado y rechaza dano fuera de sobrecalentamiento en todos los estados recorridos")
	room.queue_free()
	await ticks(3)
	print("THREE_ATTACKS_RESULT failures=",failures)
	quit(0 if failures == 0 else 1)

func fixtures() -> void:
	await fresh_fixture()
	await walk(300)
	await jump_to(373,550,true)
	check(boss.start_combat_cycle(),"Fixture horizontal inicia ciclo real")
	await ticks(65)
	vertical.cancel()
	horizontal.lane_y = player.position.y
	horizontal._phase(&"warning")
	var before: int = player.health
	await ticks(70)
	check(player.health == before,"Advertencia y expansión horizontal sin daño")
	await ticks(60)
	check(player.health == before-1 and horizontal.damage_events == 1,"Barrida horizontal causa1HP real y no duplica daño")
	boss.stop_combat_cycle()
	check(horizontal.phase == &"off" and not horizontal.visible,"Cancelar elimina barrida horizontal")
	await fresh_fixture()
	await walk(300)
	vertical.process_mode = Node.PROCESS_MODE_DISABLED
	horizontal.process_mode = Node.PROCESS_MODE_DISABLED
	check(boss.start_combat_cycle(),"Fixture de proyectil inicia reloj real")
	await ticks(2496) # 41.6s: preparation is visible but has not fired.
	check(player.health == 3,"Sin daño antes de preparación del proyectil")
	await ticks(210)
	check(player.health == 2 and direct.damage_events == 1 and direct.emissions == 1,"Proyectil directo causa exactamente1HP real")
	check(not is_instance_valid(direct.packet) and not direct.owned,"Proyectil y cuerpo se recuperan antes del sobrecalentamiento")
	for i: int in range(400):
		if boss.state != boss.State.VULNERABLE:
			break
		await ticks(1)
	check(absf(boss.window_elapsed-6.0) < .02,"Ventana sin golpes conserva6s exactos")
	await ticks(50)
	check(boss.cycle_id == 2 and boss.cycle_running and boss.health == 3,"Sin derrotar al jefe reinicia otro ciclo45s")
	for i: int in range(4000):
		if direct.phase == &"flight" and is_instance_valid(direct.packet):
			break
		await ticks(1)
	check(is_instance_valid(direct.packet),"Fixture de cancelación alcanza proyectil en vuelo")
	var old_id: int = room.get_instance_id()
	player.take_damage(3) # Terminal-flow fixture while the real projectile is flying.
	await ticks(2)
	check(not direct.owned and not is_instance_valid(direct.packet) and not horizontal.enabled and not vertical.enabled,"Muerte cancela proyectil y ambos láseres inmediatamente")
	for i: int in range(240):
		if current_scene != null and current_scene.get_instance_id() != old_id:
			break
		await ticks(1)
	await ticks(15)
	room = current_scene
	boss = room.get_node("CoreGuardian")
	vertical = boss.get_node("VerticalBurst")
	horizontal = boss.get_node("HorizontalLaser")
	direct = boss.get_node("DirectProjectile")
	check(room.get_instance_id() != old_id and not direct.owned and not is_instance_valid(direct.packet) and not horizontal.visible and not vertical.visible,"Reintento no hereda proyectil ni láseres anteriores")
	await width_fixtures()

func width_fixtures() -> void:
	await fresh_fixture()
	# Exact edge-overlap fixtures. The main route above uses normal Player movement.
	player.set_physics_process(false)
	vertical.set_physics_process(false)
	horizontal.set_physics_process(false)
	direct.set_physics_process(false)
	var source: Image = (vertical.textures[&"active"] as Texture2D).get_image()
	if source.is_compressed():
		source.decompress()
	check(source.get_used_rect().size.x*vertical.WIDTH_SCALE == 80.0,"Alfa visible vertical y hitbox comparten80px")
	vertical.enabled = true
	vertical.columns.assign([300.0])
	vertical._set_phase(&"active")
	player.position = Vector2(353,600)
	await ticks(2)
	vertical._damage_players(vertical.danger_bounds())
	check(player.health == 3,"Fuera de los80px verticales no hay dano")
	player.position = Vector2(350,600)
	await ticks(2)
	vertical._damage_players(vertical.danger_bounds())
	check(player.health == 2,"Borde visible nuevo del vertical causa1HP real")
	vertical.cancel()
	player.health = 3
	player.invulnerability_frames_remaining = 0
	horizontal.enabled = true
	horizontal.front = 0.0
	horizontal.lane_y = 600.0
	horizontal._phase(&"active")
	player.position = Vector2(300,563)
	await ticks(2)
	horizontal._damage()
	check(player.health == 3,"Fuera de los32px horizontales no hay dano")
	player.position = Vector2(300,565)
	await ticks(2)
	horizontal._damage()
	check(player.health == 2,"Borde visible nuevo del horizontal causa1HP real")
	var finish: Image = (horizontal.textures["beam_finish"] as Texture2D).get_image()
	if finish.is_compressed():
		finish.decompress()
	horizontal.phase = &"finish"
	for index: int in range(6):
		horizontal.frame = index
		var height: int = finish.get_region(Rect2i(index*64,0,64,64)).get_used_rect().size.y
		check(horizontal.danger_height() == height*horizontal.WIDTH_SCALE,"Contraccion horizontal coincide con alfa cuadro"+str(index))
	horizontal._cancel()
