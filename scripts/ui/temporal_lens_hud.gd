extends Control

enum DisplayState {
	HIDDEN,
	OWNED_NEUTRAL,
}

@onready var lens_icon: TextureRect = $LensIcon
@onready var status: Label = $Status

const MANAGER_SCRIPT: Script = preload("res://DimensionManager.gd")
const PRESENT_ICON: Texture2D = preload("res://assets/ui/hud/temporal_lens/ready_present.png")
const PAST_ICON: Texture2D = preload("res://assets/ui/hud/temporal_lens/ready_past.png")
const RECHARGE: Texture2D = preload("res://assets/ui/hud/temporal_lens/recharge_atlas.png")
const PROTECTION_DURATION: float = 0.16
var protection_frames: Array[Texture2D] = [
	preload("res://assets/ui/hud/temporal_lens/protection_00.png"),
	preload("res://assets/ui/hud/temporal_lens/protection_01.png"),
	preload("res://assets/ui/hud/temporal_lens/protection_02.png"),
	preload("res://assets/ui/hud/temporal_lens/protection_03.png"),
	preload("res://assets/ui/hud/temporal_lens/protection_04.png"),
]
var manager: Node
var recharge_frame: int = -1
var protection_frame: int = -1
var frames: Array[AtlasTexture] = []
var rejection_tween: Tween

var display_state: DisplayState = DisplayState.HIDDEN
var reveal_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var progress: Node = get_node("/root/GameProgress")
	if not progress.temporal_lens_acquired.is_connected(_on_temporal_lens_acquired):
		progress.temporal_lens_acquired.connect(_on_temporal_lens_acquired)
	sync_from_progress()
	set_process(false)
	_bind_manager()


func _bind_manager() -> void:
	var ancestor: Node = get_parent()
	while ancestor != null and ancestor != get_tree().root:
		for candidate: Node in ancestor.get_children():
			if candidate.get_script() == MANAGER_SCRIPT and candidate.controlled_player != null:
				manager = candidate
				for index: int in range(6):
					var frame: AtlasTexture = AtlasTexture.new()
					frame.atlas = RECHARGE
					frame.region = Rect2(index * 384, 0, 384, 384)
					frame.filter_clip = true
					frames.append(frame)
				manager.dimension_changed.connect(_on_dimension_changed)
				manager.dimension_change_rejected.connect(_on_change_rejected)
				manager.controlled_player.temporal_protection_started.connect(_on_protection_changed)
				manager.controlled_player.temporal_protection_ended.connect(_on_protection_changed)
				_refresh_dimension()
				return
		ancestor = ancestor.get_parent()


func _process(_delta: float) -> void:
	_refresh_dimension()


func _refresh_dimension() -> void:
	set_process(false)
	protection_frame = -1
	if not visible or not is_instance_valid(manager):
		return
	var present: bool = manager.active_dimension == 0
	var dimension_label: String = "PRESENTE" if present else "PASADO"
	var remaining: float = manager.switch_cooldown_remaining
	if remaining > 0.0:
		var fraction: float = clampf(1.0 - remaining / manager.SWITCH_COOLDOWN, 0.0, 1.0)
		recharge_frame = mini(int(fraction * frames.size()), frames.size() - 1)
		lens_icon.texture = frames[recharge_frame]
		status.text = dimension_label + (" · CAMBIO" if recharge_frame == 0 else " · RECARGA")
		set_process(true)
	else:
		recharge_frame = -1
		lens_icon.texture = PRESENT_ICON if present else PAST_ICON
		status.text = dimension_label
	var player: CharacterBody2D = manager.controlled_player
	if is_instance_valid(player) and bool(player.call("is_temporally_protected")):
		var progress: float = clampf(1.0 - float(player.call("get_temporal_protection_remaining")) / PROTECTION_DURATION, 0.0, 1.0)
		protection_frame = mini(int(progress * protection_frames.size()), protection_frames.size() - 1)
		lens_icon.texture = protection_frames[protection_frame]
		set_process(true)


func _on_protection_changed(_duration: float = 0.0) -> void:
	_refresh_dimension()


func _on_dimension_changed(_present: bool) -> void:
	if rejection_tween != null:
		rejection_tween.kill()
	_refresh_dimension()


func _on_change_rejected() -> void:
	if not visible:
		return
	if rejection_tween != null:
		rejection_tween.kill()
	status.text = "PRESENTE" if manager.active_dimension == 0 else "PASADO"
	status.text += "\nCAMBIO BLOQUEADO"
	rejection_tween = create_tween()
	rejection_tween.tween_interval(0.65)
	rejection_tween.tween_callback(_refresh_dimension)


func _exit_tree() -> void:
	var progress: Node = get_node_or_null("/root/GameProgress")
	if progress != null and progress.temporal_lens_acquired.is_connected(_on_temporal_lens_acquired):
		progress.temporal_lens_acquired.disconnect(_on_temporal_lens_acquired)


func sync_from_progress() -> void:
	var progress: Node = get_node("/root/GameProgress")
	set_display_state(DisplayState.OWNED_NEUTRAL if bool(progress.get("has_temporal_lens")) else DisplayState.HIDDEN)
	_refresh_dimension()


func set_display_state(new_state: DisplayState) -> void:
	display_state = new_state
	visible = display_state != DisplayState.HIDDEN


func _on_temporal_lens_acquired() -> void:
	sync_from_progress()
	_play_acquisition_reveal()


func _play_acquisition_reveal() -> void:
	if reveal_tween != null and reveal_tween.is_valid():
		reveal_tween.kill()
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	reveal_tween = create_tween().set_parallel(true)
	reveal_tween.tween_property(self, "modulate:a", 1.0, 0.22)
	reveal_tween.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
