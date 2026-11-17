extends CharacterBody2D

signal defeated
enum State { IDLE, PATROL, CHARGE, RECOVER, HURT, DEAD }
@export var max_health: int = 2
@export var patrol_speed: float = 45.0
@export var detection_range: float = 190.0
@export var charge_duration: float = 0.6
@export var recovery_duration: float = 0.9
@export var shot_interval: float = 1.8
@export var projectile_speed: float = 120.0
@export var projectile_lifetime: float = 3.0
@export var projectile_damage: int = 1
@export var patrol_left: float = 560.0
@export var patrol_right: float = 820.0
@export var engagement_min_x: float = 400.0
@export var projectile_scene: PackedScene
var health: int = 2
var state: State = State.IDLE
var state_remaining: float = 0.6
var shot_remaining: float = 0.0
var direction: float = -1.0
var active_projectile: Area2D
var player: CharacterBody2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("core9_player") as CharacterBody2D
	sprite.animation_finished.connect(_on_animation_finished)
	_set_state(State.IDLE, 0.6)

func _physics_process(delta: float) -> void:
	shot_remaining = maxf(0.0, shot_remaining - delta)
	state_remaining = maxf(0.0, state_remaining - delta)
	if state == State.DEAD:
		return
	velocity.x = 0.0
	if not is_on_floor():
		velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity")) * delta
	match state:
		State.IDLE:
			if state_remaining <= 0.0:
				_set_state(State.PATROL)
		State.PATROL:
			if _can_see_player() and shot_remaining <= 0.0 and not is_instance_valid(active_projectile):
				direction = -1.0 if player.global_position.x < global_position.x else 1.0
				_set_state(State.CHARGE, charge_duration)
			else:
				_patrol(delta)
		State.CHARGE:
			if not _can_see_player():
				_set_state(State.RECOVER, recovery_duration)
			elif state_remaining <= 0.0:
				_fire()
				_set_state(State.RECOVER, recovery_duration)
		State.RECOVER, State.HURT:
			if state_remaining <= 0.0:
				_set_state(State.PATROL)
	sprite.flip_h = direction < 0.0
	move_and_slide()

func _patrol(delta: float) -> void:
	var next_x: float = global_position.x + direction * patrol_speed * delta
	var edge: Vector2 = global_position + Vector2(direction * 24.0, 0.0)
	var floor_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(edge, edge + Vector2(0.0, 40.0), 1)
	var wall_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(direction * 26.0, 0.0), 1)
	if next_x < patrol_left or next_x > patrol_right or get_world_2d().direct_space_state.intersect_ray(floor_query).is_empty() or not get_world_2d().direct_space_state.intersect_ray(wall_query).is_empty():
		direction *= -1.0
		return
	velocity.x = direction * patrol_speed

func _can_see_player() -> bool:
	if not is_instance_valid(player) or int(player.get("health")) <= 0 or player.global_position.x < engagement_min_x:
		return false
	if global_position.distance_to(player.global_position) > detection_range:
		return false
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0.0, -4.0), player.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _fire() -> void:
	if projectile_scene == null or is_instance_valid(active_projectile):
		return
	active_projectile = projectile_scene.instantiate() as Area2D
	active_projectile.set("direction", direction)
	active_projectile.set("speed", projectile_speed)
	active_projectile.set("lifetime", projectile_lifetime)
	active_projectile.set("damage", projectile_damage)
	get_parent().add_child(active_projectile)
	active_projectile.global_position = global_position + Vector2(direction * 25.0, -4.0)
	shot_remaining = shot_interval

func take_damage(amount: int) -> void:
	if amount <= 0 or state == State.DEAD:
		return
	health = maxi(0, health - amount)
	if health == 0:
		_set_state(State.DEAD)
		$Hurtbox.set_deferred("monitorable", false)
		if is_instance_valid(active_projectile):
			active_projectile.call("consume")
		defeated.emit()
	else:
		_set_state(State.HURT, 0.35)

func _set_state(next: State, duration: float = 0.0) -> void:
	state = next
	state_remaining = duration
	match state:
		State.PATROL:
			sprite.scale = Vector2.ONE * 0.20
			sprite.play(&"walking")
		State.CHARGE, State.RECOVER:
			sprite.scale = Vector2.ONE * 0.22
			sprite.play(&"attacking")
			if state == State.CHARGE:
				sprite.set_frame_and_progress(0, 0.0)
		State.HURT:
			sprite.scale = Vector2.ONE * 0.13
			sprite.play(&"damaged")
			sprite.set_frame_and_progress(0, 0.0)
		State.DEAD:
			sprite.scale = Vector2.ONE * 0.24
			sprite.play(&"ka-boom")
		_:
			sprite.scale = Vector2.ONE * 0.20
			sprite.play(&"walking")
			sprite.pause()
			sprite.frame = 0

	sprite.position = Vector2(0.0, 20.0 - 250.0 * sprite.scale.y)

func _on_animation_finished() -> void:
	if state == State.DEAD:
		queue_free()
