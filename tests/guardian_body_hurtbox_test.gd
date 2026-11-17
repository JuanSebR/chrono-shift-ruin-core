extends "res://tests/guardian_three_attacks_test.gd"

var impacts: Array[Dictionary] = []
var cases: Array[Dictionary] = []
var pose_image: Image

func record_impact(amount: int) -> void:
	var sword: Area2D = player.get_node("SwordHitbox")
	var blade_size: Vector2 = (sword.collision.shape as RectangleShape2D).size
	var transform: Transform2D = boss.sprite.global_transform.affine_inverse()*sword.collision.global_transform
	var pixels: Rect2 = transform*Rect2(-blade_size*0.5,blade_size)
	if boss.sprite.flip_h:
		pixels.position.x = pose_image.get_width()-pixels.end.x
	var region: Rect2i = Rect2i(pixels).intersection(Rect2i(Vector2i.ZERO,pose_image.get_size()))
	var visible_overlap: bool = false
	for y: int in range(region.position.y,region.end.y):
		for x: int in range(region.position.x,region.end.x):
			if pose_image.get_pixel(x,y).a >= 0.5:
				visible_overlap = true
				break
		if visible_overlap:
			break
	impacts.append({"amount":amount,"player":player.position,"blade":sword.global_position,"left":sword.facing < 0,"airborne":not player.is_on_floor(),"window":boss.window_elapsed,"visible_overlap":visible_overlap,"pixels":region,"frame":boss.sprite.frame})

func swing(jump_kind: String, walking: bool, left: bool) -> void:
	var action: String = "move_left" if left else "move_right"
	Input.action_press(action)
	await ticks(8 if walking else 1)
	Input.action_release(action)
	await ticks(2)
	if walking:
		check(absf(player.velocity.x) > 0,"Ataque iniciado desde movimiento real")
	if jump_kind != "":
		Input.action_press("jump")
		await ticks(2)
		if jump_kind == "short":
			Input.action_release("jump")
			await ticks(2)
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	await ticks(30)
	Input.action_release("jump")
	for i: int in range(50):
		if player.is_on_floor():
			break
		await ticks(1)
	await ticks(3)

func run() -> void:
	if not OS.get_user_data_dir().contains("guardian_body_work"):
		quit(2)
		return
	var progress: Node = root.get_node("GameProgress")
	check(progress.new_game(),"Perfil corporal aislado")
	var definitions: Array[Dictionary] = [
		{"part":"piernas","left":false,"spawn":Vector2(1072,600),"jump":"","walk":true},
		{"part":"torso","left":false,"spawn":Vector2(1068,570),"jump":"","walk":true},
		{"part":"cabeza","left":false,"spawn":Vector2(1104,570),"jump":"short","walk":false},
		{"part":"piernas","left":true,"spawn":Vector2(1210,590),"jump":"","walk":true},
		{"part":"torso","left":true,"spawn":Vector2(1210,590),"jump":"short","walk":false},
		{"part":"cabeza","left":true,"spawn":Vector2(1180,590),"jump":"full","walk":false},
	]
	for definition: Dictionary in definitions:
		await fresh_fixture()
		vertical.process_mode = Node.PROCESS_MODE_DISABLED
		horizontal.process_mode = Node.PROCESS_MODE_DISABLED
		direct.process_mode = Node.PROCESS_MODE_DISABLED
		# Initial location only. Swings, facing, movement and jumps use Player input.
		player.position = definition.spawn
		await ticks(15)
		check(player.is_on_floor(),"Apoyo real antes del caso "+definition.part)
		if not player.is_on_floor():
			quit(1)
			return
		boss.take_damage(1)
		check(boss.health == 3 and boss.core_shape.disabled,"Reposo invulnerable y forma desactivada")
		check(boss.start_combat_cycle(),"Ciclo real para caso "+definition.part)
		for i: int in range(2710):
			if boss.state == boss.State.VULNERABLE:
				break
			await ticks(1)
		await ticks(2)
		check(boss.can_receive_damage() and not boss.core_shape.disabled,"Rectangulo solo activo en sobrecalentamiento Presente")
		check(boss.weakpoint.collision_layer == 8 and boss.weakpoint.monitorable and boss.weakpoint.is_in_group("enemy_hurtbox") and player.get_node("SwordHitbox").damage == 1,"Capa8, monitorable, grupo y dano de espada correctos")
		pose_image = boss.base_frames.get_frame_texture(&"vulnerable",boss.sprite.frame).get_image()
		if pose_image.is_compressed():
			pose_image.decompress()
		impacts.clear()
		boss.damage_accepted.connect(record_impact)
		for i: int in range(3):
			var before: int = boss.health
			await swing(definition.jump,definition.walk and i == 0,definition.left)
			check(boss.health == before-1,"Tajo unico "+definition.part+" lado "+("derecho" if definition.left else "izquierdo"))
		check(impacts.size() == 3 and boss.health == 0,"Tres senales de impacto y3->2->1->0")
		for impact: Dictionary in impacts:
			var blade: Vector2 = impact.blade
			check(impact.amount == 1 and impact.left == definition.left and impact.window < 6.0,"Orientacion y un solo1HP por tajo dentro de6s")
			check(impact.visible_overlap,"Espada intersecta pixeles visibles del cuerpo")
			if definition.part == "cabeza":
				check(impact.airborne and blade.y < 540.0,"Espada alcanza zona superior mediante salto real")
			elif definition.part == "torso":
				check(blade.y >= 540.0 and blade.y < 588.0,"Espada intersecta torso")
			else:
				check(blade.y >= 588.0,"Espada intersecta piernas")
		cases.append({"definition":definition,"impacts":impacts.duplicate(true),"remaining_hp":boss.health})
		print("BODY_CASE ",JSON.stringify(cases[-1]))
		await ticks(80)
		check(boss.core_shape.disabled and not boss.can_receive_damage(),"Derrota desactiva rectangulo")
		# Stop playback before removing each fixture in this accelerated headless run.
		player.sword_audio.stop()
		player.landing_audio.stop()
		player.footstep_audio.stop()
		await ticks(3)
	var report: FileAccess = FileAccess.open("user://body_results.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"cases":cases},"\t"))
	report.close()
	room.queue_free()
	await ticks(3)
	print("GUARDIAN_BODY_RESULT failures=",failures)
	quit(0 if failures == 0 else 1)
