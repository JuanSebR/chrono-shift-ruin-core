extends Node2D

const SPAWN_POSITION: Vector2 = Vector2(60.0, 352.0)

@onready var player: CharacterBody2D = $Player
@onready var fall_zone: Area2D = $FallReset


func _ready() -> void:
	get_node("/root/GameProgress").call("apply_room_arrival", self, player)
	fall_zone.body_entered.connect(_on_fall_zone_body_entered)
	player.connect("health_changed", _on_health_changed)
	player.connect("damage_taken", _on_damage_taken)
	player.connect("defeated", _on_player_defeated)
	get_node("/root/GameProgress").connect("sword_acquired", _on_sword_acquired)
	get_node("/root/GameProgress").connect("save_failed", _on_save_failed)
	player.energy_slash_used.connect(_on_valid_attack)
	$Enemy1.connect("defeated", _on_enemy_defeated)
	_on_health_changed(int(player.get("health")))
	if not bool(get_node("/root/GameProgress").get("has_cronal_sword")):
		_show_message("Una espada abandonada. Seguro que no es una trampa.")


func _on_fall_zone_body_entered(body: Node2D) -> void:
	if body != player or int(player.get("health")) <= 0:
		return
	player.global_position = SPAWN_POSITION
	player.velocity = Vector2.ZERO
	print("C.O.R.E.-9: El suelo era opcional, al parecer. Reiniciando tu brillante excursion al vacio.")


var message_remaining: float = 0.0
var defeat_pending: bool = false

func _process(delta: float) -> void:
	var progress: Node = get_node("/root/GameProgress")
	if str($DialoguePanel.get("active_id")) == "" and bool(progress.get("has_cronal_sword")) and not bool(progress.call("tutorial_completed", "attack")) and player.global_position.x < 550.0 and int(player.get("health")) > 0:
		$TutorialHints.show_hint("attack", "CLIC IZQUIERDO — ATACAR", Vector2(300.0, 270.0))
	else:
		$TutorialHints.hide_hint()
	message_remaining = maxf(0.0, message_remaining - delta)
	if message_remaining <= 0.0:
		$CombatHUD/Message.text = ""

func _show_message(message: String) -> void:
	$CombatHUD/Message.text = message
	message_remaining = 5.0

func _on_sword_acquired() -> void:
	$NarrativeEvents.call("on_sword_acquired")

func _on_valid_attack() -> void:
	get_node("/root/GameProgress").call("complete_tutorial", "attack")
	$TutorialHints.hide_hint()

func _on_save_failed() -> void:
	call_deferred("_show_message", "El disco olvido guardar. Espada disponible solo en esta sesion.")

func _on_health_changed(value: int) -> void:
	$CombatHUD.update_health(value)

func _on_damage_taken(value: int) -> void:
	$CombatHUD.on_damage_taken(value)

func _on_enemy_defeated() -> void:
	$NarrativeEvents.call("on_enemy_defeated")

func _on_player_defeated() -> void:
	if defeat_pending:
		return
	defeat_pending = true
	_show_message("Fin del turno. Otra vez. Preparando otra oportunidad inmerecida.")
	await player.defeat_animation_finished
	await get_tree().create_timer(0.25).timeout
	get_tree().call_deferred("reload_current_scene")
