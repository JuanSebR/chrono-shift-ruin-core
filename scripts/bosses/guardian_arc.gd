extends Node2D

const RADIUS: float = 8.0
const FINISH_TIME: float = 0.30
const ATLAS_DIRECTORY: String = "res://assets/sprites/jefe/derived/atlases/"

var packet: Sprite2D
var hold: AtlasTexture
var finishes: Array[AtlasTexture] = []
var circle: CircleShape2D = CircleShape2D.new()
var sweep_capsule: CapsuleShape2D = CapsuleShape2D.new()
var execution_id: int = -1
var last_emitted_id: int = -1
var emissions: int = 0
var contacts: int = 0
var sweep_queries: int = 0
var consumed: bool = false
var warning: bool = false
var locked: bool = false
var notice_progress: float = 0.0
var p0: Vector2
var p1: Vector2
var p2: Vector2
var duration: float = 0.45
var last_age: float = 0.0
var finish_age: float = -1.0
var packet_position: Vector2
var last_contact_position: Vector2
var last_contact_fraction: float = 1.0


func _ready() -> void:
	circle.radius = RADIUS
	sweep_capsule.radius = RADIUS
	hold = AtlasTexture.new()
	hold.atlas = load(ATLAS_DIRECTORY + "beam_hold_atlas.png") as Texture2D
	hold.region = Rect2(0, 0, 64, 64)
	var atlas: Texture2D = load(ATLAS_DIRECTORY + "beam_finish_atlas.png") as Texture2D
	for index: int in range(6):
		var texture: AtlasTexture = AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(index * 64, 0, 64, 64)
		finishes.append(texture)
	hide()


func begin_notice(id: int) -> void:
	cancel()
	execution_id = id
	warning = true
	consumed = false
	finish_age = -1.0
	show()


func update_notice(origin: Vector2, target: Vector2, direction: float, fixed: bool, progress: float) -> void:
	p0 = origin
	p1 = origin + Vector2(60.0 * direction, 0.0)
	p2 = target
	locked = fixed
	notice_progress = progress
	queue_redraw()


func emit_packet(id: int, origin: Vector2, target: Vector2, direction: float) -> bool:
	if id != execution_id or id == last_emitted_id or is_instance_valid(packet):
		return false
	last_emitted_id = id
	emissions += 1
	warning = false
	p0 = origin
	p1 = origin + Vector2(60.0 * direction, 0.0)
	p2 = target
	duration = maxf(0.45, 2.0 * maxf(p0.distance_to(p1), p1.distance_to(p2)) / 1400.0)
	last_age = 0.0
	finish_age = -1.0
	consumed = false
	packet_position = p0
	packet = Sprite2D.new()
	packet.name = "EnergyPacket"
	packet.texture = hold
	packet.scale = Vector2.ONE * 0.75
	packet.top_level = true
	add_child(packet)
	packet.global_position = packet_position
	packet.rotation = (p1 - p0).angle()
	queue_redraw()
	return true


func point(t: float) -> Vector2:
	return p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)


func _valid_player(body: Node) -> bool:
	return body is CharacterBody2D and body.is_in_group("core9_player") and int(body.get("health")) > 0


func sweep(from: Vector2, to: Vector2) -> Dictionary:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, from)
	query.collision_mask = 2
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for hit: Dictionary in space.intersect_shape(query):
		if _valid_player(hit["collider"]):
			return {"body": hit["collider"], "fraction": 0.0}
	var motion: Vector2 = to - from
	if motion.length_squared() < 0.000001:
		return {}
	# This capsule is exactly the volume swept by radius8 along the segment.
	sweep_capsule.height = motion.length() + RADIUS * 2.0
	var volume: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	volume.shape = sweep_capsule
	volume.transform = Transform2D(motion.angle() - PI * 0.5, (from + to) * 0.5)
	volume.collision_mask = 2
	volume.collide_with_areas = false
	volume.collide_with_bodies = true
	var candidates: Array[Dictionary] = space.intersect_shape(volume)
	var players: Array[Node] = []
	var excluded: Array[RID] = []
	for hit: Dictionary in candidates:
		if _valid_player(hit["collider"]):
			players.append(hit["collider"])
		else:
			excluded.append(hit["rid"])
	if players.is_empty():
		return {}
	query.motion = motion
	query.exclude = excluded
	sweep_queries += 1
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions[0] >= 1.0:
		return {}
	# Resolve the earliest valid body, even if several bodies share layer2.
	var first: Node
	var first_fraction: float = 1.0
	for body: Node in players:
		var others: Array[RID] = excluded.duplicate()
		for other: Node in players:
			if other != body:
				others.append((other as CollisionObject2D).get_rid())
		query.exclude = others
		var candidate_fraction: float = space.cast_motion(query)[0]
		if candidate_fraction < first_fraction:
			first = body
			first_fraction = candidate_fraction
	return {"body": first, "fraction": first_fraction} if first != null else {}


