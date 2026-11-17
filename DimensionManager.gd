extends Node

signal dimension_changed(is_present: bool)
signal dimension_change_rejected

enum Dimension {
	PRESENT,
	PAST,
}

const SWITCH_COOLDOWN: float = 0.2
const INACTIVE_OPACITY: float = 0.3

@export var present_tilemap: TileMapLayer
@export var past_tilemap: TileMapLayer
@export var rejection_sound: AudioStreamPlayer
@export var present_visuals: Node2D
@export var past_visuals: Node2D
@export var present_shapes: Array[CollisionShape2D]
@export var past_shapes: Array[CollisionShape2D]
@export var controlled_player: CharacterBody2D
@export var player_collider: CollisionShape2D

var switch_requested: bool = false

var active_dimension: int = Dimension.PRESENT
var switch_cooldown_remaining: float = 0.0


func _ready() -> void:
	_apply_dimension_state()


func _process(delta: float) -> void:
	switch_cooldown_remaining = move_toward(switch_cooldown_remaining, 0.0, delta)


func _unhandled_input(event: InputEvent) -> void:
	if controlled_player == null or not event.is_action_pressed("dimension_shift"):
		return
	get_viewport().set_input_as_handled()
	if can_request_switch():
		switch_requested = true


func can_request_switch() -> bool:
	return controlled_player != null and controlled_player.health > 0 \
		and not controlled_player.dialogue_controls_locked \
		and get_node("/root/GameProgress").get("has_temporal_lens") == true \
		and switch_cooldown_remaining <= 0.0


func _physics_process(_delta: float) -> void:
	if not switch_requested:
		return
	switch_requested = false
	if not can_request_switch():
		return
	var target: int = Dimension.PAST if active_dimension == Dimension.PRESENT else Dimension.PRESENT
	var destination: Array[CollisionShape2D] = past_shapes if target == Dimension.PAST else present_shapes
	# Query the destination shapes directly, even while disabled. A tiny inset
	# distinguishes resting contact from penetration at a shared edge.
	var collider: RectangleShape2D = player_collider.shape as RectangleShape2D
	var probe: RectangleShape2D = RectangleShape2D.new()
	probe.size = collider.size - Vector2(0.1, 0.1)
	for surface: CollisionShape2D in destination:
		if probe.collide(player_collider.global_transform, surface.shape, surface.global_transform):
			_play_rejection_sound()
			dimension_change_rejected.emit()
			return
	active_dimension = target
	_apply_dimension_state()
	switch_cooldown_remaining = SWITCH_COOLDOWN
	controlled_player.call("begin_temporal_protection")
	dimension_changed.emit(active_dimension == Dimension.PRESENT)


func toggle_dimension(player: CharacterBody2D) -> void:
	if switch_cooldown_remaining > 0.0:
		return
	if present_tilemap == null or past_tilemap == null:
		push_error("C.O.R.E.-9: Lente Temporal sin capas asignadas. Un fracaso administrativo impecable.")
		return

	var previous_dimension: int = active_dimension
	var target_dimension: int = Dimension.PAST if active_dimension == Dimension.PRESENT else Dimension.PRESENT
	active_dimension = target_dimension
	_apply_dimension_state()

	if player.test_move(player.global_transform, Vector2.ZERO):
		active_dimension = previous_dimension
		_apply_dimension_state()
		_play_rejection_sound()
		print("C.O.R.E.-9: Error: espacio ocupado. Qué previsible.")
		return

	switch_cooldown_remaining = SWITCH_COOLDOWN
	dimension_changed.emit(active_dimension == Dimension.PRESENT)


func _apply_dimension_state() -> void:
	var is_present: bool = active_dimension == Dimension.PRESENT
	if controlled_player != null:
		for surface: CollisionShape2D in (past_shapes if is_present else present_shapes):
			surface.disabled = true
		for surface: CollisionShape2D in (present_shapes if is_present else past_shapes):
			surface.disabled = false
		present_visuals.visible = is_present
		past_visuals.visible = not is_present
		return
	present_tilemap.collision_enabled = is_present
	past_tilemap.collision_enabled = not is_present
	present_tilemap.modulate.a = 1.0 if is_present else INACTIVE_OPACITY
	past_tilemap.modulate.a = INACTIVE_OPACITY if is_present else 1.0


## Restore a room checkpoint before the Player's physics step.
func restore_present_at_checkpoint() -> void:
	switch_requested = false
	switch_cooldown_remaining = 0.0
	if controlled_player != null:
		controlled_player.call("cancel_temporal_protection")
	active_dimension = Dimension.PRESENT
	_apply_dimension_state()
	# Refresh observers even if the dimension was already Present.
	dimension_changed.emit(true)


func _play_rejection_sound() -> void:
	if rejection_sound != null:
		rejection_sound.play()
