extends Node

const SHIFT: String = "room4_shift"
const PRESENT: String = "room4_present"
const PAST: String = "room4_past"

@onready var player: CharacterBody2D = $"../Player"
@onready var manager: Node = $"../DimensionManager"
@onready var hints: CanvasLayer = $"../TutorialHints"
@onready var progress: Node = get_node("/root/GameProgress")
@onready var metal_left: StaticBody2D = $"../WorldCollision/PresentCollision/MetalLeft"
@onready var past_left: StaticBody2D = $"../WorldCollision/PastCollision/PastLeft"

var jumping: bool = false
var shifted_to_past_in_jump: bool = false

func _ready() -> void:
	manager.dimension_changed.connect(_on_dimension_changed)
	get_parent().fall_recovered.connect(_clear_jump)

func _clear_jump() -> void:
	jumping = false
	shifted_to_past_in_jump = false

func _on_dimension_changed(is_present: bool) -> void:
	if manager.switch_cooldown_remaining <= 0.0 or not _can_teach():
		return
	progress.complete_tutorial(SHIFT)
	shifted_to_past_in_jump = not is_present and jumping and not player.is_on_floor()

func _can_teach() -> bool:
	return progress.has_temporal_lens and player.health > 0 and not player.dialogue_controls_locked and progress.active_dialogue_id.is_empty()

func _physics_process(_delta: float) -> void:
	if not _can_teach():
		hints.hide_hint()
		return
	if player.is_on_floor():
		for index: int in range(player.get_slide_collision_count()):
			var contact: KinematicCollision2D = player.get_slide_collision(index)
			if contact.get_normal().y >= -0.9:
				continue
			if contact.get_collider() == metal_left:
				progress.complete_tutorial(PRESENT)
			elif contact.get_collider() == past_left and shifted_to_past_in_jump:
				progress.complete_tutorial(PAST)
		_clear_jump()
	elif player.velocity.y < 0.0:
		jumping = true
	var anchor: Vector2 = Vector2(player.global_position.x + 150.0, player.global_position.y - 90.0)
	if not progress.tutorial_completed(SHIFT):
		hints.show_hint(SHIFT, "SHIFT — CAMBIAR DE DIMENSIÓN", anchor)
	elif not progress.tutorial_completed(PRESENT):
		hints.show_hint(PRESENT, "PRESENTE — PLATAFORMAS METÁLICAS", anchor)
	elif not progress.tutorial_completed(PAST) and player.global_position.x >= 155.0 and player.global_position.x <= 530.0:
		hints.show_hint(PAST, "PASADO — CAMBIA ANTES DE ATERRIZAR", anchor)
	else:
		hints.hide_hint()
