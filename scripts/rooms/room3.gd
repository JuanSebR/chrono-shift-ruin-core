extends "res://scripts/rooms/room2.gd"

const ART_ROOT: String = "res://assets/tiles/sala 3/derived/"
const PICKUP_FRAMES: int = 12
const MODULE_FRAMES: int = 6
const DISAPPEAR_FRAMES: int = 6

@onready var module_visual: AnimatedSprite2D = $TemporalModule/ModuleVisual
@onready var interaction_area: Area2D = $TemporalModule/InteractionArea
@onready var prompt: Label = $TemporalModule/InteractionPrompt
@onready var return_area: Area2D = $RoomTransitions/ToRoom2_2
@onready var forward_area: Area2D = $RoomTransitions/ToRoom4
@onready var player_visual: AnimatedSprite2D = $Player/AnimatedSprite2D

var acquisition_running: bool = false


func _ready() -> void:
	var progress: Node = get_node("/root/GameProgress")
	var returning_from_room4: bool = progress.arrival_scene == scene_file_path and progress.arrival_marker == &"EntryMarkers/FromRoom4"
	super._ready()
	player_visual.flip_h = returning_from_room4
	forward_area.monitoring = progress.has_temporal_lens
	_prepare_module_animation()
	_prepare_player_animation()
	if bool(get_node("/root/GameProgress").get("has_temporal_lens")):
		module_visual.hide()
	else:
		module_visual.play(&"levitation")
	prompt.hide()


func _process(_delta: float) -> void:
	prompt.visible = not acquisition_running and module_visual.visible and player.health > 0 and interaction_area.get_overlapping_bodies().has(player) and player.is_on_floor()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("dialogue_advance") or event.is_echo() or not prompt.visible:
		return
	get_viewport().set_input_as_handled()
	_begin_acquisition()


func _prepare_module_animation() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation(&"levitation")
	frames.set_animation_speed(&"levitation", 6.0)
	frames.set_animation_loop(&"levitation", true)
	for index: int in range(1, MODULE_FRAMES + 1):
		frames.add_frame(&"levitation", load(ART_ROOT + "module_levitation/%02d.png" % index) as Texture2D)
	frames.add_animation(&"disappear")
	frames.set_animation_speed(&"disappear", 8.0)
	frames.set_animation_loop(&"disappear", false)
	for index: int in range(1, DISAPPEAR_FRAMES):
		frames.add_frame(&"disappear", load(ART_ROOT + "module_disappearance_v2/%02d.png" % index) as Texture2D)
	frames.add_frame(&"disappear", load(ART_ROOT + "module_disappearance_v2/06_empty.png") as Texture2D)
	module_visual.sprite_frames = frames


func _prepare_player_animation() -> void:
	var frames: SpriteFrames = player_visual.sprite_frames.duplicate(true) as SpriteFrames
	frames.add_animation(&"module_pickup")
	frames.set_animation_speed(&"module_pickup", 12.0)
	frames.set_animation_loop(&"module_pickup", false)
	for index: int in range(1, PICKUP_FRAMES + 1):
		frames.add_frame(&"module_pickup", load(ART_ROOT + "pickup_interacting/%02d.png" % index) as Texture2D)
	player_visual.sprite_frames = frames
	player_visual.play(&"idle")


func _begin_acquisition() -> void:
	if acquisition_running or not module_visual.visible or player.health <= 0:
		return
	acquisition_running = true
	prompt.hide()
	return_area.monitoring = false
	player.dialogue_controls_locked = true
	player.velocity = Vector2.ZERO
	player.presentation = &"module_pickup"
	player_visual.flip_h = false
	player_visual.play(&"module_pickup")
	player_visual.set_frame_and_progress(0, 0.0)
	await get_tree().create_timer(0.25).timeout
	module_visual.play(&"disappear")
	await player_visual.animation_finished
	var progress: Node = get_node("/root/GameProgress")
	if bool(progress.call("acquire_temporal_lens")):
		module_visual.hide()
		hud.call("show_log", "C.O.R.E.-9: Lente Temporal adquirida. Por fin, otra responsabilidad.", 3.0)
	else:
		module_visual.show()
		module_visual.play(&"levitation")
	player.presentation = &""
	player.dialogue_controls_locked = false
	return_area.monitoring = true
	acquisition_running = false
	forward_area.monitoring = progress.has_temporal_lens
