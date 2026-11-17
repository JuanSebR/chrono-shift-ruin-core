extends Control

const ASSETS: Script = preload("res://scripts/ending/final_assets.gd")
var elapsed: float = 0.0
var ready_to_return: bool = false
var returning: bool = false
var viewing_past: bool = false
@onready var stage: Control = $Stage
@onready var character: AnimatedSprite2D = $Stage/Character
@onready var return_button: TextureButton = $Stage/ReturnButton

func _ready() -> void:
	if not get_node("/root/GameProgress").core_guardian_defeated:
		set_process(false)
		hide()
		call_deferred("_reject_access")
		return
	get_node("/root/GameProgress").clear_room_arrival()
	get_viewport().size_changed.connect(_fit_stage)
	_fit_stage()
	character.sprite_frames = ASSETS.character()
	character.play(&"idle")
	$Stage/ThanksPrimary.texture = ASSETS.crop("thanks for playing End.png",Rect2(20,25,1740,840))
	$Stage/ThanksAlternate.texture = ASSETS.crop("thaks for playing 2 End.png",Rect2(40,170,1460,690))
	return_button.texture_normal = ASSETS.crop("return Bottom End.png",Rect2(205,65,1760,600))
	return_button.pressed.connect(_return_to_menu)
	return_button.mouse_entered.connect(_highlight.bind(true))
	return_button.mouse_exited.connect(_highlight.bind(false))
	return_button.focus_entered.connect(_highlight.bind(true))
	return_button.focus_exited.connect(_highlight.bind(false))

func _reject_access() -> void:
	get_tree().change_scene_to_file("res://scenes/Room5.tscn")

func _fit_stage() -> void:
	var viewport: Vector2 = get_viewport_rect().size
	var factor: float = minf(viewport.x/1280.0,viewport.y/720.0)
	stage.scale = Vector2.ONE*factor
	stage.position = (viewport-Vector2(1280,720)*factor)*0.5

func _process(delta: float) -> void:
	elapsed += delta
	if not ready_to_return:
		var past_alpha: float = clampf((elapsed-1.25)/0.75,0,1)*clampf((4.0-elapsed)/0.75,0,1)
		$Stage/Past.modulate.a = past_alpha
		$Stage/ThanksAlternate.modulate.a = clampf((elapsed-4.0)/0.5,0,1)*clampf((6.5-elapsed)/0.5,0,1)
		$Stage/ThanksPrimary.modulate.a = clampf((elapsed-6.0)/0.5,0,1)
		if elapsed >= 6.5:
			ready_to_return = true
			return_button.show()
			return_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if ready_to_return and event.is_action_pressed("dimension_shift"):
		viewing_past = not viewing_past
		$Stage/Past.modulate.a = 1.0 if viewing_past else 0.0
		get_viewport().set_input_as_handled()

func _highlight(active: bool) -> void:
	return_button.modulate = Color(0.75,1,1) if active or return_button.has_focus() else Color.WHITE

func _return_to_menu() -> void:
	if returning or not ready_to_return:
		return
	returning = true
	call_deferred("_change_to_menu")

func _change_to_menu() -> void:
	if get_tree().current_scene != self:
		return
	var error: Error = get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	if error != OK:
		returning = false
		push_error("C.O.R.E.-9: El menu no responde. El descanso tendra que esperar.")
