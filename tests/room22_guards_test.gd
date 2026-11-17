extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in count:
		await physics_frame
		await process_frame

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func run() -> void:
	var room: Node2D = load("res://scenes/Room2_2.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player")
	var guards: Array[CharacterBody2D] = [
		room.get_node("Guard22_A") as CharacterBody2D,
		room.get_node("Guard22_B") as CharacterBody2D,
		room.get_node("Guard22_C") as CharacterBody2D,
	]
	var expected_positions: Array[float] = [800.0, 1250.0, 1670.0]
	var expected_left: Array[float] = [720.0, 1170.0, 1590.0]
	var expected_right: Array[float] = [880.0, 1330.0, 1750.0]
	await frames(20)
	for i: int in guards.size():
		var guard: CharacterBody2D = guards[i]
		check(absf(guard.global_position.x - expected_positions[i]) < 1.0 and absf(guard.global_position.y - 480.0) < 1.0, "Guard22_%s safe spawn" % String.chr(65 + i))
		check(absf(float(guard.get("patrol_left")) - expected_left[i]) < 0.01 and absf(float(guard.get("patrol_right")) - expected_right[i]) < 0.01, "Guard22_%s independent patrol bounds" % String.chr(65 + i))

	var min_x: Array[float] = [INF, INF, INF]
	var max_x: Array[float] = [-INF, -INF, -INF]
	var direction_changes: Array[int] = [0, 0, 0]
	var prior_direction: Array[float] = []
	for guard: CharacterBody2D in guards:
		prior_direction.append(float(guard.get("direction")))
	for frame: int in 520:
		await frames(1)
		for i: int in guards.size():
			var guard: CharacterBody2D = guards[i]
			min_x[i] = minf(min_x[i], guard.global_position.x)
			max_x[i] = maxf(max_x[i], guard.global_position.x)
			var direction: float = float(guard.get("direction"))
			if direction != prior_direction[i]:
				direction_changes[i] += 1
				prior_direction[i] = direction
	for i: int in guards.size():
		check(min_x[i] >= expected_left[i] - 1.0 and max_x[i] <= expected_right[i] + 1.0, "Guard22_%s stays inside patrol" % String.chr(65 + i))
		check(max_x[i] - min_x[i] > 100.0 and direction_changes[i] >= 1, "Guard22_%s patrols and turns" % String.chr(65 + i))
		check(absf(guards[i].global_position.y - 480.0) < 1.0 and guards[i].is_on_floor(), "Guard22_%s remains on floor" % String.chr(65 + i))

	player.global_position = Vector2(365.0, 420.0)
	player.velocity = Vector2.ZERO
	await frames(90)
	check(not bool(guards[0].call("_can_see_player")) and not is_instance_valid(guards[0].get("active_projectile")), "Guard22_A cannot attack during platform transport")

	for i: int in guards.size():
		guards[i].set_physics_process(i == 0)
	guards[0].global_position = Vector2(800.0, 480.0)
	guards[0].set("direction", -1.0)
	guards[0].call("_set_state", 1)
	player.global_position = Vector2(680.0, 480.0)
	player.velocity = Vector2.ZERO
	await frames(2)
	var detected_player: bool = false
	var fired_projectile: bool = false
	for frame: int in 100:
		await frames(1)
		detected_player = detected_player or bool(guards[0].call("_can_see_player"))
		fired_projectile = fired_projectile or is_instance_valid(guards[0].get("active_projectile"))
	check(detected_player and fired_projectile, "Guard22_A detects and fires at Player")

	for guard: CharacterBody2D in guards:
		guard.set_physics_process(false)
	guards[0].call("take_damage", 1)
	check(int(guards[0].get("health")) == 1 and int(guards[1].get("health")) == 2 and int(guards[2].get("health")) == 2, "guard health is independent")
	guards[1].call("take_damage", 2)
	check(int(guards[0].get("health")) == 1 and int(guards[1].get("health")) == 0 and int(guards[2].get("health")) == 2, "one guard can be defeated without affecting others")
	check(room.get_node_or_null("CombatHUD") != null, "shared HUD remains present")
	check(not room.get_node("RoomTransitions/ToRoom3").monitoring, "future Room3 door remains inactive")
	print("RESULT failures=", failures)
	quit(1 if failures else 0)