func advance(age: float, amount: int) -> void:
	if not is_instance_valid(packet):
		return
	if not consumed:
		var from_t: float = clampf(last_age / duration, 0.0, 1.0)
		var to_t: float = clampf(age / duration, 0.0, 1.0)
		var bound: float = 2.0 * maxf(p0.distance_to(p1), p1.distance_to(p2)) * (to_t - from_t)
		var steps: int = maxi(1, ceili(bound / 4.0))
		for index: int in range(1, steps + 1):
			var t: float = lerpf(from_t, to_t, float(index) / float(steps))
			var next_position: Vector2 = point(t)
			var hit: Dictionary = sweep(packet_position, next_position)
			if not hit.is_empty():
				last_contact_fraction = float(hit["fraction"])
				packet_position = packet_position.lerp(next_position, last_contact_fraction)
				last_contact_position = packet_position
				contacts += 1
				hit["body"].call("take_damage", amount)
				consumed = true
				finish_age = age
				break
			packet_position = next_position
		var tangent: Vector2 = (p1 - p0) * (2.0 * (1.0 - to_t)) + (p2 - p1) * (2.0 * to_t)
		if tangent.length_squared() > 0.001:
			packet.rotation = tangent.angle()
		packet.global_position = packet_position
		if to_t >= 1.0 and not consumed:
			consumed = true
			finish_age = age
	last_age = age
	if consumed:
		var elapsed: float = age - finish_age
		packet.texture = finishes[mini(5, int(elapsed / (FINISH_TIME / 6.0)))]
		if elapsed >= FINISH_TIME:
			packet.queue_free()
			packet = null


func finished() -> bool:
	return not is_instance_valid(packet) and not warning


func cancel() -> void:
	warning = false
	consumed = true
	if is_instance_valid(packet):
		packet.free()
	packet = null
	hide()
	queue_redraw()


func _draw() -> void:
	if not warning or hold == null:
		return
	# Short luminous strips from the existing atlas, not a new reticle sprite.
	for index: int in range(1, 40, 2):
		var t: float = float(index) / 40.0
		var p: Vector2 = to_local(point(t))
		var tangent: Vector2 = (p1 - p0) * (1.0 - t) + (p2 - p1) * t
		draw_set_transform(p, tangent.angle())
		draw_texture_rect_region(hold.atlas, Rect2(-4,-1,8,2), Rect2(0,20,8,2))
	draw_set_transform(Vector2.ZERO)
	var target: Vector2 = to_local(p2)
	if locked:
		for sign_x: float in [-1.0,1.0]:
			for sign_y: float in [-1.0,1.0]:
				var corner: Vector2 = target + Vector2(sign_x * 28, sign_y * 24)
				draw_set_transform(corner)
				draw_texture_rect_region(hold.atlas, Rect2(-6,-1,12,2), Rect2(0,16,12,2))
				draw_set_transform(corner, PI * 0.5)
				draw_texture_rect_region(hold.atlas, Rect2(-6,-1,12,2), Rect2(0,16,12,2))
	else:
		for y: float in [-20.0,0.0,20.0]:
			draw_set_transform(target + Vector2(-30,y))
			draw_texture_rect_region(hold.atlas, Rect2(-6,-1,12,2), Rect2(0,16,12,2))
	draw_set_transform(Vector2.ZERO)
	var message: String = "FIJO" if locked else "FIJANDO"
	draw_string(ThemeDB.fallback_font,target + Vector2(35,-22),message,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	# Five short charge ticks show the remaining time without covering the body.
	for index: int in range(5):
		draw_set_transform(target + Vector2(35 + index * 9,-15))
		var tint: Color = Color.WHITE if notice_progress >= float(index + 1) / 5.0 else Color(1,1,1,0.2)
		draw_texture_rect_region(hold.atlas, Rect2(0,0,6,2), Rect2(0,20,6,2), tint)
	draw_set_transform(Vector2.ZERO)
