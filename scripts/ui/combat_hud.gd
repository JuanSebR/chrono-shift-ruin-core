extends CanvasLayer

const MAX_HEALTH: int = 3
const CRITICAL_FRAME_DURATION: float = 0.12
const CRITICAL_PAUSE: float = 0.65
const LOSS_FRAME_DURATION: float = 0.065
const ASSET_ROOT: String = "res://assets/ui/hud/health/"

@onready var health_frame: TextureRect = $HealthAnchor/HealthFrame
@onready var lost_effect: TextureRect = $HealthAnchor/LostEffect
@onready var health_value: Label = $HealthAnchor/HealthValue
@onready var message_label: Label = $Message

var displayed_health: int = MAX_HEALTH
var previous_health: int = MAX_HEALTH
var is_present: bool = true
var critical_index: int = 0
var critical_elapsed: float = 0.0
var loss_index: int = -1
var loss_elapsed: float = 0.0
var log_remaining: float = 0.0
var static_frames: Dictionary = {}
var critical_frames: Dictionary = {}
var loss_frames: Array[Texture2D] = []


func _ready() -> void:
	for dimension: String in ["present", "past"]:
		var states: Array[Texture2D] = []
		var animation: Array[Texture2D] = []
		for count: int in 4:
			states.append(load(ASSET_ROOT + "health_%s_%d.png" % [dimension, count]) as Texture2D)
		for index: int in 8:
			animation.append(load(ASSET_ROOT + "critical_%s_%02d.png" % [dimension, index]) as Texture2D)
		static_frames[dimension] = states
		critical_frames[dimension] = animation
	for index: int in 8:
		loss_frames.append(load(ASSET_ROOT + "lost_%02d.png" % index) as Texture2D)
	message_label.visible = false
	update_health(MAX_HEALTH)


func _process(delta: float) -> void:
	if loss_index >= 0:
		loss_elapsed += delta
		while loss_elapsed >= LOSS_FRAME_DURATION and loss_index >= 0:
			loss_elapsed -= LOSS_FRAME_DURATION
			loss_index += 1
			if loss_index >= loss_frames.size():
				loss_index = -1
				lost_effect.visible = false
			else:
				lost_effect.texture = loss_frames[loss_index]
	if displayed_health == 1 and loss_index < 0:
		critical_elapsed += delta
		if critical_index == 8:
			if critical_elapsed >= CRITICAL_PAUSE:
				critical_index = 0
				critical_elapsed = 0.0
				_refresh_frame()
		elif critical_elapsed >= CRITICAL_FRAME_DURATION:
			critical_elapsed = 0.0
			critical_index += 1
			if critical_index < 8:
				_refresh_frame()
	if log_remaining > 0.0:
		log_remaining = move_toward(log_remaining, 0.0, delta)
		if log_remaining <= 0.0:
			message_label.visible = false


func update_health(current_health: int) -> void:
	previous_health = displayed_health
	displayed_health = clampi(current_health, 0, MAX_HEALTH)
	health_value.text = "INTEGRIDAD  %d/%d" % [displayed_health, MAX_HEALTH]
	if displayed_health != 1:
		critical_index = 0
		critical_elapsed = 0.0
	_refresh_frame()


func on_damage_taken(current_health: int) -> void:
	if current_health != displayed_health or previous_health <= displayed_health:
		return
	loss_index = 0
	loss_elapsed = 0.0
	lost_effect.position = Vector2(float(previous_health - 1) * 55.0, -22.0)
	lost_effect.texture = loss_frames[0]
	lost_effect.visible = true
	critical_index = 0
	critical_elapsed = 0.0
	_refresh_frame()
	show_log("C.O.R.E.-9: Integridad al %d/3. La garantia sigue siendo decorativa." % displayed_health)


func update_dimension_theme(present: bool) -> void:
	is_present = present
	_refresh_frame()


func show_game_over_log() -> void:
	show_log("C.O.R.E.-9: Fin del turno. Otra vez.")


func show_log(message: String, duration: float = 2.0) -> void:
	message_label.text = message
	message_label.visible = true
	log_remaining = maxf(duration, 0.0)


func _refresh_frame() -> void:
	var dimension: String = "present" if is_present else "past"
	if displayed_health == 1 and critical_index < 8 and loss_index < 0:
		health_frame.texture = critical_frames[dimension][critical_index]
	else:
		health_frame.texture = static_frames[dimension][displayed_health]
