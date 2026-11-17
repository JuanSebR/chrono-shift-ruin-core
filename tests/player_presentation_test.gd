extends SceneTree

var failures: int = 0
var results: Array[Dictionary] = []
var room: Node
var player: CharacterBody2D
var enemy: CharacterBody2D
var progress: Node

func _init() -> void:
	call_deferred("run")

func step(count: int) -> void:
	for i: int in count:
		await physics_frame
		await process_frame

func check(value: bool, name: String) -> void:
	results.append({"test": name, "pass": value})
	print(("PASS: " if value else "FAIL: ") + name)
	if not value:
		failures += 1

func fresh(path: String = "res://scenes/Room1_5.tscn") -> void:
	for action: String in ["attack", "jump", "move_left", "move_right"]:
		Input.action_release(action)
	if is_instance_valid(room):
		room.free()
	room = load(path).instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player") as CharacterBody2D
	enemy = room.get_node_or_null("Enemy1") as CharacterBody2D
	await step(8)

func run() -> void:
	if str(ProjectSettings.get_setting("application/config/name")) != "Core9_Combat_Isolated":
		push_error("Use isolated project only; never overwrite user progress")
		quit(2)
		return
	progress = root.get_node("GameProgress")
	progress.call("new_game")
	await fresh()
	player.call("use_energy_slash")
	check(player.get("presentation") == &"", "no sword: attack unavailable")
	player.position = Vector2(120, 352)
	await step(6)
	check(player.get("presentation") == &"pickup" and room.get_node_or_null("CronalSwordPickup") != null and not bool(progress.get("has_cronal_sword")), "pickup begins visibly before acquisition")
	player.call("use_energy_slash")
	check(player.get("presentation") == &"pickup", "attack cannot interrupt pickup")
	await step(28)
	check(bool(progress.get("has_cronal_sword")) and room.get_node_or_null("CronalSwordPickup") == null, "pickup completion grants and removes sword exactly once")
	check(player.is_on_floor() and absf(player.position.x - 120.0) < 1, "pickup stays grounded without involuntary movement")
	check(not bool(progress.call("acquire_sword")), "duplicate acquisition rejected")
	for left: bool in [false, true]:
		await fresh()
		enemy.set_physics_process(false)
		player.position = Vector2(740 if left else 660, 351)
		(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h = left
		await step(5)
		player.call("use_energy_slash")
		await step(2)
		check(int(enemy.get("health")) == 2, "attack windup has no damage: " + str(left))
		var saved_frame: int = int(player.get_node("AnimatedSprite2D").get("frame"))
		player.call("use_energy_slash")
		check(int(player.get_node("AnimatedSprite2D").get("frame")) == saved_frame, "invalid repeat does not restart animation: " + str(left))
		var sync: bool = true
		var active_ticks: int = 0
		var previous_health: int = 2
		for i: int in 26:
			await step(1)
			var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
			if float(player.get_node("SwordHitbox").get("remaining")) > 0:
				active_ticks += 1
				sync = sync and sprite.animation == &"attack" and sprite.frame == 3
			if int(enemy.get("health")) != previous_health:
				sync = sync and sprite.animation == &"attack" and sprite.frame == 3
			previous_health = int(enemy.get("health"))
		check(sync and active_ticks >= 4 and active_ticks <= 7, "damage window matches extended sword frame: " + str(left))
		check(int(enemy.get("health")) == 1, "one hit per animation: " + str(left))
		player.call("use_energy_slash")
		await step(15)
		check(int(enemy.get("health")) == 0, "second attack defeats enemy: " + str(left))
	await fresh()
	enemy.set_physics_process(false)
	player.position = Vector2(660, 351)
	await step(5)
	player.call("use_energy_slash")
	await step(2)
	player.call("take_damage", 1)
	check(player.get("presentation") == &"hurt" and int(player.get("health")) == 2, "real damage starts hurt and interrupts attack")
	check(str(room.get_node("CombatHUD/Health").get("text")).contains("2/3") and room.get_node("CombatHUD/HealthCells").get_child(2).get("modulate").a < 0.2, "HUD text and third energy cell update")
	player.call("take_damage", 1)
	check(int(player.get("health")) == 2, "invulnerability rejects immediate repeated damage")
	var blink_seen: bool = false
	for i: int in 20:
		await step(1)
		blink_seen = blink_seen or player.get_node("AnimatedSprite2D").get("modulate").a < 1.0
	check(blink_seen and player.get("presentation") == &"", "hurt finishes, blinking remains during invulnerability")
	check(int(enemy.get("health")) == 2, "cancelled windup never damages enemy")
	await step(45)
	check(int(player.get("invulnerability_frames_remaining")) == 0 and player.get_node("AnimatedSprite2D").get("modulate").a == 1, "invulnerability ends after one second at 60Hz")
	# Damage and jump can cancel pickup without granting or losing the object.
	progress.call("new_game")
	await fresh()
	player.position = Vector2(120, 352)
	await step(6)
	player.call("take_damage", 1)
	check(not bool(progress.get("has_cronal_sword")) and room.get_node_or_null("CronalSwordPickup") != null, "interrupted pickup keeps item and does not grant weapon")
	await step(45)
	check(bool(progress.get("has_cronal_sword")), "pickup retries safely after hurt")
	progress.call("new_game")
	await fresh()
	player.position = Vector2(120, 352)
	await step(6)
	Input.action_press("jump")
	await step(1)
	Input.action_release("jump")
	await step(3)
	check(player.velocity.y < 0 and not bool(progress.get("has_cronal_sword")) and player.get("presentation") != &"pickup", "jump cancels pickup without delaying impulse or granting weapon")
	await step(90)
	check(bool(progress.get("has_cronal_sword")), "landing inside pickup permits a clean retry")
	for path: String in ["res://scenes/Room1_Tutorial.tscn", "res://scenes/Room1_5.tscn"]:
		await fresh(path)
		var spawn: Vector2 = player.position
		player.position.x += 180
		player.call("take_damage", 3)
		check(player.get("presentation") == &"defeat", "final damage starts defeat: " + path)
		player.call("use_energy_slash")
		Input.action_press("move_right")
		Input.action_press("jump")
		await step(10)
		check(current_scene == room and player.get("presentation") == &"defeat" and is_zero_approx(player.velocity.x), "defeat blocks controls and delays restart: " + path)
		Input.action_release("move_right")
		Input.action_release("jump")
		await step(65)
		room = current_scene
		player = room.get_node("Player") as CharacterBody2D
		check(int(player.get("health")) == 3 and absf(player.position.x - spawn.x) < 0.1 and player.get("presentation") == &"", "restart restores room entry and clean player: " + path)
		check(bool(progress.get("has_cronal_sword")), "weapon persists after defeat: " + path)
	var original: SpriteFrames = load("res://assets/animations/core9_running_v2_frames.tres") as SpriteFrames
	var expanded: SpriteFrames = load("res://assets/animations/core9_presentation_frames.tres") as SpriteFrames
	var identical: bool = true
	for name: StringName in original.get_animation_names():
		identical = identical and expanded.get_frame_count(name) == original.get_frame_count(name) and expanded.get_animation_speed(name) == original.get_animation_speed(name) and expanded.get_animation_loop(name) == original.get_animation_loop(name)
		for i: int in original.get_frame_count(name):
			var a: AtlasTexture = original.get_frame_texture(name, i) as AtlasTexture
			var b: AtlasTexture = expanded.get_frame_texture(name, i) as AtlasTexture
			identical = identical and a.region == b.region and a.margin == b.margin and a.atlas.resource_path == b.atlas.resource_path and original.get_frame_duration(name, i) == expanded.get_frame_duration(name, i)
	check(identical, "five approved animations remain identical")
	check((player.get_node("CollisionShape2D").get("shape") as RectangleShape2D).size == Vector2(24,40), "main collider remains 24x40")
	var file: FileAccess = FileAccess.open("user://presentation-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "tests": results}, "\t"))
	file.close()
	print("RESULT failures=", failures)
	quit(0 if failures == 0 else 1)
