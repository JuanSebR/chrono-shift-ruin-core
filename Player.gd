extends CharacterBody2D

signal energy_slash_used
signal health_changed(current_health: int)
signal damage_taken(current_health: int)
signal defeat_animation_finished
signal defeated
signal temporal_protection_started(duration: float)
signal temporal_protection_ended

const SPEED: float = 240.0
const ACCELERATION: float = 1_600.0
const FRICTION: float = 2_000.0
const BASE_JUMP_VELOCITY: float = 420.0
const GRAVITY_MULTIPLIER: float = 1.5
const FALL_GRAVITY_MULTIPLIER: float = 1.5
const MAX_HEALTH: int = 3
const INVULNERABILITY_FRAMES: int = 60
const TEMPORAL_PROTECTION_DURATION: float = 0.16
const ATTACK_COOLDOWN: float = 0.35
const DROP_THROUGH_DURATION: float = 0.20

var presentation: StringName = &""
var pickup_target: Area2D

var dropped_platforms: Array[PhysicsBody2D] = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var gravity: float = 980.0
var jump_velocity: float = -420.0
var health: int = MAX_HEALTH
var invulnerability_frames_remaining: int = 0
var temporal_protection_timer: Timer
var temporal_protection_active: bool = false
var attack_cooldown_remaining: float = 0.0
var dialogue_controls_locked: bool = false
var drop_through_remaining: float = 0.0
var was_pressing_down: bool = false
var animation_was_on_floor: bool = true
var landing_animation_remaining: float = 0.0
const STEPS: Array[AudioStream] = [
	preload("res://assets/Sonidos/Efectos de sonido/derived/footsteps/step_1.wav"),
	preload("res://assets/Sonidos/Efectos de sonido/derived/footsteps/step_2.wav"),
	preload("res://assets/Sonidos/Efectos de sonido/derived/footsteps/step_3.wav"),
]
@onready var footstep_audio: AudioStreamPlayer2D = $FootstepAudio
@onready var landing_audio: AudioStreamPlayer2D = $LandingAudio
@onready var sword_audio: AudioStreamPlayer2D = $SwordAudio
var step_index: int = 0
var walking_on_support: bool = false
var has_grounded: bool = false
var air_time: float = 0.0


func _ready() -> void:
	add_to_group("core9_player")
	temporal_protection_timer = Timer.new()
	temporal_protection_timer.one_shot = true
	temporal_protection_timer.wait_time = TEMPORAL_PROTECTION_DURATION
	add_child(temporal_protection_timer)
	temporal_protection_timer.timeout.connect(cancel_temporal_protection)
	defeated.connect(cancel_temporal_protection)
	var base_gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var jump_height: float = (BASE_JUMP_VELOCITY * BASE_JUMP_VELOCITY) / (2.0 * base_gravity)
	gravity = base_gravity * GRAVITY_MULTIPLIER
	jump_velocity = -sqrt(2.0 * gravity * jump_height)
	animated_sprite.frame_changed.connect(_on_presentation_frame_changed)
	defeated.connect(sword_audio.stop)
	animated_sprite.animation_finished.connect(_on_presentation_finished)
	_play_idle()


func _physics_process(delta: float) -> void:
	if health <= 0:
		if footstep_audio.playing:
			footstep_audio.stop()
		if landing_audio.playing:
			landing_audio.stop()
		_apply_gravity(delta)
		move_and_slide()
		return
	var direction: float = 0.0 if presentation == &"pickup" or dialogue_controls_locked else Input.get_axis("move_left", "move_right")
	_update_timers(delta)
	_apply_gravity(delta)
	if presentation == &"pickup" and not dialogue_controls_locked and Input.is_action_just_pressed("jump"):
		_cancel_presentation()
	if not dialogue_controls_locked:
		_handle_jump()
	_handle_horizontal_movement(direction, delta)
	if not dialogue_controls_locked:
		_handle_drop_through()
		_handle_attack()
	var was_grounded: bool = is_on_floor()
	var support_velocity: Vector2 = get_platform_velocity() if was_grounded else Vector2.ZERO
	var incoming_speed: float = velocity.y
	move_and_slide()
	_update_movement_audio(delta, was_grounded, support_velocity, incoming_speed)
	_update_animation(delta)


