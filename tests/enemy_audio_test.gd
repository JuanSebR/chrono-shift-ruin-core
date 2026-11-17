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
	var room: Node2D = (load("res://scenes/Room2_2.tscn") as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player")
	var guard: CharacterBody2D = room.get_node("Guard22_A")
	await frames(60)
	check(guard.get_node_or_null("ActionAudio") == null and int(guard.get("state")) == 1, "patrol has no attack audio")
	player.global_position = Vector2(680, 480)
	await frames(3)
	check(int(guard.get("state")) == 2, "detection enters charge")
	player.global_position = Vector2(125, 382)
	await frames(5)
	check(int(guard.get("state")) == 3 and not is_instance_valid(guard.get("active_projectile")), "canceled charge has no shot")
	await frames(60)
	player.global_position = Vector2(680, 480)
	await frames(20)
	check(int(guard.get("state")) == 2, "charge preserves timing")
	await frames(21)
	check(guard.get_node_or_null("ActionAudio") == null and is_instance_valid(guard.get("active_projectile")), "projectile fires silently")
	guard.call("_fire")
	await frames(10)
	check(guard.get_node_or_null("ActionAudio") == null, "active projectile creates no audio node")
	await frames(55)
	check(int(player.get("health")) == 2 and int(room.get_node("CombatHUD").get("displayed_health")) == 2, "projectile damage reaches HUD")
	for guard_name: String in ["Guard22_A", "Guard22_B", "Guard22_C"]:
		var other: CharacterBody2D = room.get_node(guard_name)
		other.call("_fire")
		check(other.get_node_or_null("ActionAudio") == null and is_instance_valid(other.get("active_projectile")), guard_name + " fires silently")
	guard.call("take_damage", 2)
	check(int(guard.get("health")) == 0 and room.get_node_or_null("Guard22_A/ActionAudio") == null, "defeated guard remains silent")
	room.free()
	quit(1 if failures else 0)
