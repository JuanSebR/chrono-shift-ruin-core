extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	assert(OS.get_user_data_dir().contains("cycle60_work"))
	var progress: Node = root.get_node("GameProgress")
	assert(progress.core_guardian_defeated) # Actual victory from the previous process.
	var room: Node2D = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	for i: int in range(20):
		await physics_frame
	assert(room.room_cleared and not room.get_node("CoreGuardian").visible)
	assert(room.get_node("CoreGuardian").process_mode == Node.PROCESS_MODE_DISABLED)
	assert(not room.get_node("EncounterTrigger").monitoring and not room.get_node("BossHUD").anchor.visible)
	assert(room.get_node("RoomTransitions/ToRoom4").monitoring)
	room.queue_free()
	await process_frame
	assert(progress.new_game() and not progress.core_guardian_defeated)
	# New-game room fixture, not a traversal of the preceding rooms.
	room = load("res://scenes/Room5.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	for i: int in range(20):
		await physics_frame
	assert(room.get_node("CoreGuardian").health == 3 and room.get_node("CoreGuardian").visible)
	assert(room.get_node("EncounterTrigger").monitoring and not room.room_cleared)
	room.queue_free()
	await process_frame
	print("CYCLE_RESUME_PASS: saved victory restored in new process, cleared room safe, new game rearms3HP")
	quit(0)