func _update_movement_audio(delta: float, was_grounded: bool, support_velocity: Vector2, incoming_speed: float) -> void:
	var grounded: bool = is_on_floor()
	var relative_motion: Vector2 = get_position_delta() - support_velocity * delta
	walking_on_support = grounded and was_grounded and not dialogue_controls_locked and absf(velocity.x) > 1.0 and absf(relative_motion.x) > 0.35
	if not walking_on_support and footstep_audio.playing:
		footstep_audio.stop()
	if not grounded:
		air_time += delta
		return
	if has_grounded and not was_grounded and air_time >= 0.08 and incoming_speed >= 90.0:
		landing_audio.volume_db = -14.0 if incoming_speed < 180.0 else -10.0
		landing_audio.play()
	has_grounded = true
	air_time = 0.0


func _update_timers(delta: float) -> void:
	if invulnerability_frames_remaining > 0:
		invulnerability_frames_remaining -= 1
	animated_sprite.modulate.a = 0.35 if invulnerability_frames_remaining > 0 and (invulnerability_frames_remaining / 6) % 2 == 0 else 1.0
	attack_cooldown_remaining = move_toward(attack_cooldown_remaining, 0.0, delta)
	drop_through_remaining = move_toward(drop_through_remaining, 0.0, delta)
	if drop_through_remaining <= 0.0:
		for platform: PhysicsBody2D in dropped_platforms:
			if is_instance_valid(platform):
				remove_collision_exception_with(platform)
		dropped_platforms.clear()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var effective_gravity: float = gravity
	if velocity.y > 0.0:
		effective_gravity *= FALL_GRAVITY_MULTIPLIER
	velocity.y += effective_gravity * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _is_pressing_down():
		velocity.y = jump_velocity
	elif Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5


func _handle_horizontal_movement(direction: float, delta: float) -> void:
	var target_speed: float = direction * SPEED
	var rate: float = ACCELERATION if not is_zero_approx(direction) else FRICTION
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)


func _update_animation(delta: float) -> void:
	var grounded: bool = is_on_floor()
	if presentation != &"":
		animation_was_on_floor = grounded
		landing_animation_remaining = 0.0
		return
	if not is_zero_approx(velocity.x):
		animated_sprite.flip_h = velocity.x < 0.0
	if not grounded:
		landing_animation_remaining = 0.0
		_play_animation(&"jump" if velocity.y < 0.0 else &"fall")
	elif not animation_was_on_floor:
		landing_animation_remaining = 3.0 / 20.0
		animated_sprite.play(&"land")
	elif landing_animation_remaining > 0.0:
		landing_animation_remaining = maxf(0.0, landing_animation_remaining - delta)
		if is_zero_approx(landing_animation_remaining):
			_play_animation(&"idle" if is_zero_approx(velocity.x) else &"running")
	else:
		_play_animation(&"idle" if is_zero_approx(velocity.x) else &"running")
	animation_was_on_floor = grounded


func _play_animation(animation_name: StringName) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


func _play_idle() -> void:
	animated_sprite.play(&"idle")


func _handle_drop_through() -> void:
	var is_pressing_down: bool = _is_pressing_down()
	if is_pressing_down and not was_pressing_down and is_on_floor() and _can_drop_from_support():
		drop_through_remaining = DROP_THROUGH_DURATION
		for platform: PhysicsBody2D in dropped_platforms:
			add_collision_exception_with(platform)
		velocity.y = maxf(velocity.y, 1.0)
	was_pressing_down = is_pressing_down


func _can_drop_from_support() -> bool:
	var supports: Array[PhysicsBody2D] = []
	for index: int in get_slide_collision_count():
		var contact: KinematicCollision2D = get_slide_collision(index)
		if contact.get_normal().dot(up_direction) < cos(floor_max_angle):
			continue
		var body: PhysicsBody2D = contact.get_collider() as PhysicsBody2D
		if body == null:
			return false
		var has_shape: bool = false
		for owner_id: int in body.get_shape_owners():
			if body.is_shape_owner_disabled(owner_id):
				continue
			if body.shape_owner_get_shape_count(owner_id) == 0:
				continue
			has_shape = true
			if not body.is_shape_owner_one_way_collision_enabled(owner_id):
				return false
		if not has_shape:
			return false
		if not supports.has(body):
			supports.append(body)
	dropped_platforms = supports
	return not supports.is_empty()


