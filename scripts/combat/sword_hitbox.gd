extends Area2D

@export var active_duration: float = 0.10
@export var damage: int = 1
var remaining: float = 0.0
var facing: float = 1.0
var hit_targets: Array[int] = []
@onready var collision: CollisionShape2D = $CollisionShape2D

func begin_attack(facing_left: bool) -> void:
	var progress: Node = get_node_or_null("/root/GameProgress")
	if progress == null or not progress.get("has_cronal_sword"):
		return
	position = Vector2(-28.0 if facing_left else 28.0, -4.0)
	facing = -1.0 if facing_left else 1.0
	remaining = active_duration
	hit_targets.clear()

func _physics_process(delta: float) -> void:
	if remaining <= 0.0 or int(get_parent().get("health")) <= 0:
		remaining = 0.0
		return
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = 8
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var area: Area2D = result["collider"] as Area2D
		if area == null or not area.is_in_group("enemy_hurtbox"):
			continue
		var target: Node = area.get_parent()
		var target_id: int = target.get_instance_id()
		if not hit_targets.has(target_id) and target.has_method("take_damage"):
			hit_targets.append(target_id)
			target.call("take_damage", damage)
	remaining = maxf(0.0, remaining - delta)


func cancel_attack() -> void:
	remaining = 0.0
	hit_targets.clear()
