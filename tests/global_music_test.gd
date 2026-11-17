extends "res://tests/room_checkpoint_test.gd"
## Reuse existing real-Player transition/input helpers; never run the checkpoint suite here.

var music: AudioStreamPlayer
var voice: AudioStreamPlayback
var music_id: int = 0
var last_position: float = 0.0
var last_loops: int = 0
var master_capture: AudioEffectCapture
var music_capture: AudioEffectCapture
var levels: Dictionary = {}

func rms(samples: PackedVector2Array) -> float:
	var sum: float = 0.0
	for sample: Vector2 in samples:
		sum += sample.length_squared()
	return sqrt(sum / maxf(1.0,float(samples.size()*2)))

func sample_bus(capture_effect: AudioEffectCapture, seconds: float = 0.35) -> PackedVector2Array:
	capture_effect.clear_buffer()
	await create_timer(seconds,true).timeout
	return capture_effect.get_buffer(capture_effect.get_frames_available())

func snapshot() -> void:
	last_position = music.get_playback_position()
	last_loops = voice.get_loop_count()

func continuity(label: String) -> void:
	check(is_instance_valid(music) and music.get_instance_id() == music_id and music.playing \
		and music.get_stream_playback() == voice,"Same active player and playback: " + label)
	check(get_nodes_in_group("core9_global_music").size() == 1,"Single global music instance: " + label)
	check(music.get_playback_position() + 0.05 >= last_position or voice.get_loop_count() > last_loops,
		"Playback never restarts: " + label)
	snapshot()

func save_seam(samples: PackedVector2Array) -> void:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size()*4)
	for index: int in samples.size():
		bytes.encode_s16(index*4,clampi(int(roundf(samples[index].x*32767.0)),-32768,32767))
		bytes.encode_s16(index*4+2,clampi(int(roundf(samples[index].y*32767.0)),-32768,32767))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(AudioServer.get_mix_rate())
	wav.stereo = true
	wav.data = bytes
	check(wav.save_to_wav("user://loop_seam.wav") == OK,"Actual engine loop audio captured to WAV")

