extends "res://scripts/rooms/room2.gd"

const WORLD_SIZE: Vector2 = Vector2(1280.0, 720.0)
enum EncounterState { INACTIVE, INTRO, ACTIVE, PLAYER_DEFEATED, BOSS_DEFEATED }
signal encounter_state_changed(current: EncounterState)
@export var encounter_activation_enabled: bool = true
var encounter_state: EncounterState = EncounterState.INACTIVE
var encounter_initialized: bool = false
var encounter_activation_count: int = 0
var encounter_cycle_starts: int = 0
var encounter_trigger_used: bool = false
var exit_blocked: bool = false
var access_hint: Node
const VICTORY_SAVE_MAX_ATTEMPTS: int = 2
const VICTORY_SAVE_RETRY_DELAY: float = 1.0
var room_cleared: bool = false
var victory_persisted: bool = false
var victory_save_attempts: int = 0
var victory_retry_remaining: float = 0.0

@onready var room_camera: Camera2D = $Player/Camera2D
var guardian_hint: Node
var guardian_hint_message: String = ""
signal fall_recovered
var fall_recovery_count: int = 0


func _physics_process(_delta: float) -> void:
	if player.health <= 0 or player.position.y + 20.0 < 690.0:
		return
	# Local void recovery, following Room4; never alter health or boss progression.
	player.position = $EntryMarkers/Spawn.position
	player.velocity = Vector2.ZERO
	$DimensionManager.restore_present_at_checkpoint()
	room_camera.reset_smoothing()
	room_camera.force_update_scroll()
	fall_recovery_count += 1
	fall_recovered.emit()


