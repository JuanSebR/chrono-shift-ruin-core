extends "res://tests/room5_dimensional_layout_test.gd"

var boss: Node2D
var attack: Node2D
var captures: bool = false
var seen_frames: Dictionary = {}
var maximum_columns: int = 0
var first_targets: Array[float] = []

func capture(label: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/guardian_vertical_burst/"+label+".png")

func observe_attack() -> void:
	if not is_instance_valid(attack):
		return
	maximum_columns = maxi(maximum_columns,attack.columns.size())
	if attack.phase in [&"expansion",&"contraction"]:
		seen_frames[String(attack.phase)+str(attack.frame)] = true

func wait_phase(value: StringName) -> void:
	for i: int in range(1000):
		if attack.phase == value:
			return
		await ticks(1)
	check(false,"Fase alcanzada " + String(value))

func run() -> void:
	if not OS.get_user_data_dir().contains("vertical_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/guardian_vertical_burst"))
	var progress: Node = root.get_node("GameProgress")
	progress.has_temporal_lens = true
	progress.has_cronal_sword = true
	progress.core_guardian_defeated = false
	for key: String in progress.completed_tutorials:
		progress.completed_tutorials[key] = true
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	boss = room.get_node("CoreGuardian")
	attack = boss.get_node("VerticalBurst")
	check(attack.WIDTH_SCALE == 2.5,"Visual e hitbox usan escala2,5:80px maximos")
	# Isolate the vertical contract; combined attack coverage has its own suite.
	boss.get_node("HorizontalLaser").process_mode = Node.PROCESS_MODE_DISABLED
	boss.get_node("DirectProjectile").process_mode = Node.PROCESS_MODE_DISABLED
	for animation: StringName in [&"expansion",&"contraction"]:
		var image: Image = (attack.textures[animation] as Texture2D).get_image()
		if image.is_compressed():
			image.decompress()
		check(image.get_size() == Vector2i(384,360),"Hoja original6x64 sin redimensionar " + String(animation))
		var bounds: Array = attack.EXPAND_BOUNDS if animation == &"expansion" else attack.CONTRACT_BOUNDS
		for index: int in range(6):
			var used: Rect2i = image.get_region(Rect2i(index*64,0,64,360)).get_used_rect()
			check(Vector2i(used.position.x,used.size.x) == bounds[index],"Hitbox coincide con alfa del cuadro " + String(animation)+str(index))
	physics_frame.connect(observe_attack)
	await ticks(20)
	await walk(300)
	check(player.is_on_floor() and room.fall_recovery_count == 0,"Acceso físico a P1 desde entrada")
	check(boss.start_combat_cycle(),"Ciclo real dispara slot vertical al salir")
	await wait_phase(&"warning")
	first_targets.assign(attack.columns)
	check(boss.state == boss.State.OFFSCREEN and boss.sprite.animation == &"exit_repose" and attack.columns == [300.0],"Jefe fuera con pose aérea, columna300 señalada")
	check(attack.danger_bounds() == Vector2i.ZERO,"Advertencia sin hitbox peligrosa")
	await capture("01_advertencia")
	await ticks(35)
	check(player.health == 3 and attack.damage_events == 0,"Permanecer dentro de la advertencia no causa daño")
	await jump_to(370,550,true)
	check(manager.active_dimension == 1 and room.fall_recovery_count == 0,"Salto y Shift reales permiten apoyo T1 durante evasión")
	await wait_phase(&"expansion")
	await ticks(20)
	await capture("02_expansion")
	await wait_phase(&"active")
	check(player.health == 3 and player.position.x > 345,"Evasión por salto/Shift conserva integridad al activarse")
	await capture("03_activo_evadido")
	await wait_phase(&"contraction")
	await ticks(13)
	await capture("04_contraccion")
	await wait_phase(&"rest")
	check(not attack.visible and attack.columns.is_empty(),"Desaparición completa tras contracción")
	await walk(300)
	await wait_phase(&"warning")
	check(attack.columns.size() == 2 and attack.columns.has(300.0),"Segunda ráfaga marca dos columnas y deja una libre")
	await capture("05_dos_columnas")
	await wait_phase(&"active")
	check(player.health == 2 and attack.damage_events == 1 and manager.active_dimension == 1,"Láser visible causa1HP real también en Pasado")
	await capture("06_impacto_real")
	await wait_phase(&"rest")
	check(player.health == 2 and attack.damage_events == 1,"Máximo un daño por ráfaga, sin acumular por cuadro/segmento")
	check(seen_frames.size() == 12,"Seis cuadros originales de expansión y seis de contracción observados")
	await wait_phase(&"warning")
	await wait_phase(&"active")
	boss._cancel_offensives()
	check(attack.phase == &"off" and not attack.visible and attack.columns.is_empty(),"Señal cancelled limpia inmediatamente visuales y daño")
	var hp: int = player.health
	await ticks(75)
	check(player.health == hp,"Sin daño residual después de cancelar")
	attack._on_slot(&"vertical_burst",boss.cycle_id-1)
	check(not attack.enabled,"Slot obsoleto de otro ciclo se rechaza")
	# Complete current45s clock without further slots after explicit cancellation.
	for i: int in range(4000):
		if boss.state == boss.State.VULNERABLE:
			break
		await ticks(1)
	check(boss.state == boss.State.VULNERABLE and attack.phase == &"off" and not attack.visible,"Sobrecalentamiento sin laser; ciclo45s")
	check(boss.health == 3 and boss.max_health == 3 and maximum_columns == 2,"3HP intactos, nunca tres columnas simultáneas")
	# Death cancellation fixture starts a fresh offscreen cycle through its real API.
	boss.stop_combat_cycle()
	check(boss.start_combat_cycle(),"Nuevo ciclo limpio tras detener")
	await wait_phase(&"warning")
	player.invulnerability_frames_remaining = 0 # Isolated terminal-order fixture only.
	player.take_damage(3)
	await ticks(2)
	check(not attack.enabled and attack.phase == &"off" and not boss.cycle_running,"Muerte del Player cancela advertencia y futuras ráfagas")
	var old_id: int = room.get_instance_id()
	for i: int in range(240):
		if current_scene != null and current_scene.get_instance_id() != old_id:
			break
		await ticks(1)
	await ticks(15)
	room = current_scene
	attack = room.get_node("CoreGuardian/VerticalBurst")
	check(room.get_instance_id() != old_id and not attack.enabled and not attack.visible and attack.columns.is_empty(),"Reintento no hereda láseres ni temporizadores anteriores")
	var report: FileAccess = FileAccess.open("res://artifacts/guardian_vertical_burst/results.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"max_columns":maximum_columns,"animated_frames":seen_frames.keys()},"\t"))
	report.close()
	room.queue_free()
	await ticks(3)
	print("VERTICAL_RESULT failures=",failures)
	quit(0 if failures == 0 else 1)