func run() -> void:
	var actual: String = OS.get_user_data_dir().replace("\\","/").to_lower()
	var expected: String = OS.get_environment("CHRONOSHIFT_AUDIO_TEST_PROFILE").replace("\\","/").to_lower()
	if actual != expected or not actual.contains("/audio_tests/"):
		quit(2)
		return
	progress = root.get_node("GameProgress")
	equip()
	music = root.get_node("BackgroundMusic") as AudioStreamPlayer
	music_id = music.get_instance_id()
	voice = music.get_stream_playback()
	check(music.playing and voice != null,"Global music starts automatically")
	check(music.stream is AudioStreamOggVorbis and absf(music.stream.get_length()-180.0) < 0.01,
		"Original-derived OGG is stereo three-minute loop")
	check(music.stream.loop and music.stream.loop_offset == 0.0 and music.max_polyphony == 1,
		"Whole stream loops at zero with one voice")
	check(music.bus == &"Music" and music.volume_db == -18.0 \
		and music.process_mode == Node.PROCESS_MODE_ALWAYS,"Music bus, -18dB and pause-independent lifetime")
	var music_bus: int = AudioServer.get_bus_index(&"Music")
	var sfx_bus: int = AudioServer.get_bus_index(&"SFX")
	check(music_bus >= 0 and sfx_bus >= 0 and music_bus != sfx_bus \
		and AudioServer.get_bus_volume_db(music_bus) == 0.0 \
		and AudioServer.get_bus_send(music_bus) == &"Master" \
		and AudioServer.get_bus_send(sfx_bus) == &"Master","Separate existing Music and SFX buses; initial effective gain -18dB")
	master_capture = AudioEffectCapture.new()
	master_capture.buffer_length = 4.0
	music_capture = AudioEffectCapture.new()
	music_capture.buffer_length = 4.0
	AudioServer.add_bus_effect(0,master_capture)
	AudioServer.add_bus_effect(music_bus,music_capture)
	await load_room("res://scenes/MainMenu.tscn")
	check(current_scene.get_node_or_null("MenuMusic") == null,"Menu has no second music player")
	var samples: PackedVector2Array = await sample_bus(master_capture)
	levels["master_rms"] = rms(samples)
	check(samples.size() > 0 and rms(samples) > 0.0001 and rms(samples) < 0.13,"Engine decodes and mixes non-silent music at low level")
	AudioServer.set_bus_mute(sfx_bus,true)
	samples = await sample_bus(music_capture)
	levels["sfx_muted_music_rms"] = rms(samples)
	check(rms(samples) > 0.0001,"Muting SFX leaves music audible")
	AudioServer.set_bus_mute(music_bus,true)
	samples = await sample_bus(master_capture)
	levels["music_muted_master_rms"] = rms(samples)
	check(rms(samples) < 0.00001,"Muting Music silences the soundtrack independently")
	AudioServer.set_bus_mute(music_bus,false)
	AudioServer.set_bus_mute(sfx_bus,false)
	snapshot()
	current_scene._on_options_pressed()
	current_scene._on_back_pressed()
	await ticks(4)
	continuity("menu options")
	var duplicate: AudioStreamPlayer = load("res://scripts/audio/background_music.gd").new() as AudioStreamPlayer
	root.add_child(duplicate)
	await ticks(3)
	check(not is_instance_valid(duplicate),"Accidental duplicate rejects itself before playback")
	continuity("duplicate rejected")
	paused = true
	await create_timer(0.4,true).timeout
	paused = false
	check(music.get_playback_position() > last_position+0.2,"Music continues during game pause")
	continuity("pause")
	await load_room(ROOMS[0])
	continuity("Tutorial / Sala 1")
	for index: int in range(1,ROOMS.size()):
		await travel(ROOMS[index])
		continuity("forward " + ROOMS[index])
		for child: String in ["FootstepAudio","LandingAudio","SwordAudio"]:
			check(current_scene.get_node("Player/"+child).bus == &"SFX","SFX separation " + ROOMS[index]+"/"+child)
	for index: int in range(ROOMS.size()-2,-1,-1):
		await travel(ROOMS[index])
		continuity("backward " + ROOMS[index])
	check(reload_current_scene() == OK,"Local reload accepted")
	await scene_changed
	await ticks(5)
	continuity("local room reload")
	# Exercise the actual mixer across the end, rather than waiting three minutes.
	music.seek(music.stream.get_length()-1.2)
	# Godot recreates the playback on an explicit seek. This is test instrumentation, not a scene change.
	voice = null
	await ticks(3)
	voice = music.get_stream_playback()
	var loops_before: int = voice.get_loop_count()
	samples = await sample_bus(master_capture,2.8)
	check(music.playing and voice.get_loop_count() > loops_before and music.get_playback_position() < 5.0,
		"Actual OGG wraps and keeps playing across the three-minute boundary")
	check(rms(samples) > 0.0001,"Loop boundary remains non-silent")
	save_seam(samples)
	snapshot()
	progress.core_guardian_defeated = true
	await load_room("res://scenes/FinalRoom.tscn")
	continuity("FinalRoom")
	await ticks(400)
	await click(current_scene.get_node("Stage/ReturnButton"))
	check(current_scene.scene_file_path == "res://scenes/MainMenu.tscn","Ending button returns to menu")
	continuity("ending to menu")
	await load_room("res://tools/dev/Room5Practice.tscn")
	continuity("practice bootstrap")
	await key(KEY_F9)
	check(current_scene.scene_file_path == ROOMS[6] and root.get_node("PracticeController").restart_count == 2,
		"F9 keeps isolated practice behavior")
	continuity("F9")
	var report: Dictionary = {"failures":failures,"checks":checks,"levels":levels,
		"length":music.stream.get_length(),"volume_db":music.volume_db,"music_instance_id":music_id,
		"loop_count":voice.get_loop_count(),"audio_driver":AudioServer.get_driver_name(),"profile":actual}
	var file: FileAccess = FileAccess.open("user://global_music_results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	AudioServer.remove_bus_effect(music_bus,AudioServer.get_bus_effect_count(music_bus)-1)
	voice = null
	music.stop()
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	if root.get_node_or_null("PracticeController") != null:
		root.get_node("PracticeController").queue_free()
	await ticks(3)
	OS.delay_msec(100)
	print("GLOBAL_MUSIC_RESULT failures=",failures," checks=",checks.size())
	quit(0 if failures == 0 else 1)
