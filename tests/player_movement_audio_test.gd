extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for index: int in count:
		await physics_frame
		await process_frame

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func run() -> void:
	for path: String in ["Room1_Tutorial", "Room1_5", "Room2", "Room2_2"]:
		var instance: Node = (load("res://scenes/" + path + ".tscn") as PackedScene).instantiate()
		check(instance.get_node_or_null("Player/FootstepAudio") != null and instance.get_node_or_null("Player/LandingAudio") != null, path + " shared audio")
		instance.free()
	var room: Node = (load("res://scenes/Room2_2.tscn") as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player")
	var landing: AudioStreamPlayer2D = player.get_node("LandingAudio")
	var step: AudioStreamPlayer2D = player.get_node("FootstepAudio")
	await frames(10)
	check(not landing.playing, "spawn silent")
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check(int(player.get("step_index")) == 1, "one running contact while advancing")
	await frames(12)
	check(not step.playing, "stopped steps silent")
	Input.action_press("jump")
	await frames(8)
	Input.action_release("jump")
	check(not step.playing and not landing.playing, "airborne silent")
	var landings: int = 0
	var was_playing: bool = false
	for index: int in 70:
		await frames(1)
		if landing.playing and not was_playing:
			landings += 1
		was_playing = landing.playing
	check(landings == 1, "one landing for a real jump")
	var platform: AnimatableBody2D = room.get_node("MovingPlatforms/CyanTransportPlatform")
	player.global_position = platform.global_position + Vector2(0.0, -60.0)
	player.velocity = Vector2.ZERO
	await frames(17)
	check(player.is_on_floor() and landing.playing, "landing on cyan transport")
	var initial_x: float = player.global_position.x
	var initial_step: int = int(player.get("step_index"))
	await frames(30)
	check(absf(player.global_position.x - initial_x) > 5.0 and int(player.get("step_index")) == initial_step, "silent passive transport")
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check(int(player.get("step_index")) != initial_step and player.is_on_floor(), "walking on moving transport produces steps")
	step.play()
	landing.play()
	player.call("take_damage", 3)
	await frames(2)
	check(not step.playing and not landing.playing, "defeat stops movement audio")
	quit(1 if failures else 0)
