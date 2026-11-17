extends SceneTree

var failures: int = 0
var starts: int = 0
var last_voice: AudioStreamPlayback
var player: CharacterBody2D
var sword: AudioStreamPlayer2D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func frames(count: int) -> void:
	for index: int in count:
		await physics_frame
		await process_frame

func on_frame() -> void:
	if not sword.has_stream_playback():
		return
	var voice: AudioStreamPlayback = sword.get_stream_playback()
	if voice != last_voice:
		last_voice = voice
		starts += 1
		var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
		check(sprite.animation == &"attack" and sprite.frame == 5, "voice starts at frame 6")

func run() -> void:
	var progress: Node = root.get_node("GameProgress")
	progress.set("has_cronal_sword", false)
	player = (load("res://scenes/Player.tscn") as PackedScene).instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	sword = player.get_node("SwordAudio")
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	sprite.frame_changed.connect(on_frame)
	player.call("use_energy_slash")
	check(not sword.playing and sprite.animation != &"attack", "no sword, no playback")
	progress.set("has_cronal_sword", true)
	player.set_physics_process(true)
	Input.action_press("attack")
	await frames(1)
	check(sprite.animation == &"attack" and sprite.frame < 5 and not sword.playing, "windup is silent")
	player.call("use_energy_slash")
	await frames(33)
	Input.action_release("attack")
	check(starts == 1, "one playback despite held input and rejected repeat")
	check(sword.playing, "original tail continues after the animation")
	player.call("use_energy_slash")
	await frames(34)
	check(starts == 2, "consecutive attack starts one new voice")
	player.call("use_energy_slash")
	player.call("take_damage", 3)
	await frames(18)
	check(starts == 2 and not sword.playing, "defeat stops tails and cancels pending slash")
	last_voice = null
	quit(1 if failures else 0)
