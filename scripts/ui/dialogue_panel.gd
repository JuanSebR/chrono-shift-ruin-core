extends CanvasLayer

signal conversation_started(id: String)
signal conversation_finished(id: String)

var active_id: String = ""
var lines: Array[Dictionary] = []
var current_line: int = 0
var completed_unique: Dictionary = {}
var active_once: bool = true
var ambient_mode: bool = false
var ambient_remaining: float = 0.0
var controlled_player: CharacterBody2D
var root_control: Control
var portrait: TextureRect
var frame: TextureRect
var message: RichTextLabel
var advance_indicator: HBoxContainer
var advance_key: Label
var advance_action: Label

func _ready() -> void:
	layer = 20
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(portrait)
	frame = TextureRect.new()
	frame.texture = load("res://assets/sprites/Dialogos/dialog box.png") as Texture2D
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(frame)
	message = RichTextLabel.new()
	message.bbcode_enabled = false
	message.fit_content = false
	message.scroll_active = false
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message.add_theme_font_size_override("normal_font_size", 21)
	message.add_theme_color_override("default_color", Color(0.9, 1.0, 1.0))
	root_control.add_child(message)
	advance_indicator = HBoxContainer.new()
	advance_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advance_indicator.add_theme_constant_override("separation", 8)
	root_control.add_child(advance_indicator)
	var key_panel: PanelContainer = PanelContainer.new()
	key_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key_style: StyleBoxFlat = StyleBoxFlat.new()
	key_style.bg_color = Color(0.02, 0.22, 0.30, 0.92)
	key_style.border_color = Color(0.0, 0.94, 1.0, 0.95)
	key_style.set_border_width_all(1)
	key_style.set_corner_radius_all(4)
	key_style.set_content_margin_all(4.0)
	key_panel.add_theme_stylebox_override("panel", key_style)
	advance_indicator.add_child(key_panel)
	advance_key = Label.new()
	advance_key.text = "E"
	advance_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advance_key.add_theme_color_override("font_color", Color(0.8, 1.0, 1.0))
	key_panel.add_child(advance_key)
	advance_action = Label.new()
	advance_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advance_action.add_theme_color_override("font_color", Color(0.75, 0.98, 1.0))
	advance_indicator.add_child(advance_action)
	get_viewport().size_changed.connect(_layout)
	_layout()
	root_control.hide()

func _layout() -> void:
	if root_control == null:
		return
	var size: Vector2 = get_viewport().get_visible_rect().size
	var scale_factor: float = minf(size.x / 1024.0, size.y / 572.0)
	var left: float = (size.x - 1024.0 * scale_factor) * 0.5
	var bottom: float = size.y - 12.0 * scale_factor
	if ambient_mode:
		advance_indicator.hide()
		portrait.position = Vector2(left + 25.0 * scale_factor, bottom - 150.0 * scale_factor)
		portrait.size = Vector2(145.0, 140.0) * scale_factor
		frame.position = Vector2(left + 172.0 * scale_factor, bottom - 205.0 * scale_factor)
		frame.size = Vector2(630.0, 205.0) * scale_factor
		message.position = frame.position + Vector2(80.0, 67.0) * scale_factor
		message.size = frame.size - Vector2(135.0, 110.0) * scale_factor
		message.add_theme_font_size_override("normal_font_size", maxi(12, roundi(18.0 * scale_factor)))
		return
	portrait.position = Vector2(left + 12.0 * scale_factor, bottom - 204.0 * scale_factor)
	portrait.size = Vector2(210.0, 200.0) * scale_factor
	frame.position = Vector2(left + 222.0 * scale_factor, bottom - 240.0 * scale_factor)
	frame.size = Vector2(782.0, 240.0) * scale_factor
	message.position = frame.position + Vector2(95.0, 72.0) * scale_factor
	message.size = frame.size - Vector2(150.0, 175.0) * scale_factor
	message.add_theme_font_size_override("normal_font_size", maxi(12, roundi(21.0 * scale_factor)))
	advance_indicator.position = frame.position + Vector2(578.0, 140.0) * scale_factor
	advance_indicator.scale = Vector2.ONE * scale_factor

func start_conversation(id: String, content: Array[Dictionary], player: CharacterBody2D, once: bool = true, ambient: bool = false, duration: float = 0.0) -> bool:
	var progress: Node = get_node_or_null("/root/GameProgress")
	if active_id != "" or content.is_empty() or (progress != null and str(progress.get("active_dialogue_id")) != "") or (once and (completed_unique.has(id) or (progress != null and bool(progress.call("dialogue_completed", id))))):
		return false
	active_id = id
	if progress != null:
		progress.set("active_dialogue_id", id)
	active_once = once
	ambient_mode = ambient
	ambient_remaining = duration
	_layout()
	lines = content.duplicate(true)
	current_line = 0
	controlled_player = player
	if controlled_player != null and not ambient_mode:
		controlled_player.set("dialogue_controls_locked", true)
		controlled_player.velocity.x = 0.0
	root_control.show()
	_show_line()
	conversation_started.emit(id)
	return true

func _show_line() -> void:
	var data: Dictionary = lines[current_line]
	message.text = str(data.get("text", ""))
	if ambient_mode:
		advance_indicator.hide()
	else:
		advance_action.text = "CERRAR" if current_line == lines.size() - 1 else "CONTINUAR"
		advance_indicator.show()
	var expression: String = str(data.get("expression", "core9_expression_1_01"))
	var path: String = "res://assets/sprites/Dialogos/derived/%s.png" % expression
	portrait.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null

func advance() -> void:
	if active_id == "":
		return
	current_line += 1
	if current_line < lines.size():
		_show_line()
	else:
		finish()

func finish() -> void:
	if active_id == "":
		return
	var finished_id: String = active_id
	active_id = ""
	var progress: Node = get_node_or_null("/root/GameProgress")
	if progress != null:
		progress.set("active_dialogue_id", "")
	if active_once:
		completed_unique[finished_id] = true
		if progress != null:
			progress.call("complete_dialogue", finished_id)
	if is_instance_valid(controlled_player):
		controlled_player.set("dialogue_controls_locked", false)
	controlled_player = null
	root_control.hide()
	advance_indicator.hide()
	conversation_finished.emit(finished_id)

func _unhandled_input(event: InputEvent) -> void:
	if active_id != "" and not ambient_mode and event.is_action_pressed(&"dialogue_advance") and not event.is_echo():
		advance()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if active_id != "" and ambient_mode:
		ambient_remaining -= delta
		if ambient_remaining <= 0.0:
			finish()

func _exit_tree() -> void:
	var progress: Node = get_node_or_null("/root/GameProgress")
	if progress != null and str(progress.get("active_dialogue_id")) == active_id:
		progress.set("active_dialogue_id", "")
	if is_instance_valid(controlled_player):
		controlled_player.set("dialogue_controls_locked", false)
