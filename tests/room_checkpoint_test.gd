extends SceneTree
## Always launch with a dedicated APPDATA and CHRONOSHIFT_AUTOSAVE_TEST_PROFILE.

const ROOMS: Array[String] = [
	"res://scenes/Room1_Tutorial.tscn", "res://scenes/Room1_5.tscn",
	"res://scenes/Room2.tscn", "res://scenes/Room2_2.tscn",
	"res://scenes/Room3.tscn", "res://scenes/Room4.tscn", "res://scenes/Room5.tscn",
]
const SPAWNS: Array[Vector2] = [Vector2(45,304), Vector2(60,352), Vector2(100,560),
	Vector2(125,382), Vector2(130,695), Vector2(64,396), Vector2(140,600)]
var progress: Node
var failures: int = 0
var checks: Array[Dictionary] = []
var captures: bool = false

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks.append({"test":label,"pass":ok})
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1

func ticks(count: int = 4) -> void:
	for index: int in count:
		await physics_frame
		await process_frame

func isolated() -> bool:
	var actual: String = OS.get_user_data_dir().replace("\\","/").simplify_path().to_lower()
	var expected: String = OS.get_environment("CHRONOSHIFT_AUTOSAVE_TEST_PROFILE").replace("\\","/").simplify_path().to_lower()
	return not expected.is_empty() and actual == expected and actual.contains("/autosave_tests/")

func disk(path: String = "user://progress_v1.json") -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

