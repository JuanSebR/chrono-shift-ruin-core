extends Area2D

@export var speed: float = 120.0
@export var lifetime: float = 3.0
@export var damage: int = 1
var direction: float = -1.0
var consumed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Sprite2D.flip_h = direction < 0.0
	$Sprite2D.position = Vector2(-direction * 5.4, -1.12)

func _physics_process(delta: float) -> void:
	if consumed:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		consume()
		return
	var destination: Vector2 = global_position + Vector2(direction * speed * delta, 0.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, destination, 3)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_on_body_entered(hit["collider"] as Node2D)
		return
	global_position = destination

func _on_body_entered(body: Node2D) -> void:
	if consumed or body == null:
		return
	if body.is_in_group("core9_player"):
		body.call("take_damage", damage)
	consume()

func consume() -> void:
	if consumed:
		return
	consumed = true
	queue_free()