func _ready() -> void:
	player.velocity = Vector2.ZERO
	(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h = false
	super._ready()
	(player.get_node("AnimatedSprite2D") as AnimatedSprite2D).flip_h = false
	# Reuse the Player camera, but frame the arena independently of its movement.
	room_camera.top_level = true
	room_camera.position = WORLD_SIZE * 0.5
	room_camera.position_smoothing_enabled = false
	room_camera.limit_left = 0
	room_camera.limit_top = 0
	room_camera.limit_right = int(WORLD_SIZE.x)
	room_camera.limit_bottom = int(WORLD_SIZE.y)
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()
	room_cleared = get_node("/root/GameProgress").core_guardian_defeated
	victory_persisted = room_cleared
	# Local instance of the existing hint control; no shared HUD or scene edits.
	guardian_hint = load("res://scenes/ui/TutorialHints.tscn").instantiate()
	guardian_hint.name = "GuardianHint"
	add_child(guardian_hint)
	$CoreGuardian.state_changed.connect(_refresh_guardian_hint)
	_refresh_guardian_hint()
	var boss_hud: Node = load("res://scenes/ui/BossHUD.tscn").instantiate()
	boss_hud.name = "BossHUD"
	add_child(boss_hud)
	if not room_cleared:
		boss_hud.call("bind_guardian",$CoreGuardian)
	# Explicit isolated-test mode; production defaults to the physical trigger.
	if OS.get_cmdline_user_args().has("--room5-manual-diagnostic"):
		encounter_activation_enabled = false
	access_hint = load("res://scenes/ui/TutorialHints.tscn").instantiate()
	access_hint.name = "ExitBlockHint"
	add_child(access_hint)
	$EncounterTrigger.body_entered.connect(_on_encounter_entered)
	$CoreGuardian.state_changed.connect(_on_encounter_boss_state)
	$CoreGuardian.defeated.connect(_on_encounter_boss_defeated)
	if room_cleared:
		_initialize_cleared_arena()
	var final_access: Node = load("res://scenes/ending/FinalAccessDoor.tscn").instantiate()
	add_child(final_access)
	call_deferred("_arm_encounter")


func _process(delta: float) -> void:
	# Read confirmed state for presentation, without adding observers to shared systems.
	if is_instance_valid(guardian_hint):
		_refresh_guardian_hint()
	if encounter_activation_enabled:
		if encounter_state == EncounterState.BOSS_DEFEATED and exit_blocked:
			if not $CoreGuardian.sprite.is_playing() and $BossHUD.destruction_completed:
				_set_exit_blocked(false)
		if encounter_state == EncounterState.BOSS_DEFEATED and victory_retry_remaining > 0.0:
			victory_retry_remaining = maxf(0.0, victory_retry_remaining - delta)
			if victory_retry_remaining == 0.0:
				_try_persist_victory()
		_refresh_access_hint()


func _refresh_guardian_hint(_value: Variant = null) -> void:
	var guardian: Node = get_node_or_null("CoreGuardian")
	var message: String = "" if guardian == null else String(guardian.call("guardian_hint_text"))
	if room_cleared:
		message = ""
	if encounter_activation_enabled:
		if encounter_state == EncounterState.INTRO:
			message = "GUARDIÁN INICIALIZÁNDOSE\nACCESO BLOQUEADO — qué hospitalidad."
		elif encounter_state in [EncounterState.PLAYER_DEFEATED,EncounterState.BOSS_DEFEATED]:
			message = ""
	if message == guardian_hint_message:
		return
	guardian_hint_message = message
	if message.is_empty():
		guardian_hint.call("hide_hint")
	else:
		# TutorialHints updates text on a new id; retain the same id while unchanged.
		guardian_hint.call("show_hint", "guardian_status:" + message, message, Vector2(640,260))


func _fit_camera() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var factor: float = maxf(viewport_size.x / WORLD_SIZE.x, viewport_size.y / WORLD_SIZE.y)
	room_camera.zoom = Vector2.ONE * factor
	room_camera.position = WORLD_SIZE * 0.5
	room_camera.reset_smoothing()
	room_camera.force_update_scroll()


func _arm_encounter() -> void:
	encounter_initialized = true
	if encounter_activation_enabled and not room_cleared and not encounter_trigger_used:
		$EncounterTrigger.set_deferred("monitoring", true)


func _on_encounter_entered(body: Node2D) -> void:
	var guardian: Node2D = $CoreGuardian
	var exit_area: Area2D = $RoomTransitions/ToRoom4
	if not encounter_activation_enabled or room_cleared or not encounter_initialized or encounter_trigger_used or encounter_state != EncounterState.INACTIVE:
		return
	if body != player or player.health <= 0 or restart_pending or guardian.health <= 0 or get_tree().current_scene != self or exit_area.transition_pending:
		return
	if guardian.cycle_running or guardian.state != guardian.State.IDLE:
		return
	encounter_trigger_used = true
	encounter_activation_count += 1
	$EncounterTrigger.set_deferred("monitoring",false)
	_set_exit_blocked(true)
	_set_encounter_state(EncounterState.INTRO)
	if not guardian.play_diagnostic(&"starting"):
		cancel_encounter()


func _on_encounter_boss_state(value: int) -> void:
	if not encounter_activation_enabled:
		return
	var guardian: Node2D = $CoreGuardian
	# IDLE is emitted by the existing animation-finished handler after Starting.
	if encounter_state == EncounterState.INTRO and value == guardian.State.IDLE:
		if player.health <= 0 or restart_pending or guardian.health <= 0:
			return
		_set_encounter_state(EncounterState.ACTIVE)
		if guardian.start_combat_cycle():
			encounter_cycle_starts += 1
		else:
			cancel_encounter()
	elif encounter_state == EncounterState.ACTIVE and not guardian.cycle_running and guardian.health > 0 and player.health > 0:
		cancel_encounter()


func _set_encounter_state(value: EncounterState) -> void:
	if encounter_state == value:
		return
	encounter_state = value
	encounter_state_changed.emit(value)
	_refresh_guardian_hint()


func _set_exit_blocked(blocked: bool) -> void:
	exit_blocked = blocked
	var exit_area: Area2D = $RoomTransitions/ToRoom4
	var callback: Callable = Callable(exit_area,"_on_body_entered")
	# Disconnect locally as well as disabling monitoring: queued body events cannot
	# dispatch the shared transition while INTRO/ACTIVE owns the encounter.
	if blocked and exit_area.is_connected("body_entered",callback):
		exit_area.disconnect("body_entered",callback)
	elif not blocked and not exit_area.is_connected("body_entered",callback):
		exit_area.connect("body_entered",callback)
	exit_area.set_deferred("monitoring",not blocked)
	_refresh_access_hint()


func _refresh_access_hint() -> void:
	if not is_instance_valid(access_hint):
		return
	if encounter_state == EncounterState.BOSS_DEFEATED and not victory_persisted and victory_save_attempts > 0:
		var warning: String = "VICTORIA LOCAL — NO SE PUDO GUARDAR.\nLa memoria también tiene días inútiles."
		access_hint.call("show_hint","victory_save_failed",warning,Vector2(640,260))
		return
	if exit_blocked and player.health > 0 and player.position.x < 280:
		var message: String = "ACCESO BLOQUEADO — GUARDIÁN ACTIVO" if encounter_state != EncounterState.BOSS_DEFEATED else "ACCESO BLOQUEADO — SISTEMA REINICIANDO"
		access_hint.call("show_hint",message,message,Vector2(215,400))
	else:
		access_hint.call("hide_hint")


func cancel_encounter() -> void:
	# An interrupted attempt stays passive and may leave; a fresh scene rearms it.
	_set_encounter_state(EncounterState.INACTIVE)
	var guardian: Node = get_node_or_null("CoreGuardian")
	if guardian != null and (guardian.cycle_running or guardian.state == guardian.State.INTRO):
		guardian.call("stop_combat_cycle")
	_set_exit_blocked(false)
	$EncounterTrigger.set_deferred("monitoring",false)


func _on_player_defeated() -> void:
	if restart_pending:
		return
	if encounter_activation_enabled:
		_set_encounter_state(EncounterState.PLAYER_DEFEATED)
		$EncounterTrigger.set_deferred("monitoring",false)
		_set_exit_blocked(false)
		# The boss handles lethal projectile contact before freeing its packet.
		# Defer this local cleanup until that collision callback has returned.
		call_deferred("_stop_defeated_encounter")
	# Reuse the inherited defeat animation and automatic local scene reload.
	await super._on_player_defeated()


func _stop_defeated_encounter() -> void:
	var guardian: Node = get_node_or_null("CoreGuardian")
	if guardian != null:
		guardian.call("stop_combat_cycle")


func _on_encounter_boss_defeated() -> void:
	if encounter_activation_enabled and encounter_state in [EncounterState.INTRO,EncounterState.ACTIVE]:
		var guardian: Node2D = $CoreGuardian
		if guardian.health != 0 or guardian.state != guardian.State.DEFEATED:
			return
		var legitimate_victory: bool = encounter_state == EncounterState.ACTIVE and encounter_activation_count == 1 and encounter_cycle_starts == 1 and encounter_trigger_used and guardian.health == 0 and guardian.state == guardian.State.DEFEATED and player.health > 0 and not restart_pending and get_tree().current_scene == self and not $RoomTransitions/ToRoom4.transition_pending
		_set_encounter_state(EncounterState.BOSS_DEFEATED)
		$EncounterTrigger.set_deferred("monitoring",false)
		if legitimate_victory:
			_try_persist_victory()


func _try_persist_victory() -> void:
	if victory_persisted or victory_save_attempts >= VICTORY_SAVE_MAX_ATTEMPTS or encounter_state != EncounterState.BOSS_DEFEATED or get_tree().current_scene != self:
		return
	victory_save_attempts += 1
	victory_persisted = get_node("/root/GameProgress").record_core_guardian_victory()
	if not victory_persisted:
		push_warning("C.O.R.E.-9: Victoria local sin guardar; intento %d/%d. El disco exige otra auditoría." % [victory_save_attempts,VICTORY_SAVE_MAX_ATTEMPTS])
		if victory_save_attempts < VICTORY_SAVE_MAX_ATTEMPTS:
			victory_retry_remaining = VICTORY_SAVE_RETRY_DELAY
	_refresh_access_hint()


func _initialize_cleared_arena() -> void:
	# Keep structural nodes; do not replay defeat or alter the boss state machine.
	encounter_state = EncounterState.BOSS_DEFEATED
	var guardian: Node2D = $CoreGuardian
	guardian.hide()
	guardian.process_mode = Node.PROCESS_MODE_DISABLED
	guardian.sprite.pause()
	guardian.weakpoint.set_deferred("monitorable",false)
	guardian.weakpoint.set_deferred("monitoring",false)
	guardian.weakpoint.set_deferred("collision_layer",0)
	guardian.core_shape.set_deferred("disabled",true)
	$EncounterTrigger.set_deferred("monitoring",false)
	_refresh_guardian_hint()
