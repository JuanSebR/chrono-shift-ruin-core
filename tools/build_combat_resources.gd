extends SceneTree

func _init() -> void:
	for folder: String in ["res://scenes/items", "res://scenes/enemies", "res://scenes/combat", "res://assets/animations"]:
		DirAccess.make_dir_recursive_absolute(folder)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/combat_manifest.json"))
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for key: String in manifest:
		var spec: Dictionary = manifest[key]
		frames.add_animation(key)
		frames.set_animation_speed(key, spec["fps"])
		frames.set_animation_loop(key, spec["loop"])
		var texture: Texture2D = load("res://assets/Enemigos/" + spec["file"]) as Texture2D
		var cuts: Array = spec["cuts"]
		for i: int in range(cuts.size() - 1):
			var region: Rect2 = Rect2(cuts[i], spec["top"], cuts[i + 1] - cuts[i], spec["feet"] + 2 - spec["top"])
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			atlas.margin = Rect2(Vector2((460.0 - region.size.x) / 2.0, 500.0 - (float(spec["feet"]) - float(spec["top"]))), Vector2(460.0, 500.0) - region.size)
			atlas.filter_clip = true
			frames.add_frame(key, atlas, 1.0)
	assert(ResourceSaver.save(frames, "res://assets/animations/enemy1_frames.tres") == OK)
	var sword_texture: AtlasTexture = AtlasTexture.new()
	sword_texture.atlas = load("res://assets/sprites/Sprites arma/sword environment v1.png") as Texture2D
	sword_texture.region = Rect2(480, 240, 560, 500)
	sword_texture.filter_clip = true
	assert(ResourceSaver.save(sword_texture, "res://assets/animations/cronal_sword_texture.tres") == OK)
	var pickup: Area2D = Area2D.new()
	pickup.name = "CronalSwordPickup"
	pickup.collision_layer = 0
	pickup.collision_mask = 2
	pickup.set_script(load("res://scripts/items/cronal_sword_pickup.gd"))
	var pickup_sprite: Sprite2D = Sprite2D.new()
	pickup_sprite.name = "Sprite2D"
	pickup_sprite.texture = sword_texture
	pickup_sprite.scale = Vector2.ONE * 0.12
	_add(pickup, pickup_sprite)
	_shape(pickup, Vector2(20, 28))
	_save(pickup, "res://scenes/items/CronalSwordPickup.tscn")
	var projectile: Area2D = Area2D.new()
	projectile.name = "EnemyProjectile"
	projectile.collision_layer = 0
	projectile.collision_mask = 3
	projectile.set_script(load("res://scripts/combat/enemy_projectile.gd"))
	_shape(projectile, Vector2(10, 8))
	var shot_sprite: Sprite2D = Sprite2D.new()
	shot_sprite.name = "Sprite2D"
	shot_sprite.texture = load("res://assets/Enemigos/enemy_1 proyectil_flying v1.png") as Texture2D
	shot_sprite.scale = Vector2.ONE * 0.04
	_add(projectile, shot_sprite)
	_save(projectile, "res://scenes/combat/EnemyProjectile.tscn")
	var enemy: CharacterBody2D = CharacterBody2D.new()
	enemy.name = "Enemy1"
	enemy.collision_layer = 4
	enemy.collision_mask = 1
	enemy.floor_snap_length = 4.0
	enemy.set_script(load("res://scripts/enemies/enemy1.gd"))
	enemy.set("projectile_scene", load("res://scenes/combat/EnemyProjectile.tscn"))
	_shape(enemy, Vector2(36, 40))
	var animated: AnimatedSprite2D = AnimatedSprite2D.new()
	animated.name = "AnimatedSprite2D"
	animated.sprite_frames = frames
	animated.animation = &"walking"
	animated.scale = Vector2.ONE * 0.20
	animated.position = Vector2(0, -30)
	_add(enemy, animated)
	var hurtbox: Area2D = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.add_to_group("enemy_hurtbox", true)
	_add(enemy, hurtbox)
	_shape(hurtbox, Vector2(36, 40), enemy)
	_save(enemy, "res://scenes/enemies/Enemy1.tscn")
	print("PASS: combat resources and standalone scenes built with Godot APIs")
	quit()

func _add(parent: Node, child: Node, scene_owner: Node = null) -> void:
	parent.add_child(child)
	child.owner = parent if scene_owner == null else scene_owner

func _shape(parent: Node, size: Vector2, scene_owner: Node = null) -> void:
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	_add(parent, collision, scene_owner)

func _save(node: Node, path: String) -> void:
	var scene: PackedScene = PackedScene.new()
	assert(scene.pack(node) == OK)
	assert(ResourceSaver.save(scene, path) == OK)
	node.free()
