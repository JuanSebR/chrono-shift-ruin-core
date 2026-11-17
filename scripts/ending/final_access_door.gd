extends Area2D

const DESTINATION: String = "res://scenes/FinalRoom.tscn"
var room: Node2D
var player: CharacterBody2D
var unlocked: bool = false
var transition_pending: bool = false

func _ready() -> void:
	room = get_parent() as Node2D
	player = room.get_node("Player") as CharacterBody2D

func _process(_delta: float) -> void:
	unlocked = is_unlocked()
	$Prompt.visible = unlocked and not transition_pending and overlaps_body(player)

func is_unlocked() -> bool:
	return is_instance_valid(room) and bool(get_node("/root/GameProgress").core_guardian_defeated) \
		and room.victory_persisted and room.encounter_state == room.EncounterState.BOSS_DEFEATED \
		and not room.exit_blocked and not room.restart_pending and player.health > 0

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if try_enter():
			get_viewport().set_input_as_handled()

func try_enter() -> bool:
	if transition_pending or not is_unlocked() or not overlaps_body(player) or get_tree().current_scene != room:
		return false
	transition_pending = true
	$Prompt.hide()
	call_deferred("_change_room")
	return true

func _change_room() -> void:
	if get_tree().current_scene != room:
		return
	if is_unlocked():
		get_node("/root/GameProgress").clear_room_arrival()
		var error: Error = get_tree().change_scene_to_file(DESTINATION)
		if error == OK:
			return
		push_error("C.O.R.E.-9: El final no carga. Hasta las despedidas necesitan mantenimiento.")
	transition_pending = false
