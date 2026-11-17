extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var room: Node2D = (load("res://scenes/Room4.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var camera: Camera2D = room.get_node("Player/Camera2D")
	var player: CharacterBody2D = room.get_node("Player")
	var path: String = "res://artifacts/room4_stage_b/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	for view: Array in [
		["entry_1024", Vector2i(1024, 572), Vector2(64, 396), false, false],
		["center_1024", Vector2i(1024, 572), Vector2(646, 442), false, false],
		["right_1280", Vector2i(1280, 720), Vector2(1188, 264), false, false],
		["present_full", Vector2i(1280, 720), Vector2(64, 396), true, false],
		["past_full", Vector2i(1280, 720), Vector2(64, 396), true, true],
	]:
		root.size = view[1]
		player.position = view[2]
		player.velocity = Vector2.ZERO
		camera.zoom = Vector2.ONE if view[3] else Vector2(1.14, 1.14)
		room.get_node("Visuals/Present").visible = not view[4]
		room.get_node("Visuals/Past").visible = view[4]
		camera.reset_smoothing()
		if view[3]:
			root.content_scale_size = Vector2i(1280, 720)
			camera.enabled = false
			root.canvas_transform = Transform2D.IDENTITY
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		if image.get_size() != view[1] or image.save_png(path + view[0] + ".png") != OK:
			quit(1)
			return
		print(view[0], " ", image.get_size())
	quit()
