extends Area2D

@export_file("*.tscn") var next_scene_path: String = "res://scenes/Room1_5.tscn"
@export var arrival_marker: StringName = &"EntryFromTutorial"
var transition_pending: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player" or (body.is_in_group("core9_player") and int(body.get("health")) <= 0):
		return
	if transition_pending or not body is CharacterBody2D or not body.is_in_group("core9_player"):
		return
	if next_scene_path.is_empty() or not ResourceLoader.exists(next_scene_path):
		push_error("C.O.R.E.-9: Destino inexistente. El vacio ofrece mejores conexiones.")
		return
	transition_pending = true
	get_node("/root/GameProgress").call("prepare_room_arrival", next_scene_path, arrival_marker, body, self)
	call_deferred("_change_room")

func _change_room() -> void:
	var error: Error = get_tree().change_scene_to_file(next_scene_path)
	if error != OK:
		get_node("/root/GameProgress").call("clear_room_arrival")
		transition_pending = false
		push_error("C.O.R.E.-9: La sala no carga. Otra puerta decorativa.")
