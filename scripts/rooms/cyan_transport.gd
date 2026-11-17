extends AnimatableBody2D

@export var left_x: float = 260.0
@export var right_x: float = 365.0
@export var speed: float = 60.0
@export var dwell: float = 1.0
var target_right: bool = true
var waiting: float = 1.0

func _physics_process(delta: float) -> void:
	if waiting > 0.0:
		waiting = maxf(0.0, waiting - delta)
		return
	var target: float = right_x if target_right else left_x
	position.x = move_toward(position.x, target, speed * delta)
	if is_equal_approx(position.x, target):
		target_right = not target_right
		waiting = dwell
