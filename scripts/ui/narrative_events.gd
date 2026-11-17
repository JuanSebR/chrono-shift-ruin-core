extends Node

@export_enum("room1", "room15") var room_kind: String = "room1"

var pending_sword: bool = false
var pending_victory: bool = false

func on_sword_acquired() -> void:
	pending_sword = true

func on_enemy_defeated() -> void:
	pending_victory = true

func _process(_delta: float) -> void:
	var room: Node = get_parent()
	var player: CharacterBody2D = room.get_node("Player") as CharacterBody2D
	if player == null or int(player.get("health")) <= 0:
		return
	var dialogue: CanvasLayer = room.get_node("DialoguePanel") as CanvasLayer
	if str(dialogue.get("active_id")) != "":
		return
	var progress: Node = get_node("/root/GameProgress")
	if room_kind == "room1":
		if player.global_position.x < 100.0 and not bool(progress.call("dialogue_completed", "awakening")) and not bool(player.get("dialogue_controls_locked")):
			var opening: Array[Dictionary] = [
				{"text": "…Otra vez.", "expression": "core9_expression_1_01"},
				{"text": "Torre Zaman. Reactor principal: sin respuesta.", "expression": "core9_expression_1_06"},
				{"text": "Repararlo y terminar mi turno. Ese sigue siendo el plan.", "expression": "core9_expression_1_03"}
			]
			dialogue.call("start_conversation", "awakening", opening, player, true)
		elif player.global_position.x >= 720.0 and not bool(progress.call("dialogue_completed", "corridor_memory")):
			var memory: Array[Dictionary] = [{"text": "Aquí había un corredor entero. Estoy casi segura.", "expression": "core9_expression_1_04"}]
			dialogue.call("start_conversation", "corridor_memory", memory, player, true, true, 5.0)
	else:
		if pending_sword and not bool(progress.call("dialogue_completed", "old_tool")) and String(player.get("presentation")) == "":
			pending_sword = false
			var sword_lines: Array[Dictionary] = [
				{"text": "Espada cronal. Todavía operativa.", "expression": "core9_expression_1_04"},
				{"text": "Al fin, algo que no tengo que reparar.", "expression": "core9_expression_1_03"}
			]
			dialogue.call("start_conversation", "old_tool", sword_lines, player, true)
		elif pending_victory and not bool(progress.call("dialogue_completed", "incident_resolved")):
			pending_victory = false
			var victory: Array[Dictionary] = [{"text": "Incidencia resuelta. Casi había olvidado esa sensación.", "expression": "core9_expression_1_06"}]
			dialogue.call("start_conversation", "incident_resolved", victory, player, true, true, 5.0)
		elif player.global_position.x >= 410.0 and player.global_position.x < 560.0 and not bool(progress.call("dialogue_completed", "movement_detected")) and int(player.get("invulnerability_frames_remaining")) == 0:
			var warning: Array[Dictionary] = [{"text": "Movimiento detectado. No parece venir a arreglar nada.", "expression": "core9_expression_1_04"}]
			dialogue.call("start_conversation", "movement_detected", warning, player, true, true, 5.0)
