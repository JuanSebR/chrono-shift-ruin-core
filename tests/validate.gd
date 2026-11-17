extends SceneTree

func _init() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var player_script: Script = load("res://Player.gd") as Script
	var dimension_manager_script: Script = load("res://DimensionManager.gd") as Script
	var hud_script: Script = load("res://HUD.gd") as Script
	var game_manager_script: Script = load("res://GameManager.gd") as Script
	var main_menu_script: Script = load("res://MainMenu.gd") as Script
	var room1_5_script: Script = load("res://Room1_5.gd") as Script
	var level_transition_script: Script = load("res://LevelTransition.gd") as Script
	var tutorial_room: PackedScene = load("res://scenes/Room1_Tutorial.tscn") as PackedScene
	var main_menu: PackedScene = load("res://scenes/MainMenu.tscn") as PackedScene
	var player_scene: PackedScene = load("res://scenes/Player.tscn") as PackedScene
	var room1_5: PackedScene = load("res://scenes/Room1_5.tscn") as PackedScene
	var player_frames: SpriteFrames = load("res://player_frames.tres") as SpriteFrames
	if player_script == null or not player_script.can_instantiate() \
		or dimension_manager_script == null or not dimension_manager_script.can_instantiate() \
		or hud_script == null or not hud_script.can_instantiate() \
		or game_manager_script == null or not game_manager_script.can_instantiate() \
		or main_menu_script == null or not main_menu_script.can_instantiate() \
		or room1_5_script == null or not room1_5_script.can_instantiate() \
		or level_transition_script == null or not level_transition_script.can_instantiate() \
		or tutorial_room == null or not tutorial_room.can_instantiate() \
		or main_menu == null or not main_menu.can_instantiate() \
		or player_scene == null or not player_scene.can_instantiate() \
		or room1_5 == null or not room1_5.can_instantiate() \
		or player_frames == null:
		push_error("No se pudo cargar un script, escena o recurso requerido")
		quit(1)
		return
	if not player_frames.has_animation(&"running") \
		or not player_frames.has_animation(&"idle") \
		or not player_frames.has_animation(&"jump"):
		push_error("C.O.R.E.-9: Las animaciones esperadas no existen. El vacio encontro trabajo.")
		quit(1)
		return
	var run_frame: AtlasTexture = player_frames.get_frame_texture(&"running", 0) as AtlasTexture
	if player_frames.get_frame_count(&"running") != 12 \
		or not is_equal_approx(player_frames.get_animation_speed(&"running"), 15.0) \
		or run_frame == null \
		or run_frame.atlas == null \
		or run_frame.region.size != Vector2(181.0, 724.0):
		push_error("C.O.R.E.-9: La animacion running tiene frames defectuosos. Innovador, pero inutil.")
		quit(1)
		return
	var player_instance: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	var player_sprite: AnimatedSprite2D = player_instance.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var sprite_valid: bool = player_sprite != null \
		and player_sprite.sprite_frames != null \
		and player_sprite.sprite_frames.has_animation(&"running") \
		and player_sprite.position.is_equal_approx(Vector2(0.0, -26.2)) \
		and player_sprite.scale.is_equal_approx(Vector2(0.33, 0.33))
	player_instance.free()
	if not sprite_valid:
		push_error("C.O.R.E.-9: El AnimatedSprite2D del jugador no coincide con el plan. Sorpresa.")
		quit(1)
		return
	for path: String in ["res://scripts/game_progress.gd", "res://scripts/items/cronal_sword_pickup.gd", "res://scripts/combat/sword_hitbox.gd", "res://scripts/combat/enemy_projectile.gd", "res://scripts/enemies/enemy1.gd"]:
		var combat_script: Script = load(path) as Script
		if combat_script == null or not combat_script.can_instantiate():
			push_error("C.O.R.E.-9: Combate sin compilar. Que amenaza tan teorica: " + path)
			quit(1)
			return
	for path: String in ["res://scenes/items/CronalSwordPickup.tscn", "res://scenes/enemies/Enemy1.tscn", "res://scenes/combat/EnemyProjectile.tscn"]:
		var combat_scene: PackedScene = load(path) as PackedScene
		if combat_scene == null or not combat_scene.can_instantiate():
			quit(1)
			return
	var presentation_frames: SpriteFrames = load("res://assets/animations/core9_presentation_frames.tres") as SpriteFrames
	if presentation_frames == null:
		quit(1)
		return
	for name: StringName in [&"attack", &"pickup", &"hurt", &"defeat"]:
		if not presentation_frames.has_animation(name) or presentation_frames.get_frame_count(name) == 0 or presentation_frames.get_animation_loop(name):
			quit(1)
			return
	for path: String in ["res://scenes/FinalRoom.tscn", "res://scenes/ending/FinalAccessDoor.tscn"]:
		var final_scene: PackedScene = load(path) as PackedScene
		if final_scene == null or not final_scene.can_instantiate():
			push_error("C.O.R.E.-9: Final sin escena valida. Una despedida bastante teorica: " + path)
			quit(1)
			return
	print("--- VALIDACION DE SINTAXIS EXITOSA ---")
	# Autoloads are ready before validation; release the global Ogg voice before fast headless exit.
	var music: AudioStreamPlayer = root.get_node_or_null("BackgroundMusic") as AudioStreamPlayer
	if music != null:
		music.stop()
		OS.delay_msec(100)
	quit()
