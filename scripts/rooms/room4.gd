extends "res://scripts/rooms/room2.gd"

signal fall_recovered

# The lowest support starts at Y=462. Recover before the head and feet
# disappear through the bottom of the 720 px world.
const VOID_FEET_Y: float = 680.0

@onready var checkpoint: Marker2D = $EntryMarkers/Spawn
@onready var central_checkpoint: Marker2D = $EntryMarkers/CentralCheckpoint
@onready var central_rest: StaticBody2D = $WorldCollision/SharedCollision/CentralRest
@onready var collider: CollisionShape2D = $Player/CollisionShape2D
@onready var camera: Camera2D = $Player/Camera2D
@onready var sprite: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var dimension_manager: Node = $DimensionManager

var recovering: bool = false
var previous_position: Vector2
var continuous_route: bool = true
var reached_last_approach: bool = false
var key_notice_remaining: float = 0.0
var key_retry_remaining: float = 0.0


func _ready() -> void:
	continuous_route = get_node("/root/GameProgress").get("arrival_marker") != &"EntryMarkers/FromRoom5"
	super._ready()
	sprite.flip_h = false
	previous_position = player.position


func _physics_process(_delta: float) -> void:
	_update_reactor_access(_delta)
	if recovering or player.health <= 0:
		return
	var half_height: float = (collider.shape as RectangleShape2D).size.y * 0.5
	if collider.global_position.y + half_height >= VOID_FEET_Y:
		_recover()
		return
	if checkpoint == central_checkpoint or not player.is_on_floor():
		return
	for index: int in range(player.get_slide_collision_count()):
		var contact: KinematicCollision2D = player.get_slide_collision(index)
		if contact.get_collider() == central_rest and contact.get_normal().y < -0.9:
			checkpoint = central_checkpoint
			return


func _recover() -> void:
	recovering = true
	player.global_position = checkpoint.global_position
	player.velocity = Vector2.ZERO
	previous_position = player.position
	continuous_route = true
	reached_last_approach = false
	sprite.flip_h = false
	dimension_manager.restore_present_at_checkpoint()
	camera.reset_smoothing()
	camera.force_update_scroll()
	fall_recovered.emit()
	recovering = false


func _update_reactor_access(delta: float) -> void:
	var progress: Node = get_node("/root/GameProgress")
	if player.position.distance_to(previous_position) > 40.0:
		continuous_route = false
	previous_position = player.position
	key_retry_remaining = maxf(0.0, key_retry_remaining - delta)
	key_notice_remaining = maxf(0.0, key_notice_remaining - delta)
	if key_notice_remaining == 0.0:
		$ReactorNotice.call("hide_hint")
		$TemporalTutorial.set_physics_process(true)
	if continuous_route and player.is_on_floor() and player.health > 0 and progress.get("has_temporal_lens"):
		for index: int in range(player.get_slide_collision_count()):
			var contact: KinematicCollision2D = player.get_slide_collision(index)
			if contact.get_normal().y > -0.9:
				continue
			if contact.get_collider() == $WorldCollision/PastCollision/PastRight:
				reached_last_approach = true
			if contact.get_collider() == $WorldCollision/SharedCollision/ExitLedge and reached_last_approach and not progress.get("has_reactor_key") and key_retry_remaining == 0.0:
				key_retry_remaining = 1.0
				if progress.call("acquire_reactor_key"):
					$TutorialHints.call("hide_hint")
					$TemporalTutorial.set_physics_process(false)
					$ReactorNotice.call("show_hint", "reactor_key", "LLAVE DEL REACTOR OBTENIDA", Vector2(1100, 170))
					key_notice_remaining = 2.5
	$RoomTransitions/ToRoom5.set_deferred("monitoring", bool(progress.get("has_reactor_key")))
