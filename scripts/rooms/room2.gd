extends Node2D

const ROOM_RESTART_DELAY: float = 0.25

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $CombatHUD

var restart_pending: bool = false


func _ready() -> void:
	get_node("/root/GameProgress").call("apply_room_arrival", self, player)
	player.health_changed.connect(_on_health_changed)
	player.damage_taken.connect(_on_damage_taken)
	player.defeated.connect(_on_player_defeated)
	hud.call("update_health", int(player.get("health")))


func _on_health_changed(current_health: int) -> void:
	hud.call("update_health", current_health)


func _on_damage_taken(current_health: int) -> void:
	hud.call("on_damage_taken", current_health)


func _on_player_defeated() -> void:
	if restart_pending:
		return
	restart_pending = true
	hud.call("show_game_over_log")
	await player.defeat_animation_finished
	await get_tree().create_timer(ROOM_RESTART_DELAY).timeout
	get_tree().call_deferred("reload_current_scene")
