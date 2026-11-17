extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in count:
		await physics_frame
		await process_frame

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func run() -> void:
	var room: Node2D = load("res://scenes/Room1_Tutorial.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(10)
	var manager: Node = room
	var dimension: Node = room.get_node("DimensionManager")
	var hud: CanvasLayer = room.get_node("HUD")
	var before: int = int(dimension.get("active_dimension"))
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.pressed = true
	manager.call("_unhandled_input", event)
	await frames(2)
	check(int(dimension.get("active_dimension")) == before, "Shift stays locked before lens acquisition")
	check(hud.get("lens_cooldown_remaining") == null or hud.get("lens_cooldown_remaining") == 0.0, "Shift does not start temporal cooldown")
	check(not root.get_node("GameProgress").get("has_temporal_lens"), "new progression has no temporal lens")
	print("TEMPORAL_LENS_LOCK_RESULT failures=", failures)
	quit(1 if failures else 0)
