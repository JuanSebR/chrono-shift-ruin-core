extends SceneTree

const ROOM_PATH: String = "res://scenes/Room1_Tutorial.tscn"


func _init() -> void:
	var packed_scene: PackedScene = load(ROOM_PATH) as PackedScene
	if packed_scene == null:
		push_error("C.O.R.E.-9: No se encontro la sala. El vacio gana otra vez.")
		quit(1)
		return
	var room: Node2D = packed_scene.instantiate() as Node2D
	var setup: Node = room.get_node("AssetsSetup")
	setup.call("_setup_background", room)
	setup.call("_setup_tilemaps", room)
	setup.call("_setup_player", room)

	var present: TileMapLayer = room.get_node("TileMapLayer_Present") as TileMapLayer
	var past: TileMapLayer = room.get_node("TileMapLayer_Past") as TileMapLayer
	print("BAKE: present tile_set=%s cells=%d" % [present.tile_set != null, present.get_used_cells().size()])
	print("BAKE: past tile_set=%s cells=%d" % [past.tile_set != null, past.get_used_cells().size()])

	var baked: PackedScene = PackedScene.new()
	var pack_error: Error = baked.pack(room)
	if pack_error != OK:
		push_error("C.O.R.E.-9: No se pudo empaquetar la sala. Una obra maestra fallida.")
		quit(1)
		return
	var save_error: Error = ResourceSaver.save(baked, ROOM_PATH)
	if save_error != OK:
		push_error("C.O.R.E.-9: No se pudo guardar la sala editada.")
		quit(1)
		return
	print("BAKE: escena guardada con los tiles embebidos.")
	quit()