func _is_pressing_down() -> bool:
	return Input.is_action_pressed("crouch_down")


func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		use_energy_slash()


func use_energy_slash() -> void:
	var progress: Node = get_node_or_null("/root/GameProgress")
	if dialogue_controls_locked or presentation != &"" or health <= 0 or progress == null or not progress.get("has_cronal_sword") or attack_cooldown_remaining > 0.0:
		return
	attack_cooldown_remaining = ATTACK_COOLDOWN
	_start_presentation(&"attack")
	energy_slash_used.emit()
	print("C.O.R.E.-9: Corte de Energia emitido. Otra solucion elegante a un problema mal diseniado.")


func take_damage(amount: int) -> void:
	if amount <= 0 or invulnerability_frames_remaining > 0 or is_temporally_protected() or health <= 0:
		return
	_cancel_presentation()
	health = maxi(health - amount, 0)
	invulnerability_frames_remaining = INVULNERABILITY_FRAMES
	health_changed.emit(health)
	damage_taken.emit(health)
	print("C.O.R.E.-9: Integridad reducida a %d/%d. La supervivencia sigue siendo opcional." % [health, MAX_HEALTH])
	if health == 0:
		velocity.x = 0.0
		animated_sprite.modulate.a = 1.0
		_start_presentation(&"defeat")
		defeated.emit()
		print("C.O.R.E.-9: Operador inutilizado. Las estadisticas agradecen su sacrificio.")

	else:
		_start_presentation(&"hurt")


func begin_temporal_protection() -> void:
	if health <= 0 or temporal_protection_timer == null:
		return
	temporal_protection_active = true
	temporal_protection_timer.start(TEMPORAL_PROTECTION_DURATION)
	temporal_protection_started.emit(TEMPORAL_PROTECTION_DURATION)


func cancel_temporal_protection() -> void:
	if temporal_protection_timer == null or not temporal_protection_active:
		return
	temporal_protection_active = false
	temporal_protection_timer.stop()
	temporal_protection_ended.emit()


func is_temporally_protected() -> bool:
	return temporal_protection_active


func get_temporal_protection_remaining() -> float:
	return temporal_protection_timer.time_left if is_temporally_protected() else 0.0


func _start_presentation(name: StringName) -> void:
	presentation = name
	animated_sprite.play(name)
	animated_sprite.set_frame_and_progress(0, 0.0)


func _cancel_presentation() -> void:
	$SwordHitbox.call("cancel_attack")
	if is_instance_valid(pickup_target):
		pickup_target.call("cancel_pickup", self)
	pickup_target = null
	presentation = &""


func begin_pickup(item: Area2D) -> bool:
	if health <= 0 or presentation != &"" or not is_on_floor():
		return false
	pickup_target = item
	_start_presentation(&"pickup")
	return true


func _on_presentation_frame_changed() -> void:
	if health > 0 and walking_on_support and not dialogue_controls_locked and animated_sprite.animation == &"running" and animated_sprite.frame in [0, 6]:
		footstep_audio.stream = STEPS[step_index]
		step_index = (step_index + 1) % STEPS.size()
		footstep_audio.play()
	# Frame 5 is source frame 06, the start of the energy sweep.
	if presentation == &"attack" and animated_sprite.animation == &"attack" and animated_sprite.frame == 5:
		$SwordHitbox.call("begin_attack", animated_sprite.flip_h)
		sword_audio.play()
	elif presentation == &"attack" and animated_sprite.frame >= 8:
		$SwordHitbox.call("cancel_attack")


func _on_presentation_finished() -> void:
	if animated_sprite.animation != presentation or presentation == &"":
		return
	if presentation == &"defeat":
		defeat_animation_finished.emit()
		return
	var finished: StringName = presentation
	presentation = &""
	if finished == &"attack":
		$SwordHitbox.call("cancel_attack")
	if finished == &"pickup":
		var item: Area2D = pickup_target
		pickup_target = null
		if is_instance_valid(item):
			item.call("complete_pickup", self)
	_update_animation(0.0)
