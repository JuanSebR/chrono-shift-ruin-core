extends Node

signal sword_acquired
signal temporal_lens_acquired
signal save_failed
signal reactor_key_acquired
signal core_guardian_victory_recorded

const SAVE_PATH: String = "user://progress_v1.json"
const INITIAL_ROOM: String = "res://scenes/Room1_Tutorial.tscn"
# Tutorial and Sala 1 are the same scene. These are safe menu spawns, not exit markers.
const ROOM_SPAWNS: Dictionary = {
	INITIAL_ROOM: &"Player",
	"res://scenes/Room1_5.tscn": &"EntryFromTutorial",
	"res://scenes/Room2.tscn": &"EntryMarkers/Spawn",
	"res://scenes/Room2_2.tscn": &"EntryMarkers/FromRoom2",
	"res://scenes/Room3.tscn": &"EntryMarkers/FromRoom2_2",
	"res://scenes/Room4.tscn": &"EntryMarkers/Spawn",
	"res://scenes/Room5.tscn": &"EntryMarkers/Spawn",
}
var last_room_checkpoint: String = ""
var _has_saved_progress: bool = false
var has_cronal_sword: bool = false
var has_temporal_lens: bool = false
var has_reactor_key: bool = false
var core_guardian_defeated: bool = false
const TUTORIAL_DEFAULTS: Dictionary = {
	"move": false, "jump": false, "attack": false,
	"room4_shift": false, "room4_present": false, "room4_past": false,
}
var completed_tutorials: Dictionary = TUTORIAL_DEFAULTS.duplicate()
var completed_dialogues: Dictionary = {}
var active_dialogue_id: String = ""

func complete_dialogue(id: String) -> void:
	if completed_dialogues.has(id):
		return
	completed_dialogues[id] = true
	save_progress()

func dialogue_completed(id: String) -> bool:
	return bool(completed_dialogues.get(id, false))

func complete_tutorial(id: String) -> void:
	if not completed_tutorials.has(id) or completed_tutorials[id]:
		return
	completed_tutorials[id] = true
	save_progress()

func tutorial_completed(id: String) -> bool:
	return bool(completed_tutorials.get(id, false))

func _ready() -> void:
	load_progress()

func acquire_sword() -> bool:
	if has_cronal_sword:
		return false
	has_cronal_sword = true
	save_progress()
	sword_acquired.emit()
	return true

func acquire_temporal_lens() -> bool:
	if has_temporal_lens:
		return false
	has_temporal_lens = true
	if not save_progress():
		has_temporal_lens = false
		return false
	temporal_lens_acquired.emit()
	return true

func new_game() -> bool:
	var previous_checkpoint: String = last_room_checkpoint
	last_room_checkpoint = INITIAL_ROOM
	var previous_victory: bool = core_guardian_defeated
	core_guardian_defeated = false
	var previous_key: bool = has_reactor_key
	has_reactor_key = false
	var previous: bool = has_cronal_sword
	var previous_lens: bool = has_temporal_lens
	var previous_tutorials: Dictionary = completed_tutorials.duplicate()
	var previous_dialogues: Dictionary = completed_dialogues.duplicate()
	has_cronal_sword = false
	has_temporal_lens = false
	completed_tutorials = TUTORIAL_DEFAULTS.duplicate()
	completed_dialogues = {}
	if not save_progress():
		last_room_checkpoint = previous_checkpoint
		core_guardian_defeated = previous_victory
		has_reactor_key = previous_key
		has_cronal_sword = previous
		has_temporal_lens = previous_lens
		completed_tutorials = previous_tutorials
		completed_dialogues = previous_dialogues
		return false
	clear_room_arrival()
	active_dialogue_id = ""
	return true

func save_progress() -> bool:
	var temp: String = SAVE_PATH + ".tmp"
	var backup: String = SAVE_PATH + ".bak"
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return _save_error()
	file.store_string(JSON.stringify({"version": 1, "last_room_checkpoint": last_room_checkpoint, "core_guardian_defeated": core_guardian_defeated, "has_reactor_key": has_reactor_key, "has_cronal_sword": has_cronal_sword, "has_temporal_lens": has_temporal_lens, "completed_tutorials": completed_tutorials, "completed_dialogues": completed_dialogues}))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return _save_error()
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(backup):
			if DirAccess.remove_absolute(backup) != OK:
				return _save_error()
		if DirAccess.rename_absolute(SAVE_PATH, backup) != OK:
			return _save_error()
	if DirAccess.rename_absolute(temp, SAVE_PATH) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, SAVE_PATH)
		return _save_error()
	_has_saved_progress = true
	return true

func load_progress() -> bool:
	_has_saved_progress = false
	for path: String in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_length() > 4096:
			continue
		var parser: JSON = JSON.new()
		if parser.parse(file.get_as_text()) != OK:
			continue
		var data: Variant = parser.data
		if data is Dictionary and data.get("version") == 1 and typeof(data.get("has_cronal_sword")) == TYPE_BOOL:
			var checkpoint: Variant = data.get("last_room_checkpoint", "")
			last_room_checkpoint = checkpoint if checkpoint is String and is_checkpoint_room(checkpoint) else ""
			core_guardian_defeated = data.get("core_guardian_defeated") == true
			has_cronal_sword = data["has_cronal_sword"]
			has_temporal_lens = data.get("has_temporal_lens") == true
			has_reactor_key = data.get("has_reactor_key") == true
			completed_tutorials = TUTORIAL_DEFAULTS.duplicate()
			completed_dialogues = {}
			var stored: Variant = data.get("completed_tutorials", {})
			if stored is Dictionary:
				for id: String in completed_tutorials:
					if typeof(stored.get(id)) == TYPE_BOOL:
						completed_tutorials[id] = stored[id]
			var dialogues: Variant = data.get("completed_dialogues", {})
			if dialogues is Dictionary:
				for id: Variant in dialogues:
					if id is String and typeof(dialogues[id]) == TYPE_BOOL and dialogues[id]:
						completed_dialogues[id] = true
			_has_saved_progress = true
			return true
	return false


