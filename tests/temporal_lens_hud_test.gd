extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1


func _run() -> void:
	var progress: Node = root.get_node("GameProgress")
	var original_lens_state: bool = bool(progress.get("has_temporal_lens"))
	progress.set("has_temporal_lens", false)

	var lens_scene: PackedScene = load("res://scenes/ui/TemporalLensHUD.tscn") as PackedScene
	_check(lens_scene != null and lens_scene.can_instantiate(), "TemporalLensHUD loads")
	var lens_hud: Control = lens_scene.instantiate() as Control
	root.add_child(lens_hud)
	await process_frame
	_check(not lens_hud.visible, "hidden before acquisition")
	_check(lens_hud.mouse_filter == Control.MOUSE_FILTER_IGNORE, "does not block input")

	progress.set("has_temporal_lens", true)
	progress.temporal_lens_acquired.emit()
	await create_timer(0.35).timeout
	_check(lens_hud.visible, "visible after acquisition")
	_check((lens_hud.get_node("LensIcon") as TextureRect).texture != null, "neutral ownership icon assigned")
	_check(not lens_hud.has_method("start_temporal_lens_cooldown"), "no fictitious cooldown API")
	lens_hud.queue_free()
	await process_frame

	var combat_scene: PackedScene = load("res://scenes/ui/CombatHUD.tscn") as PackedScene
	var combat_hud: CanvasLayer = combat_scene.instantiate() as CanvasLayer
	root.add_child(combat_hud)
	await process_frame
	_check(combat_hud.get_node_or_null("TemporalLensHUD") != null, "single shared integration")
	_check((combat_hud.get_node("TemporalLensHUD") as Control).visible, "continue state restored")
	combat_hud.call("update_health", 2)
	_check((combat_hud.get_node("HealthAnchor/HealthValue") as Label).text == "INTEGRIDAD  2/3", "health HUD remains functional")
	combat_hud.queue_free()
	await process_frame

	for room_path: String in [
		"res://scenes/Room1_Tutorial.tscn",
		"res://scenes/Room1_5.tscn",
		"res://scenes/Room2.tscn",
		"res://scenes/Room2_2.tscn",
		"res://scenes/Room3.tscn",
	]:
		var room: Node = (load(room_path) as PackedScene).instantiate()
		var lens_nodes: Array[Node] = room.find_children("TemporalLensHUD", "Control", true, false)
		_check(lens_nodes.size() == 1, "one lens HUD in " + room_path.get_file())
		room.free()

	progress.set("has_temporal_lens", false)
	var new_game_hud: Control = lens_scene.instantiate() as Control
	root.add_child(new_game_hud)
	await process_frame
	_check(not new_game_hud.visible, "new game state hidden")
	new_game_hud.queue_free()
	progress.set("has_temporal_lens", original_lens_state)
	print("TEMPORAL_LENS_HUD_RESULT failures=", failures)
	quit(1 if failures > 0 else 0)
