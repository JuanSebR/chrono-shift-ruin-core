extends "res://tests/guardian_three_attacks_test.gd"

var output_directory: String = "res://artifacts/ending_visual_fix/headless/"
var character_frames: Dictionary = {}
var feet_positions: Array[Vector2] = []

func capture(label: String) -> void:
	if not captures or shots.has(label):
		return
	shots[label] = true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_directory+label+".png")

func open_scene(path: String) -> void:
	check(change_scene_to_file(path) == OK,"Carga "+path)
	await scene_changed
	await ticks(20)

func key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(2)
	event.pressed = false
	Input.parse_input_event(event)
	await ticks(5)

func click(button: Control) -> void:
	# GUI input uses viewport coordinates, including the current canvas transform.
	var point: Vector2 = button.get_global_transform_with_canvas()*(button.size*0.5)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion,true)
	await ticks(1)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	root.push_input(event,true)
	await ticks(2)
	event.button_mask = 0
	event.pressed = false
	root.push_input(event,true)
	await ticks(5)

func run() -> void:
	if not OS.get_user_data_dir().contains("final_room_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	if captures:
		output_directory = "res://artifacts/ending_visual_fix/%dx%d/" % [root.size.x,root.size.y]
	DirAccess.make_dir_recursive_absolute(output_directory)
	var progress: Node = root.get_node("GameProgress")
	check(progress.core_guardian_defeated and progress.has_cronal_sword,"Victoria real del proceso anterior cargada")
	progress.core_guardian_defeated = false # Isolated pre-victory gate fixture.
	await open_scene("res://scenes/FinalRoom.tscn")
	check(current_scene.scene_file_path == "res://scenes/Room5.tscn","Acceso directo al final rechazado sin victoria")
	room = current_scene
	player = room.get_node("Player")
	var blocked: Node = room.get_node("FinalAccessDoor")
	check(blocked.get_node_or_null("Door") == null,"Acceso sin sprite ni animacion de puerta")
	player.position = Vector2(1190,600)
	await ticks(12)
	await key(KEY_E)
	check(not blocked.is_unlocked() and not blocked.transition_pending and current_scene == room,"E no abre puerta bloqueada")
	await capture("01_acceso_bloqueado")
	check(progress.load_progress() and progress.core_guardian_defeated,"Victoria persistente relecta desde disco")
	await open_scene("res://scenes/Room5.tscn")
	room = current_scene
	player = room.get_node("Player")
	manager = room.get_node("DimensionManager")
	var access: Node = room.get_node("FinalAccessDoor")
	check(access.is_unlocked() and not room.get_node("CoreGuardian").visible and room.get_node("RoomTransitions/ToRoom4").monitoring,"Reingreso desbloquea final y conserva salida Room4")
	await walk(300)
	await jump_to(373,550,true)
	await jump_to(373,480,true)
	await jump_to(550,550,true,390)
	await jump_to(640,480,true)
	await jump_to(890,550,true,730)
	await walk(1190)
	await ticks(20)
	check(player.is_on_floor() and room.fall_recovery_count == 0 and access.overlaps_body(player),"Puerta alcanzada con movimiento, saltos y Shift reales")
	check(access.get_node_or_null("Door") == null and access.get_node("Prompt").visible and access.get_node("Prompt").text == "E · SALIR","Solo E SALIR aparece cerca tras victoria")
	await capture("02_solo_E_SALIR")
	await key(KEY_E)
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/FinalRoom.tscn","Interaccion E transiciona a sala final")
	var ending: Control = current_scene as Control
	check(ending.get_node_or_null("Stage/Door") == null and ending.elapsed < 0.2,"Final sin puerta y acceso inmediato sin espera de animacion")
	for i: int in range(500):
		character_frames[ending.character.frame] = true
		if ending.elapsed >= 0.85:
			await capture("03_final_presente")
		if ending.elapsed >= 2.9:
			await capture("04_final_pasado")
		if ending.elapsed >= 5.4:
			await capture("05_gracias_alternativo")
		if ending.ready_to_return:
			break
		await ticks(1)
	check(character_frames.size() == 8 and ending.character.is_playing(),"Ocho poses originales del personaje sin recorte")
	check(ending.ready_to_return and ending.elapsed < 6.6,"Cierre habilita boton a6,5s sin tiempo de puerta")
	verify_feet(ending)
	await capture("06_gracias_y_boton")
	await key(KEY_SHIFT)
	check(ending.viewing_past and ending.get_node("Stage/Past").modulate.a == 1.0,"Shift permite revisar fondo Pasado al terminar")
	await capture("07_final_pasado_con_boton")
	if captures:
		await click(ending.return_button)
	else:
		ending.return_button.grab_focus()
		await key(KEY_ENTER)
	await ticks(20)
	check(current_scene.scene_file_path == "res://scenes/MainMenu.tscn","Boton real por clic o Enter vuelve al menu")
	if current_scene.scene_file_path != "res://scenes/MainMenu.tscn":
		quit(1)
		return
	var menu: Node = current_scene
	var continue_button: TextureButton = menu.find_child("ContinueProgress",true,false) as TextureButton
	check(continue_button != null and progress.core_guardian_defeated,"Continuar conserva victoria")
	var continue_destination: String = progress.get_continue_scene()
	continue_button.grab_focus()
	await key(KEY_ENTER)
	await ticks(25)
	check(current_scene.scene_file_path == continue_destination and progress.core_guardian_defeated,"Continuar respeta checkpoint o fallback v1 y conserva victoria")
	await open_scene("res://scenes/MainMenu.tscn")
	menu = current_scene
	(menu.get_node("%NewGameButton") as TextureButton).grab_focus()
	await key(KEY_ENTER)
	await ticks(25)
	check(current_scene.scene_file_path == "res://scenes/Room1_Tutorial.tscn" and not progress.core_guardian_defeated,"Nueva Partida borra victoria solo en perfil aislado")
	await open_scene("res://tools/dev/Room5Practice.tscn")
	check(current_scene.scene_file_path == "res://scenes/Room5.tscn","F9 bootstrap conserva su entrada")
	var controller: Node = root.get_node("PracticeController")
	check(progress.record_core_guardian_victory(),"Fixture final registra victoria aislada para comprobar F9")
	await open_scene("res://scenes/FinalRoom.tscn")
	await key(KEY_F9)
	await ticks(20)
	check(current_scene.scene_file_path == "res://scenes/Room5.tscn" and controller.restart_count == 2 and not progress.core_guardian_defeated and not current_scene.get_node("FinalAccessDoor").is_unlocked(),"F9 desde final rearma jefe y bloquea puerta sin efectos pendientes")
	var report: FileAccess = FileAccess.open(output_directory+"results.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"viewport":root.size,"feet_positions":feet_positions,"character_frames":character_frames.keys(),"no_doors":true,"direct_E":true,"menu_return":true,"continue":true,"new_game":true,"F9_from_final":true},"\t"))
	report.close()
	current_scene.queue_free()
	controller.queue_free()
	await ticks(3)
	print("FINAL_ROOM_RESULT failures=",failures)
	quit(0 if failures == 0 else 1)

func verify_feet(ending: Control) -> void:
	var hero: AnimatedSprite2D = ending.character
	var expected: Vector2 = ending.stage.get_global_transform()*Vector2(1000,463)
	for index: int in range(8):
		var image: Image = hero.sprite_frames.get_frame_texture(&"idle",index).get_image()
		if image.is_compressed():
			image.decompress()
		var sole: int = -1
		for y: int in range(image.get_height()-1,-1,-1):
			for x: int in range(image.get_width()):
				if image.get_pixel(x,y).a >= 0.5:
					sole = y+1
					break
			if sole >= 0:
				break
		var foot: Vector2 = hero.to_global(hero.offset+Vector2(137,sole))
		feet_positions.append(foot)
		check(sole == 422 and foot.distance_to(expected) < 0.1,"Suela opaca y anclaje al balcon estables en pose"+str(index))
