extends CanvasLayer

const MAX_HEALTH: int = 3
const DIMENSION_COOLDOWN: float = 0.2
const PRESENT_COLOR: Color = Color(0.0, 0.941176, 1.0)
const PAST_COLOR: Color = Color(1.0, 0.0, 0.333333)
const DEFAULT_LOG_DURATION: float = 2.0
const GAME_OVER_LOG: String = "C.O.R.E.-9: Fin del turno. Otra vez."
const DAMAGE_LOG: String = "C.O.R.E.-9: Integridad al 66%. Podría ser peor, supongo."

@export var health_cells: Array[CanvasItem]
@export var temporal_lens_icon: CanvasItem
@export var temporal_lens_cooldown: Range
@export var log_label: Label

var displayed_health: int = MAX_HEALTH
var lens_cooldown_remaining: float = 0.0
var log_time_remaining: float = 0.0


func _ready() -> void:
	update_health(MAX_HEALTH)
	update_dimension_theme(true)
	_update_lens_indicator()
	if log_label != null:
		log_label.visible = false


func _process(delta: float) -> void:
	_update_lens_cooldown(delta)
	_update_log_visibility(delta)


func update_health(current_health: int) -> void:
	var clamped_health: int = clampi(current_health, 0, MAX_HEALTH)
	displayed_health = clamped_health
	for index: int in health_cells.size():
		var cell: CanvasItem = health_cells[index]
		if cell != null:
			cell.visible = index < clamped_health


func update_dimension_theme(is_present: bool) -> void:
	var theme_color: Color = PRESENT_COLOR if is_present else PAST_COLOR
	for cell: CanvasItem in health_cells:
		if cell != null:
			cell.modulate = theme_color
	if temporal_lens_icon != null:
		temporal_lens_icon.modulate = theme_color
	if temporal_lens_cooldown != null:
		temporal_lens_cooldown.modulate = theme_color
	if log_label != null:
		log_label.modulate = theme_color


func start_temporal_lens_cooldown() -> void:
	lens_cooldown_remaining = DIMENSION_COOLDOWN
	_update_lens_indicator()


func show_log(message: String, duration: float = DEFAULT_LOG_DURATION) -> void:
	if log_label == null:
		return
	log_label.text = message
	log_label.visible = true
	log_time_remaining = maxf(duration, 0.0)


func show_damage_log() -> void:
	show_log("C.O.R.E.-9: Integridad al %d%%. La garantia no cubre esto." % roundi(100.0 * displayed_health / MAX_HEALTH))


func show_game_over_log() -> void:
	show_log(GAME_OVER_LOG)


func _update_lens_cooldown(delta: float) -> void:
	if lens_cooldown_remaining <= 0.0:
		return
	lens_cooldown_remaining = move_toward(lens_cooldown_remaining, 0.0, delta)
	_update_lens_indicator()


func _update_lens_indicator() -> void:
	var recharge_ratio: float = 1.0 - (lens_cooldown_remaining / DIMENSION_COOLDOWN)
	if temporal_lens_cooldown != null:
		temporal_lens_cooldown.value = recharge_ratio * temporal_lens_cooldown.max_value
	if temporal_lens_icon != null:
		temporal_lens_icon.modulate.a = 0.3 + (recharge_ratio * 0.7)


func _update_log_visibility(delta: float) -> void:
	if log_time_remaining <= 0.0:
		return
	log_time_remaining = move_toward(log_time_remaining, 0.0, delta)
	if log_time_remaining <= 0.0 and log_label != null:
		log_label.visible = false
