extends SceneTree

var checks: int = 0
var failures: int = 0
var room: Node2D
var player: CharacterBody2D
var boss: Node2D
var manager: Node
var beam: Node2D
var captures: bool = false
var seen_states: Array[int] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func ticks(count: int) -> void:
	for tick: int in range(count):
		await physics_frame

func wait_state(expected: int) -> void:
	for tick: int in range(400):
		if boss.state == expected:
			return
		await ticks(1)
	check(false, "Tiempo agotado esperando estado " + str(expected))

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

func capture(label: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var directory: String = "res://artifacts/room5_stage_g"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	check(image.save_png("%s/%s_%dx%d.png" % [directory,label,image.get_width(),image.get_height()]) == OK, "Render real " + label)

func reset_player(position: Vector2) -> void:
	player.set_physics_process(true)
	player.position = position
	player.velocity = Vector2.ZERO
	player.health = 3
	player.invulnerability_frames_remaining = 0
	player.health_changed.emit(3)
	await ticks(12)

func run() -> void:
	if not OS.get_user_data_dir().contains("phase_g_work"):
		quit(2)
		return
	captures = OS.get_cmdline_user_args().has("--capture")
	var progress: Node = root.get_node("GameProgress")
	progress.has_temporal_lens = true
	progress.has_cronal_sword = true
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	boss = room.get_node("CoreGuardian")
	manager = room.get_node("DimensionManager")
	beam = boss.get_node("BeamAttack")
	await ticks(20)
	var camera: Camera2D = player.get_node("Camera2D")
	var camera_before: Transform2D = camera.global_transform
	var zoom_before: Vector2 = camera.zoom
	var hud_before: Transform2D = (room.get_node("CombatHUD/HealthAnchor") as Control).get_global_transform_with_canvas()
	check(boss.state == boss.State.IDLE and not boss.beam_running and not beam.visible and player.health == 3, "Carga pasiva sin ataque ni daño automático")
	check(beam.textures.size() == 3 and beam.textures["beam_start"].get_size() == Vector2(2304,192) and beam.textures["beam_finish"].get_size() == Vector2(384,64), "Tres atlas originales cargados y tamaños correctos")
	await reset_player(Vector2(380,540))
	check(player.is_on_floor(), "Fixture Player real apoyado sobre R1")
	await capture("01_idle")
	boss.state_changed.connect(func(value: int) -> void: seen_states.append(value))
	check(boss.request_beam() and not boss.request_beam(), "Una solicitud aceptada; duplicación rechazada")
	check(beam.global_position == Vector2(980,512), "Emisor registrado al cañón Repose0")
	var origin: Vector2 = beam.global_position
	await capture("02_prepare")
	await wait_state(boss.State.BEAM_GROW)
	check(player.health == 3, "Preparación sin daño")
	await ticks(15)
	check(player.health == 3 and beam.phase == &"grow", "Crecimiento visible todavía inocuo")
	await capture("03_grow")
	await wait_state(boss.State.BEAM_ACTIVE)
	await ticks(3)
	check(player.health == 2 and player.invulnerability_frames_remaining > 0, "Intersección física del haz resta una célula e inicia invulnerabilidad normal")
	check(boss.health == 6 and not boss.core_exposed and not boss.can_receive_damage(), "Salud del jefe independiente y núcleo protegido sin cambios")
	await capture("04_active")
	await wait_state(boss.State.BEAM_FINISH)
	check(player.health == 2 and beam.phase == &"finish", "Una ventana activa respeta invulnerabilidad, desactiva daño al disipar")
	await ticks(8)
	await capture("05_finish")
	await wait_state(boss.State.RECOVER)
	check(not beam.visible, "Recuperación sin efecto persistente")
	await capture("06_recover")
	await wait_state(boss.State.IDLE)
	check(not boss.beam_running and not beam.visible and beam.global_position == origin and boss.position == Vector2(1070,620), "Fin limpio, cuerpo y emisor estables")
	check(seen_states == [boss.State.BEAM_PREPARE,boss.State.BEAM_GROW,boss.State.BEAM_ACTIVE,boss.State.BEAM_FINISH,boss.State.RECOVER,boss.State.IDLE], "Secuencia completa y un único retorno a Idle")
	await ticks(40)
	check(player.health == 2 and boss.state == boss.State.IDLE, "Sin daño residual ni repetición autónoma")
	await reset_player(Vector2(1120,600))
	boss.request_beam()
	await wait_state(boss.State.IDLE)
	check(player.health == 3, "Fuera del alcance horizontal no hay daño")
	await reset_player(Vector2(380,600))
	boss.request_beam()
	await wait_state(boss.State.IDLE)
	check(player.health == 3, "F0 debajo de la trayectoria permite evasión")
	await reset_player(Vector2(380,540))
	shift()
	await ticks(18)
	check(manager.active_dimension == 1, "Shift real a Pasado")
	boss.request_beam()
	await wait_state(boss.State.BEAM_ACTIVE)
	var active_elapsed: float = boss.beam_elapsed
	await ticks(18)
	check(player.health == 3 and boss.beam_elapsed > active_elapsed and boss.state == boss.State.BEAM_ACTIVE, "Pasado seguro durante emisión; ataque no se reinicia")
	await wait_state(boss.State.IDLE)
	check(player.health == 3, "Pasado no recibe daño en toda la secuencia")
	boss.request_beam()
	await wait_state(boss.State.BEAM_GROW)
	for tick: int in range(60):
		if boss.beam_elapsed >= 0.50:
			break
		await ticks(1)
	var before_shift: float = boss.beam_elapsed
	shift()
	await ticks(2)
	check(manager.active_dimension == 0 and boss.beam_elapsed >= before_shift and boss.state == boss.State.BEAM_GROW, "Regresar a Presente mantiene reloj del ataque")
	await wait_state(boss.State.BEAM_ACTIVE)
	check(player.is_temporally_protected() and player.health == 3, "Protección temporal real de Shift evita el primer contacto")
	await ticks(14)
	check(not player.is_temporally_protected() and player.health == 2, "Tras protección expirada el mismo haz puede impactar")
	await wait_state(boss.State.IDLE)
	await reset_player(Vector2(780,490))
	player.set_physics_process(false)
	player.position = Vector2(780,490)
	player.velocity = Vector2.ZERO
	boss.request_beam()
	shift()
	await ticks(3)
	check(manager.active_dimension == 0 and not player.is_temporally_protected() and manager.switch_cooldown_remaining == 0, "Shift rechazado por ocupación no da protección ni recarga")
	await wait_state(boss.State.BEAM_ACTIVE)
	await ticks(3)
	check(player.health == 2, "El haz detecta el cuerpo real del fixture sin protección ficticia")
	await wait_state(boss.State.IDLE)
	await reset_player(Vector2(380,540))
	boss.set_core_exposed(true)
	check(not boss.request_beam() and boss.core_exposed, "No inicia ataque durante vulnerabilidad ni cambia su regla")
	boss.set_core_exposed(false)
	boss.request_beam()
	await wait_state(boss.State.BEAM_ACTIVE)
	# Controlled lethal fixture: the protected core remains immune to ordinary sword damage.
	boss.health = 0
	await ticks(3)
	var health_after_cancel: int = player.health
	check(boss.state == boss.State.DEFEATED and not boss.beam_running and not beam.visible and beam.phase == &"off", "Derrota controlada cancela inmediatamente el haz")
	await ticks(40)
	check(player.health == health_after_cancel and not boss.request_beam(), "Derrotado no reinicia ni sigue causando daño")
	check(camera.global_transform == camera_before and camera.zoom == zoom_before and (room.get_node("CombatHUD/HealthAnchor") as Control).get_global_transform_with_canvas() == hud_before, "Cámara y HUD intactos")
	check(not FileAccess.file_exists("user://progress_v1.json"), "Sin modificaciones de progreso")
	print("BEAM_RESULT checks=",checks," failures=",failures)
	room.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
