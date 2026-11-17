extends SceneTree

var failures: int = 0
var starts: int = 0
var ends: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
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

func _run() -> void:
	var progress: Node = root.get_node("GameProgress")
	progress.has_temporal_lens = true
	var room: Node2D = (load("res://scenes/Room4.tscn") as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	var player: CharacterBody2D = room.get_node("Player")
	var manager: Node = room.get_node("DimensionManager")
	player.temporal_protection_started.connect(func(_duration: float) -> void: starts += 1)
	player.temporal_protection_ended.connect(func() -> void: ends += 1)
	await ticks(2)
	await create_timer(0.05).timeout
	check(not player.is_temporally_protected(), "Aparición sin protección")
	shift()
	await ticks(3)
	check(manager.active_dimension == 1 and player.is_temporally_protected() and starts == 1, "Cambio aceptado activa protección")
	check(player.get_temporal_protection_remaining() > 0.0 and manager.switch_cooldown_remaining > 0.0, "Protección y recarga independientes")
	var projectile: Area2D = (load("res://scenes/combat/EnemyProjectile.tscn") as PackedScene).instantiate()
	room.add_child(projectile)
	projectile._on_body_entered(player)
	check(player.health == 3 and player.invulnerability_frames_remaining == 0 and projectile.consumed, "Proyectil real consumido sin daño ni invulnerabilidad normal")
	player.take_damage(1)
	check(player.health == 3, "Daño común rechazado durante protección")
	shift()
	await ticks(3)
	check(starts == 1 and manager.active_dimension == 1, "Shift durante recarga no reinicia protección")
	await create_timer(0.17).timeout
	check(not player.is_temporally_protected() and ends == 1, "Protección finaliza tras 0,16 s")
	check(manager.switch_cooldown_remaining <= 0.05, "Recarga conserva su propio reloj")
	player.take_damage(1)
	check(player.health == 2 and player.invulnerability_frames_remaining > 0, "Daño vuelve a funcionar e inicia invulnerabilidad normal")
	await create_timer(0.08).timeout
	shift()
	await ticks(3)
	check(player.is_temporally_protected() and player.invulnerability_frames_remaining > 0, "Ambas protecciones coexisten")
	await create_timer(0.18).timeout
	check(not player.is_temporally_protected() and player.invulnerability_frames_remaining > 0, "Fin temporal conserva invulnerabilidad por daño")
	manager.restore_present_at_checkpoint()
	check(not player.is_temporally_protected() and manager.switch_cooldown_remaining == 0.0, "Recuperación limpia protección y recarga")
	await create_timer(1.05).timeout
	check(player.invulnerability_frames_remaining == 0, "Invulnerabilidad normal mantiene sus 60 pasos físicos")
	shift()
	await ticks(3)
	check(player.is_temporally_protected(), "Protección activa antes de caer")
	player.position = Vector2(350, 700)
	await ticks(3)
	check(player.health == 2 and not player.is_temporally_protected() and manager.active_dimension == 0 and manager.switch_cooldown_remaining == 0.0, "Caída real de Room4 recupera sin protección residual")
	player.set_physics_process(false)
	player.position = Vector2(450, 405)
	player.set_physics_process(true)
	shift()
	await ticks(3)
	check(manager.active_dimension == 0 and not player.is_temporally_protected(), "Cambio rechazado sin protección")
	player.position = Vector2(64, 396)
	progress.has_temporal_lens = false
	shift()
	await ticks(3)
	check(manager.active_dimension == 0 and not player.is_temporally_protected(), "Sin Lente no hay protección")
	progress.has_temporal_lens = true
	player.invulnerability_frames_remaining = 1
	shift()
	await ticks(3)
	check(player.is_temporally_protected() and player.invulnerability_frames_remaining == 0, "Fin de invulnerabilidad por daño conserva protección temporal")
	player.health = 0
	player.defeated.emit()
	check(not player.is_temporally_protected(), "Derrota cancela protección")
	room.queue_free()
	await process_frame
	var fresh_room: Node2D = (load("res://scenes/Room4.tscn") as PackedScene).instantiate()
	root.add_child(fresh_room)
	check(not fresh_room.get_node("Player").is_temporally_protected(), "Instancia nueva no hereda protección")
	fresh_room.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
