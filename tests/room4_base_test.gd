extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func _run() -> void:
	var packed: PackedScene = load("res://scenes/Room4.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	var room: Node2D = packed.instantiate() as Node2D
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	check(room.find_children("*", "CharacterBody2D", true, false).size() == 1, "Player único")
	check(room.find_children("*", "Camera2D", true, false).size() == 1 and root.get_camera_2d() == camera, "Cámara única activa")
	check(room.find_children("CombatHUD", "", true, false).size() == 1, "HUD único")
	check(Vector4i(camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom) == Vector4i(0, 0, 1280, 720), "Límites locales")
	var return_area: Area2D = room.get_node("RoomTransitions/ToRoom3")
	check(return_area.get_parent().get_child_count() == 1 and return_area.next_scene_path == "res://scenes/Room3.tscn" and not return_area.transition_pending, "Única salida válida hacia Room3")
	var geometry: Dictionary = {
		"EntryLedge": Vector3(38, 92, 416), "MetalLeft": Vector3(178, 298, 428),
		"PastLeft": Vector3(412, 506, 404), "CentralRest": Vector3(574, 718, 462),
		"MetalRight": Vector3(788, 872, 410), "PastRight": Vector3(954, 1076, 344),
		"ExitLedge": Vector3(1136, 1240, 284),
	}
	var shapes: Array[CollisionShape2D] = []
	for node: Node in room.find_children("*", "CollisionShape2D", true, false):
		if node.get_parent() is StaticBody2D:
			shapes.append(node as CollisionShape2D)
	check(shapes.size() == 7, "Siete apoyos y ningún suelo inferior")
	var identities: Dictionary = {}
	for shape: CollisionShape2D in shapes:
		var body: StaticBody2D = shape.get_parent()
		var spec: Vector3 = geometry[body.name]
		var rectangle: RectangleShape2D = shape.shape as RectangleShape2D
		identities[rectangle.get_instance_id()] = true
		check(shape.disabled == (body.get_parent().name == &"PastCollision"), str(body.name) + " estado inicial")
		check(rectangle.size == Vector2(spec.y - spec.x, 8) and shape.global_position == Vector2((spec.x + spec.y) / 2, spec.z + 4), str(body.name) + " cotas")
	check(identities.size() == 7, "Shape2D independientes")
	await create_timer(0.12).timeout
	check(player.is_on_floor() and player.position.distance_to(Vector2(64, 396)) < 1.0, "Aparición estable")
	Input.action_press("move_right")
	await create_timer(0.08).timeout
	Input.action_press("jump")
	await create_timer(0.60).timeout
	Input.action_release("jump")
	Input.action_release("move_right")
	await create_timer(0.15).timeout
	check(player.is_on_floor() and player.position.x > 178 and absf(player.position.y - 408) < 1, "Salto real hasta MetalLeft")
	for shape: CollisionShape2D in shapes:
		player.position = shape.global_position + Vector2(0, -38)
		player.velocity = Vector2.ZERO
		await create_timer(0.30).timeout
		check(player.is_on_floor() != shape.disabled, str(shape.get_parent().name) + " apoyo físico")
	quit(0 if failures == 0 else 1)
