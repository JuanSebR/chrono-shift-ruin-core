extends Node

const ROOM_RESTART_DELAY: float = 0.25

@export var player: CharacterBody2D
@export var dimension_manager: Node
@export var hud: CanvasLayer

var restart_pending: bool = false
var tutorial_start_x: float = 0.0
var jump_was_grounded: bool = false


func _ready() -> void:
	get_node("/root/GameProgress").call("apply_room_arrival", self, player)
	_connect_dimension_manager()
	_connect_player()
	if player != null and hud != null:
		hud.call("update_health", player.health)
	if player != null:
		tutorial_start_x = player.global_position.x
		jump_was_grounded = player.is_on_floor()

func _physics_process(_delta: float) -> void:
	if player == null or player.health <= 0:
		return
	var progress: Node = get_node("/root/GameProgress")
	var hints: CanvasLayer = get_node("TutorialHints") as CanvasLayer
	if str($DialoguePanel.get("active_id")) != "":
		hints.call("hide_hint")
		return
	if not bool(progress.call("tutorial_completed", "move")) and tutorial_start_x < 250.0:
		if absf(player.global_position.x - tutorial_start_x) >= 28.0:
			progress.call("complete_tutorial", "move")
			hints.call("hide_hint")
		else:
			hints.call("show_hint", "move", "A / D — MOVERSE", Vector2(115.0, 230.0))
	elif not bool(progress.call("tutorial_completed", "jump")) and player.global_position.x >= 300.0 and player.global_position.x < 700.0:
		if jump_was_grounded and player.velocity.y < -50.0:
			progress.call("complete_tutorial", "jump")
			hints.call("hide_hint")
		else:
			hints.call("show_hint", "jump", "ESPACIO — SALTAR", Vector2(425.0, 305.0))
	else:
		hints.call("hide_hint")
	jump_was_grounded = player.is_on_floor()


func _unhandled_input(event: InputEvent) -> void:
	if player == null or player.health <= 0 or bool(player.get("dialogue_controls_locked")) or dimension_manager == null or not _is_dimension_shift_event(event):
		return
	var progress: Node = get_node("/root/GameProgress")
	if not progress.get("has_temporal_lens"):
		get_viewport().set_input_as_handled()
		return
	dimension_manager.call("toggle_dimension", player)
	get_viewport().set_input_as_handled()


func _connect_dimension_manager() -> void:
	if dimension_manager != null:
		dimension_manager.connect("dimension_changed", _on_dimension_changed)


func _connect_player() -> void:
	if player == null:
		return
	player.health_changed.connect(_on_health_changed)
	player.damage_taken.connect(_on_damage_taken)
	player.defeated.connect(_on_player_defeated)


func _is_dimension_shift_event(event: InputEvent) -> bool:
	if event.is_action_pressed("dimension_shift"):
		return true
	if event is InputEventKey:
		var key_event: InputEventKey = event
		return key_event.pressed and not key_event.echo and (key_event.keycode == KEY_K or key_event.keycode == KEY_SHIFT)
	if event is InputEventJoypadButton:
		var button_event: InputEventJoypadButton = event
		return button_event.pressed and button_event.button_index == JOY_BUTTON_RIGHT_SHOULDER
	return false


func _on_dimension_changed(is_present: bool) -> void:
	if hud == null:
		return
	hud.call("update_dimension_theme", is_present)


func _on_health_changed(current_health: int) -> void:
	if hud != null:
		hud.call("update_health", current_health)


func _on_damage_taken(_current_health: int) -> void:
	if hud != null:
		hud.call("on_damage_taken", _current_health)


func _on_player_defeated() -> void:
	if restart_pending:
		return
	restart_pending = true
	if hud != null:
		hud.call("show_game_over_log")
	await player.defeat_animation_finished
	await get_tree().create_timer(ROOM_RESTART_DELAY).timeout
	get_tree().call_deferred("reload_current_scene")
