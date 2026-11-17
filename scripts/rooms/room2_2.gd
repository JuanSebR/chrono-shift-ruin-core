extends "res://scripts/rooms/room2.gd"

const VOID_DEATH_Y: float = 750.0

var void_defeat_pending: bool = false

func _ready() -> void:
	super._ready()
	(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h = false

func _physics_process(_delta: float) -> void:
	if player.health <= 0 or void_defeat_pending:
		return
	if player.position.y > VOID_DEATH_Y:
		_trigger_void_defeat()


func _trigger_void_defeat() -> void:
	void_defeat_pending = true
	get_node("/root/GameProgress").call("clear_room_arrival")
	player.call("_cancel_presentation")
	player.health = 0
	player.velocity = Vector2.ZERO
	player.invulnerability_frames_remaining = 0
	(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).modulate.a = 1.0
	player.health_changed.emit(0)
	player.damage_taken.emit(0)
	player.call("_start_presentation", &"defeat")
	player.defeated.emit()
	print("C.O.R.E.-9: El vacio reclama otra victoria burocratica. Reinicio local iniciado.")
