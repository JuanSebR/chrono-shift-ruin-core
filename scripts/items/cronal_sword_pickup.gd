extends Area2D

var collected: bool = false
var collector: CharacterBody2D

func _ready() -> void:
	if get_node("/root/GameProgress").get("has_cronal_sword"):
		queue_free()

func _physics_process(_delta: float) -> void:
	if collected or is_instance_valid(collector):
		return
	for body: Node2D in get_overlapping_bodies():
		if body is CharacterBody2D and body.is_in_group("core9_player") and bool(body.call("begin_pickup", self)):
			collector = body as CharacterBody2D
			return

func complete_pickup(body: CharacterBody2D) -> void:
	if collected or body != collector or int(body.get("health")) <= 0:
		return
	collected = true
	get_node("/root/GameProgress").call("acquire_sword")
	hide()
	set_deferred("monitoring", false)
	queue_free()

func cancel_pickup(body: CharacterBody2D) -> void:
	if collector == body:
		collector = null
