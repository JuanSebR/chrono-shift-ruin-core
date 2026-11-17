extends CanvasLayer

var active_id: String = ""
var anchor_world: Vector2 = Vector2.ZERO
var panel: PanelContainer
var label: Label

func _ready() -> void:
	layer = 8
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.09, 0.15, 0.89)
	style.border_color = Color(0.0, 0.94, 1.0, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", style)
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.78, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 17)
	panel.add_child(label)
	add_child(panel)
	panel.hide()

func show_hint(id: String, message: String, world_position: Vector2) -> void:
	if active_id != id:
		active_id = id
		label.text = message
		panel.show()
	anchor_world = world_position

func hide_hint() -> void:
	active_id = ""
	if panel != null:
		panel.hide()

func _process(_delta: float) -> void:
	if active_id == "" or panel == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_point: Vector2 = get_viewport().get_canvas_transform() * anchor_world
	panel.position = Vector2(clampf(screen_point.x - panel.size.x * 0.5, 8.0, maxf(8.0, viewport_size.x - panel.size.x - 8.0)), clampf(screen_point.y - panel.size.y, 8.0, maxf(8.0, viewport_size.y - panel.size.y - 8.0)))
