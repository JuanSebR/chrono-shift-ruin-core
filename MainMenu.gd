extends Control

const TUTORIAL_SCENE: String = "res://scenes/Room1_Tutorial.tscn"
const CONTINUE_TEXTURE: Texture2D = preload("res://assets/inicio/Continuar.png")

@onready var new_game_button: TextureButton = %NewGameButton
@onready var options_button: TextureButton = %OptionsButton
@onready var quit_button: TextureButton = %QuitButton
@onready var options_panel: ColorRect = %OptionsPanel
@onready var back_button: Button = %BackButton
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var volume_slider: HSlider = %VolumeSlider

var _transitioning: bool = false
var continue_button: TextureButton


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	for button: TextureButton in [new_game_button, options_button, quit_button]:
		button.mouse_entered.connect(_set_highlight.bind(button, true))
		button.mouse_exited.connect(_set_highlight.bind(button, false))
		button.focus_entered.connect(_set_highlight.bind(button, true))
		button.focus_exited.connect(_set_highlight.bind(button, false))
		button.button_down.connect(_set_pressed.bind(button, true))
		button.button_up.connect(_set_pressed.bind(button, false))
	options_panel.hide()
	fullscreen_check.set_pressed_no_signal(
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	var bus_index: int = AudioServer.get_bus_index(&"Master")
	var linear_volume: float = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	volume_slider.set_value_no_signal(clampf(linear_volume * 100.0, 0.0, 100.0))
	continue_button = TextureButton.new()
	continue_button.name = "ContinueProgress"
	continue_button.texture_normal = CONTINUE_TEXTURE
	continue_button.ignore_texture_size = true
	continue_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	continue_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	continue_button.custom_minimum_size = Vector2(300.0, 88.0)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.tooltip_text = "Continuar: la chatarra sigue esperando."
	var buttons: VBoxContainer = new_game_button.get_parent() as VBoxContainer
	buttons.add_child(continue_button)
	buttons.move_child(continue_button, 0)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.mouse_entered.connect(_set_highlight.bind(continue_button, true))
	continue_button.mouse_exited.connect(_set_highlight.bind(continue_button, false))
	continue_button.focus_entered.connect(_set_highlight.bind(continue_button, true))
	continue_button.focus_exited.connect(_set_highlight.bind(continue_button, false))
	continue_button.button_down.connect(_set_pressed.bind(continue_button, true))
	continue_button.button_up.connect(_set_pressed.bind(continue_button, false))
	var progress: Node = get_node("/root/GameProgress")
	continue_button.disabled = not bool(progress.call("load_progress")) or str(progress.call("get_continue_scene")).is_empty()
	if not continue_button.disabled:
		continue_button.grab_focus()
	else:
		continue_button.modulate = Color(0.4, 0.4, 0.4, 0.55)
		continue_button.tooltip_text = "Sin partida guardada. Hasta el disco necesita un comienzo."
		new_game_button.grab_focus()
	print("C.O.R.E.-9: Menu desplegado. Elige tu ruina con dignidad.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and options_panel.visible:
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _on_new_game_pressed() -> void:
	if _transitioning:
		return
	if not get_node("/root/GameProgress").call("new_game"):
		return
	_transitioning = true
	print("C.O.R.E.-9: Nueva partida solicitada. Otra ruina por explorar.")
	var error: Error = get_tree().change_scene_to_file(TUTORIAL_SCENE)
	if error != OK:
		_transitioning = false
		push_error("C.O.R.E.-9: No se pudo cargar la sala tutorial. El multiverso respira aliviado.")


func _on_options_pressed() -> void:
	options_panel.show()
	back_button.grab_focus()
	print("C.O.R.E.-9: Configuracion abierta. Ajusta el caos a tu gusto.")


func _on_back_pressed() -> void:
	options_panel.hide()
	options_button.grab_focus()
	print("C.O.R.E.-9: Configuracion cerrada. Ignorancia restaurada.")


func _on_quit_pressed() -> void:
	print("C.O.R.E.-9: Abandonando la ruina. No te culpo.")
	get_tree().quit()


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	var mode: DisplayServer.WindowMode = (
		DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_mode(mode)
	print("C.O.R.E.-9: Pantalla %s. Como si importara." % ("completa" if toggled_on else "ventana"))


func _on_volume_changed(value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(&"Master")
	var linear_volume: float = clampf(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		bus_index, linear_to_db(linear_volume) if linear_volume > 0.0 else -80.0)


func _set_highlight(button: TextureButton, active: bool) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	button.modulate = Color(1.18, 1.18, 1.25) if active else Color.WHITE
	button.scale = Vector2(1.03, 1.03) if active else Vector2.ONE


func _set_pressed(button: TextureButton, down: bool) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	button.modulate = Color(0.8, 0.8, 0.85) if down else Color.WHITE
	button.scale = Vector2(0.99, 0.99) if down else Vector2.ONE


func _on_continue_pressed() -> void:
	if _transitioning:
		return
	var progress: Node = get_node("/root/GameProgress")
	if not bool(progress.call("load_progress")):
		return
	var destination: String = str(progress.call("prepare_continue_arrival"))
	if destination.is_empty():
		return
	_transitioning = true
	var error: Error = get_tree().change_scene_to_file(destination)
	if error != OK:
		progress.call("clear_room_arrival")
		_transitioning = false