func write_fixture(data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open("user://progress_v1.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func equip() -> void:
	progress.has_cronal_sword = true
	progress.has_temporal_lens = true
	progress.has_reactor_key = true
	for id: String in progress.completed_tutorials:
		progress.completed_tutorials[id] = true
	progress.completed_dialogues = {"awakening":true,"old_tool":true,"checkpoint_probe":true}
	progress.active_dialogue_id = ""

func load_room(path: String) -> void:
	progress.clear_room_arrival()
	check(change_scene_to_file(path) == OK,"Scene loads: " + path)
	await scene_changed
	await ticks()

func key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await ticks(2)
	event.pressed = false
	Input.parse_input_event(event)
	await ticks()

func click(button: BaseButton) -> void:
	var point: Vector2 = button.get_global_transform_with_canvas() * (button.size * 0.5)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await ticks(2)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	root.push_input(event, true)
	await ticks(2)
	event.pressed = false
	event.button_mask = 0
	root.push_input(event, true)
	await ticks(6)

func capture(label: String) -> void:
	if captures:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://" + label + ".png")

func travel(destination: String) -> void:
	var source: Node = current_scene
	var door: Area2D
	for candidate: Node in source.find_children("*", "Area2D", true, false):
		if candidate.get_script() == load("res://LevelTransition.gd") and candidate.next_scene_path == destination:
			door = candidate as Area2D
			break
	if door == null:
		check(false,"Existing transition found: " + destination)
		return
	var player: CharacterBody2D = source.get_node("Player") as CharacterBody2D
	# Fixture starts beside the existing trigger; real movement/body_entered performs the transition.
	var direction: float = 1.0 if door.global_position.x > 300.0 else -1.0
	player.global_position = door.global_position - Vector2(direction * 70.0,0)
	player.velocity = Vector2.ZERO
	await ticks(2)
	Input.action_press("move_right" if direction > 0.0 else "move_left")
	for index: int in 90:
		await ticks(1)
		if current_scene != source:
			break
	Input.action_release("move_right")
	Input.action_release("move_left")
	await ticks(6)
	check(current_scene != null and current_scene.scene_file_path == destination,"Physical transition arrives: " + destination)

func check_resume(index: int, mouse: bool = false) -> void:
	await load_room("res://scenes/MainMenu.tscn")
	var menu: Node = current_scene
	var button: TextureButton = menu.find_child("ContinueProgress",true,false) as TextureButton
	check(button != null and not button.disabled,"Continue enabled: " + ROOMS[index])
	check(menu.find_children("ContinueProgress","",true,false).size() == 1,"Only one Continue button")
	check(button.texture_normal.resource_path == "res://assets/inicio/Continuar.png" \
		and button.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST \
		and button.stretch_mode == TextureButton.STRETCH_KEEP_ASPECT_CENTERED,"Original PNG, nearest, keep aspect")
	if captures:
		await capture("menu_enabled_" + str(DisplayServer.window_get_size().x))
	if mouse:
		await click(button)
	else:
		button.grab_focus()
		await key(KEY_ENTER)
	if current_scene == menu:
		check(false,"Continue input changes scene")
		return
	check(current_scene.scene_file_path == ROOMS[index],"Continue destination: " + ROOMS[index])
	var player: CharacterBody2D = current_scene.get_node("Player") as CharacterBody2D
	check(absf(player.position.x-SPAWNS[index].x) < 0.5 and absf(player.position.y-SPAWNS[index].y) < 26.0 \
		and player.health == 3,"Safe initial spawn / health 3: " + ROOMS[index])
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(23.5,39.5)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = player.global_transform
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	check(player.get_world_2d().direct_space_state.intersect_shape(query).is_empty(),"Spawn outside solid geometry: " + ROOMS[index])
	await ticks(30)
	check(current_scene.scene_file_path == ROOMS[index] and player.health == 3 and player.is_on_floor(),"Spawn stable on safe floor: " + ROOMS[index])
	check(progress.has_cronal_sword and progress.has_temporal_lens and progress.has_reactor_key \
		and progress.completed_tutorials.attack and progress.completed_dialogues.checkpoint_probe,"Inventory, tutorials and dialogues preserved")
	if index >= 5:
		check(current_scene.get_node("DimensionManager").active_dimension == 0,"Resume begins in Presente")
	if index == 6:
		check(current_scene.encounter_state == current_scene.EncounterState.INACTIVE \
			and not current_scene.get_node("CoreGuardian").cycle_running,"Undefeated guardian passive before EncounterTrigger")

func finish() -> void:
	progress.clear_room_arrival()
	for audio: Node in root.find_children("*","AudioStreamPlayer",true,false):
		(audio as AudioStreamPlayer).stop()
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await ticks(3)
	# Accelerated headless ticks can finish before the audio thread releases its Ogg playback.
	OS.delay_msec(100)
	var file: FileAccess = FileAccess.open("user://checkpoint_results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"checks":checks},"\t"))
	file.close()
	print("RESULT checkpoints failures=",failures," checks=",checks.size())
	quit(0 if failures == 0 else 1)

func verify_f9() -> void:
	await load_room("res://tools/dev/Room5Practice.tscn")
	var controller: Node = root.get_node("PracticeController")
	check(controller._isolated_profile() and current_scene.scene_file_path == ROOMS[6],"Practice uses its existing isolated bootstrap and Room5")
	progress.last_room_checkpoint = ROOMS[4]
	progress.save_progress()
	await travel(ROOMS[5])
	check(progress.last_room_checkpoint == ROOMS[4],"Development transitions do not advance normal checkpoints")
	progress.record_core_guardian_victory()
	await key(KEY_F9)
	await ticks(20)
	check(current_scene.scene_file_path == ROOMS[6] and controller.restart_count == 2 \
		and progress.last_room_checkpoint == ROOMS[4],"F9 always returns to Room5 without changing checkpoint")
	check(not progress.core_guardian_defeated and progress.has_cronal_sword and progress.has_temporal_lens \
		and progress.has_reactor_key and current_scene.get_node("Player").health == 3 \
		and current_scene.get_node("DimensionManager").active_dimension == 0 \
		and not current_scene.get_node("CoreGuardian").cycle_running,"F9 rearms equipment, 3HP, Presente and passive undefeated guardian")
	await key(KEY_F9)
	check(controller.restart_count == 3 and progress.last_room_checkpoint == ROOMS[4],"F9 can be repeated without checkpoint changes")
	await finish()

func run() -> void:
	if not isolated():
		push_error("C.O.R.E.-9: Perfil de checkpoints sin aislamiento verificado. El disco real no participa.")
		quit(2)
		return
	progress = root.get_node("GameProgress")
	captures = OS.get_cmdline_user_args().has("--capture")
	if OS.get_cmdline_user_args().has("--f9"):
		await verify_f9()
		return
	if OS.get_cmdline_user_args().has("--ui-only"):
		await load_room("res://scenes/MainMenu.tscn")
		var button: TextureButton = current_scene.find_child("ContinueProgress",true,false)
		check(button.disabled,"Fresh rendered profile: Continue disabled")
		await capture("menu_disabled_" + str(DisplayServer.window_get_size().x))
		await click(button)
		check(disk().is_empty(),"Disabled rendered click creates no save")
		check(progress.new_game(),"Rendered New Game saves Tutorial checkpoint")
		equip()
		progress.last_room_checkpoint = ROOMS[6]
		progress.save_progress()
		await check_resume(6,true)
		await finish()
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--cold-read="):
			await check_resume(int(argument.get_slice("=",1)),true)
			await finish()
			return
		if argument.begins_with("--cold-write="):
			var index: int = int(argument.get_slice("=",1))
			check(progress.new_game(),"Cold fixture creates isolated new game")
			equip()
			progress.save_progress()
			if index == 0:
				await load_room(ROOMS[1])
			else:
				await load_room(ROOMS[index-1])
			await travel(ROOMS[index])
			check(progress.last_room_checkpoint == ROOMS[index],"Cold writer confirms legitimate arrival")
			await finish()
			return
	# This suite owns a fresh isolated profile. Never delete files unless the guard above passed.
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://progress_v1.json" + suffix):
			DirAccess.remove_absolute("user://progress_v1.json" + suffix)
	await load_room("res://scenes/MainMenu.tscn")
	var disabled: TextureButton = current_scene.find_child("ContinueProgress",true,false)
	check(disabled.disabled and not disabled.has_focus(),"No save: Continue disabled, focus skips it")
	await capture("menu_disabled_" + str(DisplayServer.window_get_size().x))
	await click(disabled)
	check(current_scene.scene_file_path == "res://scenes/MainMenu.tscn" and disk().is_empty(),"Disabled click creates no save and cannot continue")
	current_scene.get_node("%NewGameButton").grab_focus()
	await key(KEY_ENTER)
	check(current_scene.scene_file_path == ROOMS[0] and progress.last_room_checkpoint == ROOMS[0],"New Game through keyboard starts Tutorial / Sala 1 and resets checkpoint")
	check(not progress.has_cronal_sword and not progress.has_temporal_lens and not progress.has_reactor_key \
		and not progress.core_guardian_defeated and progress.completed_dialogues.is_empty(),"New Game resets progression and victory")
	await load_room("res://scenes/MainMenu.tscn")
	check(not current_scene.find_child("ContinueProgress",true,false).disabled,"Valid new save enables Continue before sword acquisition")
	current_scene.find_child("ContinueProgress",true,false).grab_focus()
	await key(KEY_ENTER)
	check(current_scene.scene_file_path == ROOMS[0] and not progress.has_cronal_sword,"Continue before acquiring sword loads saved Tutorial")
	equip()
	progress.save_progress()
	await load_room(ROOMS[0])
	# All six forward and six backward connections use actual area signals and Player movement.
	for index: int in range(1,ROOMS.size()):
		await travel(ROOMS[index])
		check(progress.last_room_checkpoint == ROOMS[index] and JSON.parse_string(disk()).last_room_checkpoint == ROOMS[index],"Forward arrival persisted: " + ROOMS[index])
	for index: int in range(ROOMS.size()-2,-1,-1):
		await travel(ROOMS[index])
		check(progress.last_room_checkpoint == ROOMS[index],"Backtracking records last visited: " + ROOMS[index])
	# Direct scene execution and synthetic diagnostic handoffs never advance the checkpoint.
	var previous: String = disk()
	await load_room(ROOMS[6])
	check(disk() == previous and progress.last_room_checkpoint == ROOMS[0],"Direct Room5 diagnostic does not autosave")
	for index: int in ROOMS.size():
		# Resume fixture changes only this test profile; transition persistence was verified above.
		progress.last_room_checkpoint = ROOMS[index]
		progress.save_progress()
		await check_resume(index,index % 2 == 1)
	# No writes for movement, Shift, death/reload or repeated confirmation of the same room.
	await load_room(ROOMS[5])
	progress.last_room_checkpoint = ROOMS[5]
	progress.save_progress()
	previous = disk()
	var backup_before: String = disk("user://progress_v1.json.bak")
	await key(KEY_SHIFT)
	Input.action_press("move_right")
	await ticks(4)
	Input.action_release("move_right")
	check(disk() == previous and disk("user://progress_v1.json.bak") == backup_before,"Walking and Shift do not write checkpoints")
	var player: CharacterBody2D = current_scene.get_node("Player")
	player.invulnerability_frames_remaining = 0
	player.take_damage(3)
	await ticks(100)
	check(current_scene.scene_file_path == ROOMS[5] and current_scene.get_node("Player").health == 3 \
		and disk() == previous and disk("user://progress_v1.json.bak") == backup_before,"Death restarts local room without checkpoint write")
	await load_room(ROOMS[4])
	await travel(ROOMS[5])
	check(disk("user://progress_v1.json.bak") == backup_before,"Repeated same checkpoint avoids redundant disk rotation")
	# Real disk failure: a directory occupies only the isolated .tmp path.
	await load_room(ROOMS[1])
	progress.last_room_checkpoint = ROOMS[1]
	progress.save_progress()
	previous = disk()
	DirAccess.make_dir_absolute("user://progress_v1.json.tmp")
	await travel(ROOMS[2])
	check(progress.last_room_checkpoint == ROOMS[1] and disk() == previous,"Failed checkpoint save rolls back memory and preserves disk")
	check(not progress.new_game() and progress.last_room_checkpoint == ROOMS[1] and progress.has_cronal_sword,"Failed New Game restores previous checkpoint/progression")
	DirAccess.remove_absolute("user://progress_v1.json.tmp")
	# Missing marker / missing target must not confirm a checkpoint.
	var bad: Node = current_scene.get_node("RoomTransitions/ToRoom2_2")
	bad.arrival_marker = &"DoesNotExist"
	await travel(ROOMS[3])
	check(progress.last_room_checkpoint == ROOMS[1] and disk() == previous,"Missing arrival marker never confirms destination")
	bad = current_scene.get_node("RoomTransitions/ToRoom2")
	bad.next_scene_path = "res://scenes/DoesNotExist.tscn"
	bad._on_body_entered(current_scene.get_node("Player"))
	await ticks()
	check(progress.last_room_checkpoint == ROOMS[1] and disk() == previous,"Nonexistent target preserves previous checkpoint")
	var failed_source: Node = current_scene
	bad.next_scene_path = "res://icon.svg"
	bad._on_body_entered(current_scene.get_node("Player"))
	await ticks()
	check(current_scene == failed_source and not bad.transition_pending and progress.arrival_scene.is_empty() \
		and progress.last_room_checkpoint == ROOMS[1] and disk() == previous,"Failed change_scene clears handoff and preserves previous checkpoint")
	# Retrocompatibility, invalid values, .bak recovery; reading never writes/migrates.
	var legacy: Dictionary = JSON.parse_string(previous)
	legacy.erase("last_room_checkpoint")
	legacy.core_guardian_defeated = true
	for value: Variant in [null, "res://scenes/FinalRoom.tscn", "res://scenes/Missing.tscn", 17, {"room":ROOMS[4]}]:
		var data: Dictionary = legacy.duplicate(true)
		if value != null:
			data.last_room_checkpoint = value
		write_fixture(data)
		var before: String = disk()
		check(progress.load_progress() and progress.get_continue_scene() == ROOMS[1] \
			and progress.has_cronal_sword and progress.has_temporal_lens and progress.has_reactor_key \
			and progress.core_guardian_defeated and progress.completed_dialogues.checkpoint_probe \
			and disk() == before,"Legacy/invalid checkpoint safely falls back without erasing progress: " + str(value))
	legacy.has_cronal_sword = false
	write_fixture(legacy)
	check(progress.load_progress() and progress.get_continue_scene() == ROOMS[0],"Legacy without sword resumes Tutorial safely")
	legacy.has_cronal_sword = true
	legacy.last_room_checkpoint = ROOMS[6]
	write_fixture(legacy)
	progress.load_progress()
	progress.save_progress()
	var file: FileAccess = FileAccess.open("user://progress_v1.json",FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(progress.load_progress() and progress.last_room_checkpoint == ROOMS[6] and progress.core_guardian_defeated,"Corrupt primary recovers full checkpoint/victory from .bak")
	progress.save_progress()
	await load_room("res://scenes/MainMenu.tscn")
	await click(current_scene.find_child("ContinueProgress",true,false))
	check(current_scene.scene_file_path == ROOMS[6] and current_scene.victory_persisted \
		and current_scene.encounter_state == current_scene.EncounterState.BOSS_DEFEATED \
		and not current_scene.get_node("CoreGuardian").visible,"Continue Room5 preserves defeated guardian")
	previous = disk()
	current_scene.get_node("Player").position = Vector2(1190,600)
	await ticks(5)
	check(current_scene.get_node("FinalAccessDoor/Prompt").visible,"Persistent victory unlocks ending access")
	await key(KEY_E)
	check(current_scene.scene_file_path == "res://scenes/FinalRoom.tscn" \
		and progress.last_room_checkpoint == ROOMS[6] and disk() == previous,"E enters ending without replacing Room5 checkpoint")
	await ticks(400)
	await click(current_scene.get_node("Stage/ReturnButton"))
	check(current_scene.scene_file_path == "res://scenes/MainMenu.tscn" and disk() == previous,"Ending menu return does not autosave")
	# The existing F9 controller has a stricter launch-path guard; its runner tests it separately.
	check(progress.new_game() and progress.last_room_checkpoint == ROOMS[0] and not progress.core_guardian_defeated \
		and not progress.has_cronal_sword and not progress.completed_tutorials.attack,"New Game after victory clears all progression and old checkpoint")
	await finish()
