extends "res://tests/core_guardian_phase_two_test.gd"

var hud: CanvasLayer
var hud_checks_running: bool = false
var hud_captures: Dictionary = {}
var visual_trace: Array[Dictionary] = []
var seen_destruction: Array[int] = []
var phase_one_at_six: bool = false
var phase_two_confirmed: bool = false
var premature_phase_two: bool = false
var layout_checked: bool = false
var layout_measurements: Dictionary = {}

func fresh() -> void:
	await super.fresh()
	hud = room.get_node("BossHUD")

func capture(label: String) -> void:
	var names: Dictionary = {"01_reposo_etapa1":"01_pasiva","03_transicion_sobrecarga":"05_transicion","08_expuesto_etapa2":"07_nucleo_expuesto"}
	if names.has(label):
		await hud_capture(names[label])

func hud_capture(label: String) -> void:
	if not captures or hud_captures.has(label):
		return
	hud_captures[label] = true
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var directory: String = "res://artifacts/room5_stage_j"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	check(picture.save_png("%s/%s_%dx%d.png" % [directory,label,picture.get_width(),picture.get_height()]) == OK,"HUD captura real " + label)

func observe() -> void:
	super.observe()
	if not hud_checks_running or not is_instance_valid(hud) or not is_instance_valid(boss):
		return
	var entry: Dictionary = {"hp":boss.health,"phase":boss.combat_phase,"text":hud.health_value.text,"phase_text":hud.phase_indicator.text,"visible":hud.anchor.visible,"destruction":hud.destruction_index}
	if visual_trace.is_empty() or visual_trace.back() != entry:
		visual_trace.append(entry)
	if boss.cycle_running and boss.health == 6:
		hud_capture("02_llena")
	if boss.health == 4:
		hud_capture("03_salud10")
	if boss.health == 3 and boss.combat_phase == 1:
		phase_one_at_six = phase_one_at_six or hud.phase_indicator.text != "SOBRECARGA"
		premature_phase_two = premature_phase_two or hud.phase_indicator.text == "SOBRECARGA"
		hud_capture("04_salud6")
	if boss.combat_phase == 2 and hud.phase_indicator.text == "SOBRECARGA":
		phase_two_confirmed = true
		hud_capture("06_sobrecarga")
	if not layout_checked and boss.state == boss.State.PHASE_TRANSITION:
		var occupied: Rect2 = hud.anchor.get_global_rect()
		var hint: Rect2 = room.get_node("GuardianHint").panel.get_global_rect()
		var player_hud: Rect2 = room.get_node("CombatHUD/HealthAnchor").get_global_rect()
		var lens: Rect2 = room.get_node("CombatHUD/TemporalLensHUD/LensIcon").get_global_rect()
		check(not occupied.intersects(hint) and not occupied.intersects(player_hud) and not occupied.intersects(lens),"BossHUD no solapa GuardianHint, integridad ni Lente")
		check(occupied.end.x <= root.get_visible_rect().size.x and occupied.end.y <= root.get_visible_rect().size.y,"BossHUD conserva margen dentro de pantalla")
		layout_measurements = {"viewport":str(root.get_visible_rect()),"boss_hud":str(occupied),"guardian_hint":str(hint),"player_hud":str(player_hud),"lens":str(lens),"art_uniform_scale":str(hud.health_art.scale)}
		layout_checked = true
	if boss.health == 2:
		hud_capture("08_salud2")
	if hud.destruction_started and not hud.destruction_completed:
		if not seen_destruction.has(hud.destruction_index):
			seen_destruction.append(hud.destruction_index)
		if hud.destruction_index == -1:
			hud_capture("09_salud0")
		elif hud.destruction_index == 0:
			hud_capture("10_destruccion_inicial")
		elif hud.destruction_index == 2:
			hud_capture("11_destruccion_media")
		elif hud.destruction_index == 4:
			hud_capture("12_destruccion_final")

