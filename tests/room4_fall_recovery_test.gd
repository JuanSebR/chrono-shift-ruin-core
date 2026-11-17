extends SceneTree

var failures: int = 0
var recoveries: int = 0
var landing: Vector2
var reset_velocity: Vector2
var observed_cooldown: float = 0.0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1

func ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame

func shift() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"dimension_shift"
	event.pressed = true
	Input.parse_input_event(event)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path: String = "res://artifacts/room4_stage_f"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	var image: Image = root.get_texture().get_image()
	check(image.save_png("%s/%s_%dx%d.png" % [path, label, image.get_width(), image.get_height()]) == OK, "Captura " + label)

func _run() -> void:
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 720) if "1280" in OS.get_cmdline_user_args() else Vector2i(1024, 572)
	var progress: Node = root.get_node("GameProgress")
	progress.has_temporal_lens = true
	progress.has_cronal_sword = true
	var room: Node2D = load("res://scenes/Room4.tscn").instantiate()
	root.add_child(room)
	var player: CharacterBody2D = room.get_node("Player")
	var manager: Node = room.get_node("DimensionManager")
	var hud: CanvasLayer = room.get_node("CombatHUD")
	var status: Label = hud.get_node("TemporalLensHUD/Status")
	room.fall_recovered.connect(func() -> void:
		recoveries += 1
		landing = player.position
		reset_velocity = player.velocity
	)
	player.health_changed.emit(3)
	await ticks(8)
	check(room.checkpoint.name == &"Spawn" and player.is_on_floor(), "Entrada activa y estable")
	await capture("entry")
	Input.action_press(&"move_right")
	await ticks(5)
	Input.action_press(&"jump")
	await ticks(36)
	Input.action_release(&"jump")
	Input.action_release(&"move_right")
	await ticks(14)
	check(player.is_on_floor() and player.position.x >= 178 and player.position.x <= 298 and recoveries == 0, "Salto válido hasta MetalLeft sin recuperación")
	Input.action_press(&"move_right")
	for index: int in range(60):
		if player.position.y > 570:
			break
		await physics_frame
	Input.action_release(&"move_right")
	check(player.position.y > 570 and not player.is_on_floor(), "Caída real por movimiento y gravedad")
	await capture("fall")
	await ticks(35)
	check(recoveries == 1 and landing == Vector2(64, 396) and reset_velocity == Vector2.ZERO and player.is_on_floor() and status.text == "PRESENTE" and player.health == 3, "Presente recupera en entrada con 3/3")
	await capture("entry_recovered")

	player.position = Vector2(646, 350)
	await ticks(4)
	check(room.checkpoint.name == &"Spawn" and not player.is_on_floor(), "Cruzar el centro en el aire no activa el checkpoint")
	await ticks(35)
	check(room.checkpoint.name == &"CentralCheckpoint" and player.is_on_floor(), "Contacto real activa el centro")
	await capture("central")
	player.health = 2
	player.health_changed.emit(2)
	shift()
	await ticks(5)
	check(manager.active_dimension == 1 and recoveries == 1, "Shift válido no causa recuperación")
	Input.action_press(&"move_right")
	for index: int in range(100):
		if recoveries >= 2:
			break
		await physics_frame
	Input.action_release(&"move_right")
	await ticks(8)
	check(recoveries == 2 and landing == Vector2(646, 442) and player.is_on_floor() and player.health == 2, "Caída en Pasado recupera en centro con 2/3")
	await capture("central_from_past")

	player.health = 1
	player.health_changed.emit(1)
	player.position = Vector2(760, 620)
	player.velocity = Vector2(0, 300)
	shift()
	await ticks(4)
	observed_cooldown = manager.switch_cooldown_remaining
	check(manager.active_dimension == 1 and observed_cooldown > 0.0, "Caída durante recarga real")
	await ticks(30)
	check(recoveries == 3 and reset_velocity == Vector2.ZERO and manager.switch_cooldown_remaining == 0.0 and manager.can_request_switch(), "Recarga cancelada y Shift disponible")
	check(manager.active_dimension == 0 and manager.present_visuals.visible and not manager.past_visuals.visible and status.text == "PRESENTE", "Dimensión y HUD sincronizados")
	for shape: CollisionShape2D in manager.past_shapes:
		check(shape.disabled, "Pasado desactivado")
	for shape: CollisionShape2D in manager.present_shapes:
		check(not shape.disabled, "Presente activo")
	check(player.health == 1 and not player.get_node("AnimatedSprite2D").flip_h and player.get_node("AnimatedSprite2D").animation != &"defeat", "Salud 1/3, orientación y sin derrota")
	check(progress.has_temporal_lens and progress.has_cronal_sword and root.get_camera_2d() == player.get_node("Camera2D"), "Progreso y cámara conservados")
	check((hud.get_node("HealthAnchor/HealthValue") as Label).text == "INTEGRIDAD  1/3", "Salud visible intacta")
	await capture("cooldown_recovered")

	player.position = Vector2(450, 405)
	player.velocity = Vector2.ZERO
	shift()
	await ticks(4)
	check(status.text.contains("CAMBIO BLOQUEADO"), "Rechazo confirmado antes de caída")
	await ticks(60)
	check(recoveries == 4 and status.text == "PRESENTE" and player.is_on_floor() and player.health == 1, "Recuperación posterior al rechazo sin aviso residual")
	var before_move: float = player.position.x
	Input.action_press(&"move_right")
	await ticks(6)
	Input.action_release(&"move_right")
	check(player.position.x > before_move and recoveries == 4 and not room.get_node("RoomTransitions/ToRoom3").transition_pending, "Control restaurado y retorno no activado por recuperación")
	room.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
