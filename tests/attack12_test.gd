extends SceneTree
var failed: int = 0
func _init() -> void:
	call_deferred("run")
func step() -> void:
	await physics_frame
	await process_frame
func check(value: bool, label: String) -> void:
	print(("PASS: " if value else "FAIL: ") + label)
	if not value:
		failed += 1
func click() -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
func release() -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	Input.parse_input_event(event)
func run() -> void:
	var old: SpriteFrames = load("res://assets/animations/core9_presentation_frames.tres") as SpriteFrames
	var updated: SpriteFrames = load("res://assets/animations/core9_presentation_attack12.tres") as SpriteFrames
	var names: Array[StringName] = [&"idle",&"running",&"jump",&"fall",&"land",&"pickup",&"hurt",&"defeat"]
	var same: bool = true
	for n: StringName in names:
		same = same and old.get_frame_count(n) == updated.get_frame_count(n) and old.get_animation_speed(n) == updated.get_animation_speed(n) and old.get_animation_loop(n) == updated.get_animation_loop(n)
		for i: int in old.get_frame_count(n):
			var a: AtlasTexture = old.get_frame_texture(n,i) as AtlasTexture
			var b: AtlasTexture = updated.get_frame_texture(n,i) as AtlasTexture
			same = same and a.region == b.region and a.margin == b.margin and a.atlas.resource_path == b.atlas.resource_path and old.get_frame_duration(n,i) == updated.get_frame_duration(n,i)
	check(same,"all eight other animations unchanged")
	check(updated.get_frame_count(&"attack") == 12 and updated.get_animation_speed(&"attack") == 24 and not updated.get_animation_loop(&"attack"),"12 frames at 24fps once")
	for i: int in 12:
		var atlas: AtlasTexture = updated.get_frame_texture(&"attack",i) as AtlasTexture
		check(atlas.atlas.resource_path.ends_with("frame_%02d.res" % (i+1)),"ordered source %02d" % (i+1))
		var source: Texture2D = load("res://assets/sprites/sprites movimiento/Accion de golpear/attack_%02d.png" % (i+1)) as Texture2D
		var expected: Image = source.get_image()
		expected.resize(338,338,Image.INTERPOLATE_NEAREST)
		check(expected.get_data() == atlas.atlas.get_image().get_data(), "complete independent image %02d" % (i+1))
	root.get_node("GameProgress").set("has_cronal_sword",true)
	for left: bool in [false,true]:
		var room: Node = load("res://scenes/Room1_5.tscn").instantiate()
		root.add_child(room)
		current_scene = room
		var player: CharacterBody2D = room.get_node("Player")
		var enemy: CharacterBody2D = room.get_node("Enemy1")
		enemy.set_physics_process(false)
		player.position = Vector2(740 if left else 660,351)
		var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
		sprite.flip_h = left
		for i: int in 8:
			await step()
		click()
		await step()
		release()
		var seen: Array[int] = []
		var valid: bool = true
		var active_ticks: int = 0
		for tick: int in 35:
			await step()
			if sprite.animation == &"attack":
				if seen.is_empty() or seen[-1] != sprite.frame:
					seen.append(sprite.frame)
				if float(player.get_node("SwordHitbox").get("remaining")) > 0:
					active_ticks += 1
					valid = valid and sprite.frame >= 5 and sprite.frame <= 7
				if tick == 23:
					var before: int = sprite.frame
					click()
					await step()
					release()
					valid = valid and sprite.frame >= before and player.get("presentation") == &"attack"
		check(seen == [0,1,2,3,4,5,6,7,8,9,10,11],"mouse attack plays 01–12 without restart, left="+str(left))
		check(valid and active_ticks >= 4 and active_ticks <= 7,"damage window aligned with frames 06–08, left="+str(left))
		check(int(enemy.get("health")) == 1,"exactly one damage against enemy, left="+str(left))
		check(sprite.animation == &"idle","returns to idle, left="+str(left))
		click()
		await step()
		release()
		for i: int in 36:
			await step()
		check(int(enemy.get("health")) == 0,"second complete attack defeats enemy, left="+str(left))
		Input.action_press("move_left" if left else "move_right")
		await step()
		click()
		await step()
		release()
		for i: int in 38:
			await step()
		check(sprite.animation == &"running", "returns to running after attack, left=" + str(left))
		Input.action_release("move_left" if left else "move_right")
		room.free()
	print("RESULT failures=",failed)
	quit(0 if failed == 0 else 1)