func finish_continuous(result: String) -> void:
	recording = false
	metrics["result"] = result
	metrics["trial_seconds"] = float(elapsed_steps)/60.0
	metrics["player_final_hp"] = player.health
	metrics["boss_final_hp"] = boss.health
	metrics["missed_slashes"] = int(metrics["slashes"])-int(metrics["hits"])
	check(result == "boss_defeated" and boss.health == 0 and player.health == 3,"HUD combate continuo 6 a0 sin alterar salud Player")
	await ticks(60)
	check(hud.health_events == 6 and hud.health_value.text == "0/6","HUD refleja los seis daños aceptados, sin perder segundo tajo")
	var observed_values: Array[int] = []
	var all_values_correct: bool = true
	for sample: Dictionary in visual_trace:
		var value: int = int(sample["hp"])
		if not observed_values.has(value):
			observed_values.append(value)
		all_values_correct = all_values_correct and sample["text"] == "%d/6" % value
	check(observed_values.size() == 7 and all_values_correct,"Se observan todos los valores 6 a0 sincronizados durante combate real")
	check(phase_one_at_six and phase_two_confirmed and not premature_phase_two,"3HP no anuncia fase2 antes de confirmación")
	check(hud.destruction_plays == 1 and hud.destruction_completed and not hud.anchor.visible,"Destrucción única termina y oculta HUD")
	check(seen_destruction == [-1,0,1,2,3,4] and hud.destruction_index == 4,"Cero visible y cinco cuadros de destrucción en orden, termina en partículas")
	boss.defeated.emit() # Late duplicate notification after a genuine sword defeat.
	await ticks(2)
	check(hud.destruction_plays == 1 and not hud.anchor.visible and hud.health_value.text == "0/6","Notificación terminal repetida no reinicia animación ni salud llena")
	check(hud.destruction_frames[4].region.position == Vector2(1280,0) and not hud.destruction_frames[4].get_image().is_invisible(),"Último cuadro original contiene partículas, no un vacío inventado")
	check(hud.health_fraction() == 0.0 and not boss.cycle_running and current_scene == room,"Derrota no restaura barra ni cambia de escena")
	var directory: String = "res://artifacts/room5_stage_j"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var data: Dictionary = {"combat":metrics,"visual_trace":visual_trace,"destruction_indices":seen_destruction,"health_events":hud.health_events,"destruction_plays":hud.destruction_plays,"layout":layout_measurements}
	var suffix: String = "_%dx%d" % [root.size.x,root.size.y] if captures else ""
	var file: FileAccess = FileAccess.open(directory + "/continuous" + suffix + ".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"))
	file.close()
	print("HUD_CONTINUOUS ",JSON.stringify({"seconds":metrics["trial_seconds"],"arcs":metrics["arcs"],"beams":metrics["beams"],"hits":metrics["hits"],"player_hp":player.health}))