func is_checkpoint_room(scene_path: String) -> bool:
	if not ROOM_SPAWNS.has(scene_path) or not ResourceLoader.exists(scene_path, "PackedScene"):
		return false
	var packed: PackedScene = load(scene_path) as PackedScene
	return packed != null and packed.can_instantiate()


func get_continue_scene() -> String:
	if not _has_saved_progress:
		return ""
	if is_checkpoint_room(last_room_checkpoint):
		return last_room_checkpoint
	# Legacy v1 saves used Room1.5 after acquiring the sword. Reading never migrates the file.
	var fallback: String = "res://scenes/Room1_5.tscn" if has_cronal_sword else INITIAL_ROOM
	return fallback if is_checkpoint_room(fallback) else ""


func prepare_continue_arrival() -> String:
	clear_room_arrival()
	var destination: String = get_continue_scene()
	if destination.is_empty():
		return ""
	arrival_scene = destination
	arrival_marker = ROOM_SPAWNS[destination]
	arrival_health = 3
	arrival_facing_left = false
	arrival_invulnerability = 0
	arrival_attack_cooldown = 0.0
	_arrival_is_resume = true
	return destination

func _save_error() -> bool:
	push_warning("C.O.R.E.-9: El disco rechazo mi memoria. Adquisicion pendiente; brillante infraestructura.")
	save_failed.emit()
	return false


func acquire_reactor_key() -> bool:
	if has_reactor_key:
		return false
	has_reactor_key = true
	if not save_progress():
		has_reactor_key = false
		return false
	reactor_key_acquired.emit()
	return true


func record_core_guardian_victory() -> bool:
	if core_guardian_defeated:
		return true
	core_guardian_defeated = true
	if not save_progress():
		core_guardian_defeated = false
		return false
	core_guardian_victory_recorded.emit()
	return true


# Ephemeral room-to-room handoff; never written to the save file.
var arrival_scene: String = ""
var arrival_marker: StringName = &""
var arrival_health: int = 3
var arrival_facing_left: bool = false
var arrival_invulnerability: int = 0
var arrival_attack_cooldown: float = 0.0
var _arrival_is_resume: bool = false
var _arrival_from_transition: bool = false
var _arrival_serial: int = 0

func prepare_room_arrival(scene_path: String, marker: StringName, player: CharacterBody2D, transition: Area2D = null) -> void:
	clear_room_arrival()
	var source: Node = get_tree().current_scene
	_arrival_from_transition = is_instance_valid(transition) and source != null \
		and source.is_ancestor_of(transition) and source.get_node_or_null("Player") == player \
		and is_checkpoint_room(source.scene_file_path) and is_checkpoint_room(scene_path)
	arrival_scene = scene_path
	arrival_marker = marker
	arrival_health = int(player.get("health"))
	arrival_invulnerability = int(player.get("invulnerability_frames_remaining"))
	arrival_attack_cooldown = float(player.get("attack_cooldown_remaining"))
	arrival_facing_left = (player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h

func clear_room_arrival() -> void:
	_arrival_serial += 1
	arrival_scene = ""
	arrival_marker = &""
	_arrival_is_resume = false
	_arrival_from_transition = false

func apply_room_arrival(scene: Node, player: CharacterBody2D) -> void:
	if arrival_scene != scene.scene_file_path or arrival_marker == &"":
		return
	var marker: Node2D = scene.get_node_or_null(NodePath(String(arrival_marker))) as Node2D
	if marker == null or (not _arrival_is_resume and not marker is Marker2D):
		push_error("C.O.R.E.-9: Punto de entrada inexistente. La arquitectura sigue siendo una sugerencia.")
		clear_room_arrival()
		return
	player.global_position = marker.global_position
	player.velocity = Vector2.ZERO
	player.set("health", arrival_health)
	player.set("invulnerability_frames_remaining", arrival_invulnerability)
	player.set("attack_cooldown_remaining", arrival_attack_cooldown)
	(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h = arrival_facing_left
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	var confirm_transition: bool = _arrival_from_transition
	clear_room_arrival()
	if confirm_transition:
		# _ready runs before SceneTree finishes assigning current_scene. Confirm after it does.
		call_deferred("_confirm_room_checkpoint", scene, player, _arrival_serial)


func _confirm_room_checkpoint(scene: Node, player: CharacterBody2D, serial: int) -> void:
	if serial != _arrival_serial or not is_instance_valid(scene) or not is_instance_valid(player):
		return
	if get_tree().current_scene != scene or scene.get_node_or_null("Player") != player \
		or not player.global_position.is_finite() or int(player.get("health")) <= 0:
		return
	if not OS.get_environment("CHRONOSHIFT_ROOM5_PROFILE").is_empty():
		return
	var destination: String = scene.scene_file_path
	if not is_checkpoint_room(destination) or last_room_checkpoint == destination:
		return
	var previous: String = last_room_checkpoint
	last_room_checkpoint = destination
	if not save_progress():
		last_room_checkpoint = previous
