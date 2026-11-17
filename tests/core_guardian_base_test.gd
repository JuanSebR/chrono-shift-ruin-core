extends SceneTree

var failures: int = 0
var checks: int = 0
var deaths: int = 0
var room: Node2D
var player: CharacterBody2D
var boss: Node2D
var manager: Node
var captures: bool = false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	print(("PASS " if value else "FAIL ") + label)
	if not value:
		failures += 1

func ticks(count: int) -> void:
	for tick: int in range(count):
		await physics_frame

func capture(label: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	var directory: String = "res://artifacts/room5_stage_f"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	check(frame.save_png("%s/%s_%dx%d.png" % [directory, label, frame.get_width(), frame.get_height()]) == OK, "Captura " + label)

func shift() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.location = KEY_LOCATION_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.location = KEY_LOCATION_LEFT
	event.pressed = false
	Input.parse_input_event(event)

func attack(jumping: bool) -> void:
	if jumping:
		Input.action_press("jump")
		await ticks(20)
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	await ticks(13)
	if jumping and boss.health == 5 and boss.can_receive_damage():
		await capture("sword_real")
	await ticks(28)
	Input.action_release("jump")
	await ticks(15)

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_f_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	var progress: Node = root.get_node("GameProgress")
	progress.has_cronal_sword = true
	progress.has_temporal_lens = true
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	boss = room.get_node("CoreGuardian")
	manager = room.get_node("DimensionManager")
	await ticks(12)
	var sprite: AnimatedSprite2D = boss.get_node("VisualRoot/AnimatedSprite2D")
	check(boss.position == Vector2(1070,620) and boss.scale == Vector2.ONE and sprite.flip_h, "Pies, escala física y orientación")
	check(boss.health == boss.max_health and not boss.core_exposed and sprite.animation == &"repose" and sprite.sprite_frames.get_animation_loop(&"repose"), "Inicial pasivo y salud configurable")
	check(room.find_children("CoreGuardian", "", true, false).size() == 1 and boss.find_children("*", "StaticBody2D", true, false).is_empty(), "Una entidad y sin bloqueo corporal")
	for name: String in ["starting", "repose", "vulnerable", "retorn", "exit", "defeated"]:
		check(sprite.sprite_frames.get_frame_count(name) == {"starting":8,"repose":4,"vulnerable":6,"retorn":4,"exit":4,"defeated":7}[name], "Atlas y poses " + name)
	check(not boss.play_diagnostic(&"attack3"), "Ataques no disponibles")
	await capture("idle_scale")
	boss.play_diagnostic(&"starting")
	await ticks(40)
	await capture("intro")
	await ticks(30)
	check(sprite.animation == &"repose" and boss.position == Vector2(1070,620), "Intro explícita sin movimiento")
	boss.take_damage(1)
	check(boss.health == 6, "Presente protegido rechaza daño")
	boss.set_core_exposed(true)
	await ticks(18)
	await capture("vulnerable_core")
	await ticks(37)
	var core: Area2D = boss.get_node("CoreWeakpoint")
	check(core.position.distance_to(Vector2(11.092875,-54)) < 0.1, "Landmark vulnerable final registrado sin mover núcleo para alcance")
	player.position = Vector2(core.global_position.x - 32, 600)
	player.velocity = Vector2.ZERO
	await ticks(12)
	await capture("near_core")
	await attack(false)
	check(boss.health == 6, "Ataque desde suelo no alcanza núcleo alto")
	await attack(true)
	check(boss.health == 5, "Salto y espada reales: un solo daño en Presente expuesto")
	await attack(true)
	check(boss.health == 4, "Segundo tajo real reduce otro punto")
	shift()
	await ticks(18)
	var before: int = boss.health
	boss.take_damage(1)
	await attack(true)
	check(manager.active_dimension == 1 and boss.health == before, "Pasado expuesto rechaza método e impacto real")
	await capture("past")
	Input.action_press("jump")
	await ticks(20)
	Input.action_press("attack")
	await ticks(15)
	Input.action_release("attack")
	check(float(player.get_node("SwordHitbox").get("remaining")) > 0.0, "Cambio solicitado con ventana de espada activa")
	shift()
	await ticks(35)
	Input.action_release("jump")
	check(manager.active_dimension == 0 and boss.health == before - 1, "Impacto durante Shift se resuelve con dimensión confirmada")
	before = boss.health
	shift()
	await ticks(18)
	boss.set_core_exposed(false)
	boss.take_damage(1)
	check(boss.health == before, "Pasado protegido rechaza daño")
	shift()
	await ticks(18)
	boss.set_core_exposed(true)
	await ticks(55)
	player.position.x = core.global_position.x - 140
	await attack(true)
	check(boss.health == before, "Tajo fuera de alcance no reduce salud")
	player.position.x = core.global_position.x - 32
	progress.has_cronal_sword = false
	await attack(true)
	check(boss.health == before, "Sin espada no causa daño")
	progress.has_cronal_sword = true
	boss.set_core_exposed(false)
	await attack(true)
	check(boss.health == before, "Núcleo protegido rechaza espada real")
	boss.set_core_exposed(true)
	await ticks(55)
	player.set_physics_process(false)
	player.position = Vector2(780,490)
	shift()
	await ticks(4)
	check(manager.active_dimension == 0 and boss.can_receive_damage(), "Shift rechazado conserva daño permitido por Presente confirmado")
	player.position = Vector2(core.global_position.x - 32,600)
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	await ticks(12)
	check(sprite.sprite_frames.get_animation_names().size() == 6 and not boss.play_diagnostic(&"attack3"), "Sin secuencias ofensivas ni animaciones duplicadas")
	boss.play_diagnostic(&"retorn")
	await ticks(10)
	await capture("retorn")
	await ticks(30)
	check(sprite.animation == &"repose", "Retorn controlado vuelve a estado seguro")
	boss.play_diagnostic(&"exit")
	await ticks(40)
	check(sprite.animation == &"repose" and boss.position == Vector2(1070,620), "Exit no asigna trayectoria física")
	boss.defeated.connect(func() -> void: deaths += 1)
	boss.set_core_exposed(true)
	boss.take_damage(999)
	boss.take_damage(999)
	await ticks(35)
	await capture("defeated")
	await ticks(30)
	check(boss.health == 0 and deaths == 1 and not boss.core_exposed and sprite.animation == &"defeated" and not sprite.is_playing(), "Derrota única terminal, salud saturada en cero")
	check(player.health == 3 and room.find_children("CombatHUD", "", true, false).size() == 1 and root.get_camera_2d() == player.get_node("Camera2D"), "Salud del Player, HUD y cámara independientes")
	check(not FileAccess.file_exists("user://progress_v1.json"), "No se guarda victoria ni progreso")
	print("GUARDIAN_RESULT checks=", checks, " failures=", failures)
	room.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
