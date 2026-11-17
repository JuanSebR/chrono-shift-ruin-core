extends SceneTree

func _init() -> void:
	# Mapa: nombre PNG destino -> nombre archivo .ctex en .godot/imported
	var textures = {
		"fondo_1.5.png": "fondo_1.5.png-3154e30c26d090cad7508b387351c186.ctex",
		"plataformas_sala_1.5.png": "plataformas_sala_1.5.png-5056afeefdbcca1c5d78d47b5911c606.ctex",
		"complemento_plataformas.png": "complemento_plataformas.png-78d45f3bcab6344bc2b38fb28498d22e.ctex",
		"puente_translucido-removebg-preview.png": "puente_translucido-removebg-preview.png-3b3e0d4a730a739df17b7544083d602e.ctex"
	}

	foreach name, ctexPath in textures:
		var ctexPathFull: String = "res://.godot/imported/" + ctexPath
		var tex: Texture2D = load(ctexPathFull) as Texture2D
		if tex == null:
			push_error("No se pudo cargar el textura comprimida: " + ctexPath)
			continue
		var img: Image = tex.get_image()
		var err: Error = img.save_png("res://assets/tiles/Sala 1.5/" + name)
		if err == OK:
			print("Restaurado " + name)
		else:
			push_error("No se pudo guardar " + name + " (" + itos(err) + ")")
	quit()