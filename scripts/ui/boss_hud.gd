extends CanvasLayer

const CELL_SIZE: Vector2 = Vector2(320,128)
const ZERO_HOLD: float = 0.08
const DESTRUCTION_FRAME_TIME: float = 0.12
const LOSS_ACCENT_TIME: float = 0.12
const ENERGY_WINDOWS: Array[Rect2] = [Rect2(58,52,70,28),Rect2(129,52,64,28),Rect2(193,52,67,28)]

var guardian: Node2D
var health_frames: Array[AtlasTexture] = []
var destruction_frames: Array[AtlasTexture] = []
var health_events: int = 0
var destruction_plays: int = 0
var destruction_started: bool = false
var destruction_completed: bool = false
var destruction_elapsed: float = 0.0
var destruction_index: int = -1
var loss_accent_remaining: float = 0.0

@onready var anchor: Control = $Anchor
@onready var health_art: Control = $Anchor/HealthArt
@onready var boss_name: Label = $Anchor/BossName
@onready var phase_indicator: Label = $Anchor/PhaseIndicator
@onready var health_value: Label = $Anchor/HealthValue


func _ready() -> void:
	var directory: String = "res://assets/sprites/jefe/derived/atlases/"
	var health_atlas: Texture2D = load(directory + "hud_health_atlas.png") as Texture2D
	var defeated_atlas: Texture2D = load(directory + "hud_defeated_atlas.png") as Texture2D
	for index: int in range(4):
		health_frames.append(_frame(health_atlas,index))
	for index: int in range(5):
		destruction_frames.append(_frame(defeated_atlas,index))
	health_art.draw.connect(_draw_health)
	get_viewport().size_changed.connect(_layout)
	_layout()
	anchor.hide()


func _frame(atlas: Texture2D, index: int) -> AtlasTexture:
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(Vector2(index * 320,0),CELL_SIZE)
	texture.filter_clip = true
	return texture


func _layout() -> void:
	anchor.position = (get_viewport().get_visible_rect().size - Vector2(320,92)).round()


func bind_guardian(target: Node2D) -> void:
	if guardian == target:
		_sync()
		return
	_disconnect_guardian()
	guardian = target
	destruction_started = false
	destruction_completed = false
	destruction_elapsed = 0.0
	destruction_index = -1
	if not is_instance_valid(guardian):
		anchor.hide()
		return
	guardian.connect("health_changed",_on_health_changed)
	guardian.connect("state_changed",_on_state_changed)
	guardian.connect("defeated",_on_defeated)
	guardian.connect("tree_exiting",_on_guardian_exit)
	# Binding an already defeated actor must not manufacture another defeat event.
	if int(guardian.get("health")) <= 0:
		destruction_started = true
		destruction_completed = true
	_sync()


func _disconnect_guardian() -> void:
	if is_instance_valid(guardian):
		var connections: Dictionary = {"health_changed":_on_health_changed,"state_changed":_on_state_changed,"defeated":_on_defeated,"tree_exiting":_on_guardian_exit}
		for name: String in connections:
			var callback: Callable = connections[name]
			if guardian.is_connected(name,callback):
				guardian.disconnect(name,callback)
	guardian = null


func _on_guardian_exit() -> void:
	_disconnect_guardian()
	anchor.hide()


func _exit_tree() -> void:
	_disconnect_guardian()


func health_fraction() -> float:
	if not is_instance_valid(guardian):
		return 0.0
	return clampf(float(guardian.get("health")) / maxf(1.0,float(guardian.get("max_health"))),0.0,1.0)


func segment_fraction(index: int) -> float:
	return clampf(health_fraction() * 3.0 - float(index),0.0,1.0)


func _on_health_changed(_current: int, _maximum: int) -> void:
	health_events += 1
	loss_accent_remaining = LOSS_ACCENT_TIME
	_sync()


func _on_state_changed(_state: int) -> void:
	_sync()


func _sync() -> void:
	if not is_instance_valid(guardian):
		anchor.hide()
		return
	health_value.text = "%d/%d" % [int(guardian.get("health")),int(guardian.get("max_health"))]
	phase_indicator.text = "VULNERABLE" if guardian.state == guardian.State.VULNERABLE else "OFENSIVA"
	if destruction_started:
		anchor.visible = not destruction_completed
	else:
		anchor.visible = bool(guardian.get("cycle_running")) and int(guardian.get("health")) > 0
	health_art.queue_redraw()


func _on_defeated() -> void:
	if destruction_started or not is_instance_valid(guardian) or int(guardian.get("health")) != 0 or int(guardian.get("state")) != guardian.State.DEFEATED:
		return
	destruction_started = true
	destruction_completed = false
	destruction_plays += 1
	destruction_elapsed = 0.0
	destruction_index = -1
	health_value.text = "0/%d" % int(guardian.get("max_health"))
	anchor.show()
	health_art.queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(guardian):
		anchor.hide()
		return
	loss_accent_remaining = maxf(0.0,loss_accent_remaining-delta)
	health_value.modulate = Color(1,0.78,0.45) if loss_accent_remaining > 0.0 else Color.WHITE
	if destruction_started and not destruction_completed:
		destruction_elapsed += delta
		if destruction_elapsed >= ZERO_HOLD:
			destruction_index = mini(4,int((destruction_elapsed-ZERO_HOLD)/DESTRUCTION_FRAME_TIME))
		if destruction_elapsed >= ZERO_HOLD + destruction_frames.size()*DESTRUCTION_FRAME_TIME:
			destruction_completed = true
			anchor.hide()
		health_art.queue_redraw()


func _draw_health() -> void:
	if not is_instance_valid(guardian) or health_frames.size() != 4:
		return
	if destruction_started and destruction_index >= 0:
		health_art.draw_texture(destruction_frames[destruction_index],Vector2.ZERO)
		return
	# Keep the original empty casing and shadows. Only the three energy interiors
	# reveal proportional regions of the original full image; no replacement art.
	health_art.draw_texture(health_frames[3],Vector2.ZERO)
	for index: int in range(3):
		var fraction: float = segment_fraction(index)
		if fraction <= 0.0:
			continue
		var region: Rect2 = ENERGY_WINDOWS[index]
		region.size.x = floorf(region.size.x * fraction)
		if region.size.x > 0.0:
			health_art.draw_texture_rect_region(health_frames[0],region,region)
