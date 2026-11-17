extends "res://tests/room4_route_test.gd"

var arrivals: Array[Dictionary] = []
var progress: Node

func require(ok: bool, label: String) -> bool:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1
		quit(1)
	return ok

func ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame

func act(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)

func observe_arrival() -> void:
	var actor: CharacterBody2D = current_scene.get_node_or_null("Player")
	if actor != null:
		arrivals.append({"room": current_scene.name, "position": actor.position, "velocity": actor.velocity})

func walk_until(action: StringName, condition: Callable, maximum_ticks: int) -> bool:
	Input.action_press(action)
	for index: int in range(maximum_ticks):
		if condition.call():
			break
		await physics_frame
	Input.action_release(action)
	return condition.call()

func capture(label: String) -> void:
	if not capture_enabled:
		return
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var directory: String = "res://artifacts/room4_stage_h"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if image.save_png("%s/%s_%dx%d.png" % [directory, label, image.get_width(), image.get_height()]) != OK:
		failures += 1

func _run() -> void:
	capture_enabled = DisplayServer.get_name() != "headless"
	if capture_enabled:
		root.size = Vector2i(1280, 720) if "1280" in OS.get_cmdline_user_args() else Vector2i(1024, 572)
	progress = root.get_node("GameProgress")
	scene_changed.connect(observe_arrival)
	progress.new_game()
	progress.acquire_sword()
	change_scene_to_file("res://scenes/Room2_2.tscn")
	await scene_changed
	player = current_scene.get_node("Player")
	# Scope starts on the final approach in Room2.2. All later travel uses input.
	player.position = Vector2(1870, 480)
	player.health = 2
	if not require(await walk_until(&"move_right", func() -> bool: return is_room(&"Room3"), 100), "Room2.2 → Room3"):
		return
	player = current_scene.get_node("Player")
	var room3: Node2D = current_scene
	var module: AnimatedSprite2D = room3.get_node("TemporalModule/ModuleVisual")
	if not require(module.visible and module.animation == &"levitation" and not room3.get_node("CombatHUD/TemporalLensHUD").visible and not room3.get_node("RoomTransitions/ToRoom4").monitoring, "Room3 antes de la Lente"):
		return
	if not require(await walk_until(&"move_right", func() -> bool: return player.position.x >= 1132.0, 350), "Aproximación real al pedestal"):
		return
	await ticks(10)
	if not require(room3.get_node("TemporalModule/InteractionPrompt").visible, "Indicación E"):
		return
	act(&"dialogue_advance")
	await ticks(20)
	if not require(room3.acquisition_running and player.dialogue_controls_locked and module.animation == &"disappear" and not room3.get_node("RoomTransitions/ToRoom4").monitoring, "Cinemática y puerta cerrada"):
		return
	act(&"dialogue_advance")
	await ticks(65)
	if not require(progress.has_temporal_lens and not module.visible and not player.dialogue_controls_locked, "Adquisición única y control restaurado"):
		return
	Input.action_press(&"jump")
	Input.action_press(&"move_right")
	await ticks(38)
	Input.action_release(&"jump")
	if not require(await walk_until(&"move_right", func() -> bool: return is_room(&"Room4"), 150), "Arco accesible y entrada en Room4"):
		return
	player = current_scene.get_node("Player")
	manager = current_scene.get_node("DimensionManager")
	if not require(arrivals.back().position == Vector2(64, 396) and arrivals.back().velocity == Vector2.ZERO and current_scene.checkpoint.name == &"Spawn" and player.health == 2 and manager.active_dimension == 0 and manager.switch_cooldown_remaining == 0.0 and not player.get_node("AnimatedSprite2D").flip_h, "Llegada exacta, Presente, salud y checkpoint"):
		return
	await ticks(12)
	await capture("entrada_presente")
	var room4: Node2D = current_scene
	var recovery_count: Array[int] = [0]
	room4.fall_recovered.connect(func() -> void:
		recovery_count[0] += 1
		Input.action_release(&"move_right")
	)
	if not require(await walk_until(&"move_right", func() -> bool: return recovery_count[0] == 1, 100), "Caída real antes del centro"):
		return
	await ticks(10)
	if not require(support() == "EntryLedge" and player.health == 2, "Recuperación en entrada"):
		return
	for origin: int in range(3):
		if not require(await jump(origin, origin + 1, 21 if origin == 1 else -1, 5, 40), "Ida tramo %d" % (origin + 1)):
			return
	if not require(room4.checkpoint.name == &"CentralCheckpoint" and progress.tutorial_completed("room4_shift") and progress.tutorial_completed("room4_present") and progress.tutorial_completed("room4_past"), "Checkpoint central y tres aprendizajes"):
		return
	await capture("centro_pasado")
	if not require(await walk_until(&"move_right", func() -> bool: return recovery_count[0] == 2, 125), "Caída real desde el centro en Pasado"):
		return
	await ticks(10)
	if not require(support() == "CentralRest" and manager.active_dimension == 0 and manager.switch_cooldown_remaining == 0.0 and player.health == 2, "Recuperación central en Presente"):
		return
	await capture("centro_recuperado")
	for origin: int in range(3, 6):
		if not require(await jump(origin, origin + 1, 21 if origin == 4 else -1, 5, 40), "Ida tramo %d" % (origin + 1)):
			return
	if not require(await walk_until(&"move_right", func() -> bool: return player.position.x >= 1210.0, 50), "Repisa final X ≥ 1210"):
		return
	await ticks(10)
	if not require(support() == "ExitLedge" and room4.has_node("EntryMarkers/FutureRoom5Access") and room4.get_node("RoomTransitions").get_child_count() == 1, "Repisa segura y salida futura inactiva"):
		return
	await capture("repisa_final")
	for origin: int in range(6, 0, -1):
		if not require(await jump(origin, origin - 1, 19 if origin in [5, 3, 2] else -1, 5, 40), "Regreso tramo %d" % origin):
			return
	if not await return_to_room3(&"Presente"):
		return
	if not require(await walk_until(&"move_right", func() -> bool: return is_room(&"Room4"), 70), "Reingreso sin bucle"):
		return
	player = current_scene.get_node("Player")
	manager = current_scene.get_node("DimensionManager")
	await ticks(18)
	if not require(current_scene.checkpoint.name == &"Spawn" and manager.active_dimension == 0 and current_scene.get_node("TutorialHints").active_id.is_empty(), "Instancia nueva sin checkpoint ni avisos heredados"):
		return
	shift()
	await ticks(18)
	if not require(manager.active_dimension == 1, "Pasado antes del segundo regreso"):
		return
	if not await return_to_room3(&"Pasado"):
		return
	await capture("regreso_pedestal_vacio")
	change_scene_to_file("res://scenes/MainMenu.tscn")
	await scene_changed
	progress.has_temporal_lens = false
	progress.has_cronal_sword = false
	progress.completed_tutorials = progress.TUTORIAL_DEFAULTS.duplicate()
	current_scene.call("_on_continue_pressed")
	await ticks(8)
	if not require(is_room(&"Room1_5") and progress.has_temporal_lens and progress.has_cronal_sword and progress.tutorial_completed("room4_past"), "Continuar real restaura progreso"):
		return
	current_scene.get_node("Player").take_damage(3)
	await ticks(140)
	if not require(is_room(&"Room1_5") and current_scene.get_node("Player").health == 3 and progress.has_temporal_lens and progress.tutorial_completed("room4_past"), "Derrota y reinicio conservan progreso"):
		return
	change_scene_to_file("res://scenes/MainMenu.tscn")
	await scene_changed
	current_scene.call("_on_new_game_pressed")
	await ticks(8)
	if not require(is_room(&"Room1_Tutorial") and not progress.has_temporal_lens and not progress.tutorial_completed("room4_shift") and not progress.tutorial_completed("room4_present") and not progress.tutorial_completed("room4_past"), "Nueva Partida real reinicia Lente y tutoriales"):
		return
	change_scene_to_file("res://scenes/Room3.tscn")
	await scene_changed
	require(current_scene.get_node("TemporalModule/ModuleVisual").visible and not current_scene.get_node("CombatHUD/TemporalLensHUD").visible, "Módulo restaurado tras Nueva Partida")
	quit(0 if failures == 0 else 1)

func is_room(name: StringName) -> bool:
	return current_scene != null and current_scene.name == name

func return_to_room3(dimension: StringName) -> bool:
	if not require(await walk_until(&"move_left", func() -> bool: return is_room(&"Room3"), 65), "Room4 → Room3 desde " + str(dimension)):
		return false
	player = current_scene.get_node("Player")
	return require(arrivals.back().position == Vector2(1570, 703) and arrivals.back().velocity == Vector2.ZERO and player.health == 2 and not current_scene.get_node("TemporalModule/ModuleVisual").visible and current_scene.get_node("CombatHUD/TemporalLensHUD/Status").text == "LENTE INSTALADA", "Retorno exacto, pedestal vacío y HUD neutral")
