extends SceneTree

var failures: int = 0
var checks: Array[Dictionary] = []
var room: Node2D
var player: CharacterBody2D
var enemy: CharacterBody2D
var progress: Node

func _init() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks.append({"test": label, "pass": condition})
	print(("PASS: " if condition else "FAIL: ") + label)
	if not condition:
		failures += 1

func frames(count: int) -> void:
	for i: int in count:
		await physics_frame
		await process_frame

func fresh() -> void:
	if is_instance_valid(room):
		room.free()
	room = load("res://scenes/Room1_5.tscn").instantiate() as Node2D
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player") as CharacterBody2D
	enemy = room.get_node("Enemy1") as CharacterBody2D
	await frames(5)

func run() -> void:
	progress = root.get_node("GameProgress")
	# Never run against the user's real save: test requires the isolated app name.
	if str(ProjectSettings.get_setting("application/config/name")) != "Core9_Combat_Isolated":
		push_error("Combat test requires isolated project/user directory")
		quit(2)
		return
	check(bool(progress.call("new_game")), "new game safely resets progress")
	await fresh()
	enemy.set_physics_process(false)
	player.position = Vector2(660, 351)
	await frames(5)
	player.call("use_energy_slash")
	await frames(8)
	check(int(enemy.get("health")) == 2 and float(player.get("attack_cooldown_remaining")) == 0.0, "without sword: no attack or damage")
	player.position = Vector2(120, 352)
	await frames(30)
	check(bool(progress.get("has_cronal_sword")), "physical player contact acquires sword")
	check(not is_instance_valid(room.get_node_or_null("CronalSwordPickup")), "pickup removed once")
	check(not bool(progress.call("acquire_sword")), "duplicate acquisition rejected")
	progress.set("has_cronal_sword", false)
	check(bool(progress.call("load_progress")) and bool(progress.get("has_cronal_sword")), "disk reload restores acquired sword")
	await fresh()
	check(room.get_node_or_null("CronalSwordPickup") == null, "scene change does not respawn sword")
	enemy.set_physics_process(false)
	player.position = Vector2(660, 351)
	await frames(10)
	check(int(enemy.get("health")) == 2, "inactive hitbox cannot damage nearby enemy")
	player.call("use_energy_slash")
	await frames(8)
	check(int(enemy.get("health")) == 1, "one active slash deals exactly one damage")
	await frames(8)
	player.call("use_energy_slash")
	await frames(2)
	check(int(enemy.get("health")) == 1, "cooldown prevents immediate second slash")
	await frames(10)
	player.call("use_energy_slash")
	await frames(8)
	check(int(enemy.get("health")) == 0 and int(enemy.get("state")) == 5, "second valid slash defeats enemy")
	await frames(60)
	check(not is_instance_valid(enemy), "destruction animation finishes and removes enemy")
	await fresh()
	player.position = Vector2(740, 351)
	player.get_node("AnimatedSprite2D").set("flip_h", true)
	enemy.set_physics_process(false)
	await frames(5)
	player.call("use_energy_slash")
	await frames(8)
	check(int(enemy.get("health")) == 1, "left-facing sword hits left-side enemy")
	await fresh()
	player.position = Vector2(60, 352)
	var patrol_safe: bool = true
	var minimum_x: float = 1000.0
	var maximum_x: float = 0.0
	for i: int in 840:
		await frames(1)
		minimum_x = minf(minimum_x, enemy.position.x)
		maximum_x = maxf(maximum_x, enemy.position.x)
		patrol_safe = patrol_safe and enemy.position.x >= 559.0 and enemy.position.x <= 821.0 and enemy.position.y < 355.0
	check(patrol_safe and minimum_x < 565.0 and maximum_x > 815.0, "patrol traverses bounds and stays on terrain")
	player.position = Vector2(enemy.position.x - 120, 351)
	await frames(5)
	var shot_seen: bool = false
	var max_projectiles: int = 0
	for i: int in 160:
		await frames(1)
		var count: int = 0
		for child: Node in room.get_children():
			if child is Area2D and child.get_script() == load("res://scripts/combat/enemy_projectile.gd"):
				count += 1
		max_projectiles = maxi(max_projectiles, count)
		shot_seen = shot_seen or count > 0
	check(shot_seen and max_projectiles == 1, "detects player, charges, fires at most one projectile")
	check(int(player.get("health")) == 2, "projectile applies one damage")
	player.set("invulnerability_frames_remaining", 60)
	player.call("take_damage", 1)
	check(int(player.get("health")) == 2, "existing invulnerability rejects repeated damage")
	enemy.set_physics_process(false)
	enemy.call("_set_state", 2, 0.6)
	enemy.call("take_damage", 1)
	check(int(enemy.get("state")) == 4, "damage interrupts charge")
	# End-to-end traversal uses real movement and attack inputs.
	progress.call("new_game")
	await fresh()
	Input.action_press("move_right")
	var crossed: bool = false
	for i: int in 180:
		await frames(1)
		var narrative: CanvasLayer = room.get_node("DialoguePanel") as CanvasLayer
		if str(narrative.get("active_id")) == "old_tool":
			narrative.call("advance")
			narrative.call("advance")
		if player.position.x > 410:
			crossed = true
		if player.position.x >= enemy.position.x - 38:
			break
	Input.action_release("move_right")
	check(crossed and bool(progress.get("has_cronal_sword")) and player.position.y < 400, "walk sequence: pickup then permanent bridge to enemy")
	# Allow the incoming projectile reaction to finish before issuing valid attacks.
	await frames(20)
	Input.action_press("attack")
	await frames(1)
	Input.action_release("attack")
	await frames(24)
	Input.action_press("attack")
	await frames(1)
	Input.action_release("attack")
	await frames(8)
	check(is_instance_valid(enemy) and int(enemy.get("health")) == 0 and int(player.get("health")) > 0, "end-to-end player defeats enemy with two input attacks")
	check((player.get_node("CollisionShape2D").get("shape") as RectangleShape2D).size == Vector2(24, 40), "player collider preserved 24x40")
	check(player.get_node("AnimatedSprite2D").get("position") == Vector2(0, -26.2) and player.get_node("AnimatedSprite2D").get("scale") == Vector2(0.33, 0.33), "player visual transform unchanged")
	await fresh()
	player.position = Vector2(600, 351)
	enemy.set_physics_process(false)
	await frames(6)
	var wall: StaticBody2D = StaticBody2D.new()
	wall.position = Vector2(650, 345)
	var wall_shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(10, 100)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	room.add_child(wall)
	await frames(3)
	check(not bool(enemy.call("_can_see_player")), "terrain wall blocks line of sight")
	wall.queue_free()
	await frames(3)
	check(bool(enemy.call("_can_see_player")), "clear line of sight detects player")
	enemy.call("_fire")
	await frames(15)
	Input.action_press("jump")
	await frames(15)
	var jumped_above_shot: bool = player.position.y < 315
	Input.action_release("jump")
	await frames(20)
	check(int(player.get("health")) == 3 and jumped_above_shot, "jump evades horizontal projectile without changed physics")
	await frames(200)
	check(not is_instance_valid(enemy.get("active_projectile")), "projectile expires after maximum lifetime")
	player.set("invulnerability_frames_remaining", 0)
	player.call("take_damage", 3)
	await frames(80)
	room = current_scene as Node2D
	player = room.get_node("Player") as CharacterBody2D
	check(int(player.get("health")) == 3 and bool(progress.get("has_cronal_sword")) and room.get_node_or_null("CronalSwordPickup") == null, "defeat reload restores health and retains sword")
	# Corrupt only the isolated save, then verify last known good fallback.
	progress.call("save_progress")
	var broken: FileAccess = FileAccess.open("user://progress_v1.json", FileAccess.WRITE)
	broken.store_string("broken")
	broken.close()
	progress.set("has_cronal_sword", false)
	check(bool(progress.call("load_progress")) and bool(progress.get("has_cronal_sword")), "corrupt save recovers validated backup")
	progress.call("save_progress")
	var output: FileAccess = FileAccess.open("user://combat-results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"failures": failures, "checks": checks}, "\t"))
	output.close()
	print("RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