func damage_fixture() -> void:
	await fresh()
	check(not hud.anchor.visible and player.health == 3,"BossHUD oculto y CombatHUD independiente al entrar")
	check(hud.health_frames.size() == 4 and hud.destruction_frames.size() == 5,"Cuatro estados y cinco cuadros originales cargados")
	check(hud.health_frames[0].get_size() == Vector2(320,128) and hud.destruction_frames[4].get_size() == Vector2(320,128),"Celdas derivadas correctas")
	var image: Image = hud.health_frames[3].get_image()
	check(image.get_pixel(0,0).a == 0 and image.get_pixel(160,64).a > .9,"Transparencia externa real y sombras internas preservadas")
	check(hud.health_art.scale == Vector2(.75,.75) and hud.health_art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,"Escala uniforme y nearest")
	var anchor_before: Vector2 = hud.anchor.position
	Input.action_press("move_right")
	await ticks(12)
	Input.action_release("move_right")
	await ticks(8)
	check(hud.anchor.position == anchor_before,"BossHUD anclado a pantalla al mover Player")
	hud.bind_guardian(boss)
	hud.bind_guardian(boss)
	var connections: int = 0
	for row: Dictionary in boss.get_signal_connection_list("health_changed"):
		if (row["callable"] as Callable).get_object() == hud:
			connections += 1
	check(connections == 1,"Reenlace no duplica observador de salud")
	player.position = Vector2(1049,600) # Isolated sword fixture, not continuous route.
	await ticks(12)
	var count: int = hud.health_events
	await sword()
	check(boss.health == 6 and hud.health_events == count and hud.health_value.text == "6/6","Espada contra núcleo protegido no produce daño visual")
	boss.set_core_exposed(true)
	await ticks(55)
	await shift()
	await sword()
	check(manager.active_dimension == 1 and boss.health == 6 and hud.health_events == count,"Espada real en Pasado rechazada sin animación de daño del HUD")
	await shift()
	await sword()
	await sword()
	check(boss.health == 4 and hud.health_events == count+2 and hud.health_value.text == "4/6","Dos tajos reales aceptados actualizan dos veces")
	check(player.health == 3 and room.get_node("CombatHUD").health_value.text.contains("3/3"),"Salud Player no se comparte con jefe")
	# Visual-only fixtures read actual properties/signals; they do not prove combat.
	var ratios: Array[float] = []
	for hp: int in [6,5,4,3,2,1]:
		boss.health = hp
		boss.health_changed.emit(hp,boss.max_health)
		ratios.append(hud.health_fraction())
		check(hud.health_value.text == "%d/6" % hp and is_equal_approx(hud.health_fraction(),float(hp)/6.0),"Fixture visual salud " + str(hp))
	check(ratios[0] > ratios[1] and ratios[1] > ratios[2] and is_equal_approx(ratios[3],.5),"Cinco y cuatro HP son distinguibles; tres HP es mitad")
	check(is_equal_approx(hud.segment_fraction(0),.5) and hud.segment_fraction(1) == 0.0,"1HP conserva la mitad de cámara original")
	await fresh()
	check(boss.start_combat_cycle() and hud.anchor.visible and hud.health_value.text == "6/6","Inicio manual muestra HUD lleno")
	var hp_before: int = boss.health
	boss.stop_combat_cycle()
	await ticks(2)
	check(not hud.anchor.visible and hud.destruction_plays == 0 and boss.health == hp_before,"Stop oculta sin destruir ni alterar salud")
	boss.start_combat_cycle()
	check(hud.anchor.visible and hud.destruction_plays == 0,"Reinicio controlado reutiliza HUD sin derrota falsa")
	var hud_ref: WeakRef = weakref(hud)
	var boss_ref: WeakRef = weakref(boss)
	Input.action_press("move_left")
	for index: int in range(100):
		if current_scene != room:
			break
		await ticks(1)
	Input.action_release("move_left")
	await ticks(3)
	check(current_scene.scene_file_path == "res://scenes/Room4.tscn" and hud_ref.get_ref() == null and boss_ref.get_ref() == null,"Salida real Room5 libera HUD y referencia al Guardián")
	check(current_scene.find_children("BossHUD","",true,false).is_empty(),"No existe BossHUD fuera de Room5")
	room = current_scene
	await fresh()
	var prior_boss: Node2D = boss
	hud.bind_guardian(null)
	check(not prior_boss.is_connected("health_changed",Callable(hud,"_on_health_changed")),"Desvincular elimina señal de salud")
	hud.bind_guardian(prior_boss)
	prior_boss.queue_free()
	await ticks(2)
	check(hud.guardian == null and not hud.anchor.visible and hud.destruction_plays == 0,"Liberar jefe desconecta HUD sin simular destrucción")
	check(not FileAccess.file_exists("user://progress_v1.json"),"Sin persistencia de victoria")

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_j_work"):
		quit(2)
		return
	root.get_node("GameProgress").has_temporal_lens = true
	root.get_node("GameProgress").has_cronal_sword = true
	captures = OS.get_cmdline_user_args().has("--capture")
	physics_frame.connect(observe)
	hud_checks_running = true
	await continuous()
	hud_checks_running = false
	await damage_fixture()
	if is_instance_valid(room):
		room.queue_free()
	await ticks(3)
	print("HUD_RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
