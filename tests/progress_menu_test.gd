extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var actual: String = OS.get_user_data_dir().replace("\\","/").to_lower()
	var expected: String = OS.get_environment("CHRONOSHIFT_AUTOSAVE_TEST_PROFILE").replace("\\","/").to_lower()
	if actual != expected or not actual.contains("/autosave_tests/"):
		quit(2)
		return
	var progress: Node = root.get_node("GameProgress")
	# Legacy v1 fixture deliberately has no room checkpoint.
	var file: FileAccess = FileAccess.open("user://progress_v1.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"has_cronal_sword":true}))
	file.close()
	assert(progress.load_progress())
	var menu: Node = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	var music: AudioStreamPlayer = root.get_node("BackgroundMusic")
	assert(music.playing and music.bus == &"Music" and music.stream.loop and music.volume_db == -18.0)
	assert(menu.get_node_or_null("MenuMusic") == null)
	assert(get_nodes_in_group("core9_global_music").size() == 1)
	var playback: AudioStreamPlayback = music.get_stream_playback()
	menu.call("_on_options_pressed")
	menu.call("_on_back_pressed")
	assert(music.playing and music.get_stream_playback() == playback)
	playback = null
	assert(AudioServer.get_bus_send(AudioServer.get_bus_index(&"SFX")) == &"Master")
	assert(AudioServer.get_bus_send(AudioServer.get_bus_index(&"Music")) == &"Master")
	print("PASS: one global looping track at -18dB, options preserve playback, separate Music/SFX buses")
	assert(menu.find_child("ContinueProgress", true, false) != null)
	menu.call("_on_continue_pressed")
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/Room1_5.tscn")
	assert(current_scene.get_node_or_null("CronalSwordPickup") == null)
	assert(is_instance_valid(music) and music.playing)
	print("PASS: menu continue loads ROOM1.5 and keeps sword")
	current_scene.free()
	menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	assert(root.get_node("BackgroundMusic") == music and music.playing)
	menu.call("_on_new_game_pressed")
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/Room1_Tutorial.tscn")
	assert(not bool(progress.get("has_cronal_sword")))
	assert(progress.last_room_checkpoint == "res://scenes/Room1_Tutorial.tscn")
	assert(is_instance_valid(music) and music.playing)
	print("PASS: menu new game resets sword and starts tutorial")
	music.stop()
	await process_frame
	OS.delay_msec(100)
	quit()
