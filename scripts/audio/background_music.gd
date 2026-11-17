extends AudioStreamPlayer
## One root-owned stream survives every scene change, reload and pause.

const MUSIC_PATH: String = "res://assets/Sonidos/Cancion/derived/global_background_loop.ogg"
const MUSIC_GROUP: StringName = &"core9_global_music"

func _ready() -> void:
	var existing: Node = get_tree().get_first_node_in_group(MUSIC_GROUP)
	if existing != null and existing != self:
		queue_free()
		return
	add_to_group(MUSIC_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(&"Music") < 0:
		push_error("C.O.R.E.-9: Falta el bus Music. Hasta el ruido exige su propio carril.")
		return
	var music: AudioStreamOggVorbis = load(MUSIC_PATH) as AudioStreamOggVorbis
	if music == null:
		push_error("C.O.R.E.-9: La musica no carga. El silencio no estaba en el contrato.")
		return
	music.loop = true
	music.loop_offset = 0.0
	stream = music
	bus = &"Music"
	volume_db = -18.0
	max_polyphony = 1
	play()
