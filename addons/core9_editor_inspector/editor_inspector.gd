@tool
extends EditorPlugin
## Fixed authenticated protocol. Mutations use validated EditorUndoRedoManager actions.

const FramesDiagnostic = preload("res://addons/core9_editor_inspector/player_frames_diagnostic.gd")
const Operations = preload("res://addons/core9_editor_inspector/editor_operations.gd")

const PORT: int = 6008
const MAX_REQUEST_BYTES: int = 8192
const MAX_SCAN_NODES: int = 5000
const METHODS: Array[String] = ["editor_get_state", "editor_get_scene_tree", "editor_get_selection", "editor_inspect_node", "editor_diagnose_player_frames"]

var _server: TCPServer = TCPServer.new()
var _clients: Array[Dictionary] = []
var _token: String = ""
var _project_path: String = ""
var _operations: Operations = Operations.new()
var _frames_diagnostic: FramesDiagnostic = FramesDiagnostic.new()


func _enter_tree() -> void:
	if _operations == null:
		_operations = Operations.new()
	if _frames_diagnostic == null:
		_frames_diagnostic = FramesDiagnostic.new()
	_operations.setup(self)
	var credential_path: String = OS.get_environment("LOCALAPPDATA").path_join("GodotMCPCodex/private/core-9.json")
	if not FileAccess.file_exists(credential_path):
		push_warning("C.O.R.E.-9: Inspector sin credencial privada. Observar tambien requiere burocracia.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(credential_path))
	if not parsed is Dictionary:
		return
	var credential: Dictionary = parsed
	_token = str(credential.get("token", ""))
	_project_path = _normalize_path(str(credential.get("project_path", "")))
	if _token.length() != 64 or _project_path != _normalize_path(ProjectSettings.globalize_path("res://")):
		_token = ""
		push_warning("C.O.R.E.-9: Inspector fuera de su proyecto. La privacidad sobrevive, por una vez.")
		return
	var listen_error: Error = _server.listen(PORT, "127.0.0.1")
	if listen_error != OK:
		push_warning("C.O.R.E.-9: Puerto 6008 ocupado. No invadire otra ruina.")


func _exit_tree() -> void:
	for client: Dictionary in _clients:
		var peer: StreamPeerTCP = client["peer"]
		peer.disconnect_from_host()
	_clients.clear()
	_server.stop()
	_token = ""


func _process(_delta: float) -> void:
	if not _server.is_listening():
		return
	# Script hot reload can leave newly added instance fields null on an existing plugin.
	if _frames_diagnostic == null:
		_frames_diagnostic = FramesDiagnostic.new()
	var cleanup: Dictionary = _frames_diagnostic.process_authorized_cleanup()
	if not cleanup.is_empty():
		cleanup["save_protection_after"] = _operations._audit_external_resources()
		_frames_diagnostic.write_cleanup_evidence(cleanup)
	while _server.is_connection_available():
		var peer: StreamPeerTCP = _server.take_connection()
		if _clients.size() >= 4:
			peer.disconnect_from_host()
		else:
			_clients.append({"peer": peer, "buffer": PackedByteArray(), "started": Time.get_ticks_msec()})
	for index: int in range(_clients.size() - 1, -1, -1):
		var client: Dictionary = _clients[index]
		var peer: StreamPeerTCP = client["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or Time.get_ticks_msec() - int(client["started"]) > 4000:
			peer.disconnect_from_host()
			_clients.remove_at(index)
			continue
		if client.has("outgoing"):
			var outgoing: PackedByteArray = client["outgoing"]
			var sent: int = int(client["sent"])
			var partial: Array = peer.put_partial_data(outgoing.slice(sent))
			client["sent"] = sent + int(partial[1])
			if int(partial[0]) != OK or int(client["sent"]) >= outgoing.size():
				peer.disconnect_from_host()
				_clients.remove_at(index)
			continue
		var available: int = peer.get_available_bytes()
		if available == 0:
			continue
		var buffer: PackedByteArray = client["buffer"]
		if buffer.size() + available > MAX_REQUEST_BYTES:
			peer.disconnect_from_host()
			_clients.remove_at(index)
			continue
		var incoming: Array = peer.get_data(available)
		if int(incoming[0]) != OK:
			peer.disconnect_from_host()
			_clients.remove_at(index)
			continue
		buffer.append_array(incoming[1])
		client["buffer"] = buffer
		var newline: int = buffer.find(10)
		if newline < 0:
			continue
		var request: Variant = JSON.parse_string(buffer.slice(0, newline).get_string_from_utf8())
		var response: Dictionary = _handle_request(request)
		var encoded: PackedByteArray = (JSON.stringify(response) + "\n").to_utf8_buffer()
		if encoded.size() > 524288:
			encoded = (JSON.stringify(_failure("RESPONSE_TOO_LARGE")) + "\n").to_utf8_buffer()
		client["outgoing"] = encoded
		client["sent"] = 0


func _normalize_path(value: String) -> String:
	return value.replace("\\", "/").trim_suffix("/").to_lower()


func _failure(code: String) -> Dictionary:
	return {"ok": false, "error": code}


func _handle_request(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _failure("INVALID_REQUEST")
	var request: Dictionary = value
	if not request.get("token") is String or str(request["token"]).sha256_text() != _token.sha256_text():
		return _failure("UNAUTHORIZED")
	if _normalize_path(str(request.get("project_path", ""))) != _project_path:
		return _failure("WRONG_PROJECT")
	var method: String = str(request.get("method", ""))
	if not method in METHODS and not method in Operations.METHODS:
		return _failure("METHOD_NOT_ALLOWED")
	if not request.get("params", {}) is Dictionary:
		return _failure("INVALID_PARAMS")
	var params: Dictionary = request.get("params", {})
	if method in Operations.METHODS:
		var operation_result: Dictionary = _operations.execute(method, params, EditorInterface.get_edited_scene_root())
		operation_result["state"] = _state(EditorInterface.get_edited_scene_root())
		return {"ok": true, "result": operation_result}
	if not _valid_params(method, params):
		return _failure("INVALID_PARAMS")
	if params.get("source", "editor") != "editor":
		return _failure("REMOTE_TREE_NOT_SUPPORTED")
	var root: Node = EditorInterface.get_edited_scene_root()
	var state: Dictionary = _state(root)
	if params.has("expected_scene_id") and str(params["expected_scene_id"]) != str(state["scene_id"]):
		return _failure("ACTIVE_SCENE_CHANGED")
	var result: Dictionary
	match method:
		"editor_diagnose_player_frames":
			if _frames_diagnostic == null:
				return _failure("DIAGNOSTIC_NOT_INITIALIZED")
			result = _frames_diagnostic.compare()
			result["save_protection_audit"] = _operations._audit_external_resources()
			result["state"] = state
		"editor_get_state":
			result = state
		"editor_get_selection":
			result = _selection(root, state)
		"editor_get_scene_tree":
			if root == null:
				return _failure("NO_EDITED_SCENE")
			result = _scene_tree(root, state, params)
		"editor_inspect_node":
			if root == null:
				return _failure("NO_EDITED_SCENE")
			result = _inspect(root, state, params)
	return {"ok": true, "result": result}


func _valid_params(method: String, params: Dictionary) -> bool:
	var allowed: Array[String] = ["source", "expected_scene_id"]
	if method in ["editor_get_scene_tree", "editor_inspect_node"]:
		allowed.append("node_path")
	if method == "editor_get_scene_tree":
		allowed.append_array(["max_nodes", "max_depth", "offset", "include_internal"])
	for key: Variant in params:
		if not key is String or not key in allowed:
			return false
		var value: Variant = params[key]
		if key in ["source", "expected_scene_id", "node_path"]:
			if not value is String or str(value).length() > 1024:
				return false
		elif key == "include_internal":
			if not value is bool:
				return false
		else:
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) != floorf(float(value)):
				return false
			var maximum: int = 200 if key == "max_nodes" else (64 if key == "max_depth" else MAX_SCAN_NODES)
			if int(value) < (1 if key == "max_nodes" else 0) or int(value) > maximum:
				return false
	return true


func _state(root: Node) -> Dictionary:
	var scene_path: String = root.scene_file_path if root != null else ""
	var unsaved: Variant = null
	if EditorInterface.has_method("get_unsaved_scenes"):
		unsaved = scene_path in EditorInterface.get_unsaved_scenes() if scene_path != "" else root != null
	return {"source": "editor", "remote_supported": false, "protocol_version": 4, "project_path": _project_path, "scene_path": scene_path, "scene_id": str(root.get_instance_id()) if root != null else "", "scene_revision": _operations.scene_revision(root), "scene_name": str(root.name) if root != null else "", "unsaved": unsaved, "playing": EditorInterface.is_playing_scene(), "captured_msec": Time.get_ticks_msec()}


func _node_info(node: Node, root: Node) -> Dictionary:
	var script_resource: Script = node.get_script() as Script
	return {"name": str(node.name), "type": node.get_class(), "path": str(root.get_path_to(node)), "scene_file_path": node.scene_file_path, "instance_child": node != root and node.owner != root, "script_path": script_resource.resource_path if script_resource != null else ""}


func _selection(root: Node, state: Dictionary) -> Dictionary:
	var entries: Array[Dictionary] = []
	var total: int = 0
	for node: Node in EditorInterface.get_selection().get_selected_nodes():
		if root != null and (node == root or root.is_ancestor_of(node)):
			total += 1
			if entries.size() < 20:
				entries.append(_node_info(node, root))
	return {"state": state, "nodes": entries, "total_selected": total, "truncated": total > entries.size()}


func _resolve_node(root: Node, path: String) -> Node:
	if path.begins_with("/") or ":" in path or ".." in path.split("/"):
		return null
	var node: Node = root if path == "." else root.get_node_or_null(NodePath(path))
	if node != null and (node == root or root.is_ancestor_of(node)):
		return node
	return null


func _scene_tree(root: Node, state: Dictionary, params: Dictionary) -> Dictionary:
	var start: Node = _resolve_node(root, str(params.get("node_path", ".")))
	if start == null:
		return {"error": "NODE_NOT_FOUND", "state": state}
	var max_nodes: int = clampi(int(params.get("max_nodes", 80)), 1, 200)
	var max_depth: int = clampi(int(params.get("max_depth", 32)), 0, 64)
	var offset: int = clampi(int(params.get("offset", 0)), 0, MAX_SCAN_NODES)
	var include_internal: bool = bool(params.get("include_internal", false))
	var stack: Array[Dictionary] = [{"node": start, "depth": 0}]
	var nodes: Array[Dictionary] = []
	var visited: int = 0
	var depth_limited: bool = false
	while not stack.is_empty() and visited < MAX_SCAN_NODES:
		var item: Dictionary = stack.pop_back()
		var node: Node = item["node"]
		var depth: int = int(item["depth"])
		if visited >= offset and nodes.size() < max_nodes:
			var info: Dictionary = _node_info(node, root)
			info["depth"] = depth
			nodes.append(info)
		visited += 1
		var children: Array[Node] = node.get_children(include_internal)
		if depth >= max_depth:
			depth_limited = depth_limited or not children.is_empty()
			continue
		for index: int in range(children.size() - 1, -1, -1):
			stack.append({"node": children[index], "depth": depth + 1})
	var next_offset: Variant = offset + nodes.size() if offset + nodes.size() < visited else null
	return {"state": state, "nodes": nodes, "offset": offset, "next_offset": next_offset, "total_in_depth_limit": visited, "depth_limited": depth_limited, "scan_limited": not stack.is_empty(), "includes_instanced_children": true, "include_internal": include_internal}


func _safe_value(value: Variant, root: Node) -> Variant:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT:
			return value
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			return str(value).left(256)
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return {"type": type_string(typeof(value)), "x": value.x, "y": value.y}
		TYPE_RECT2, TYPE_RECT2I:
			return {"type": type_string(typeof(value)), "position": _safe_value(value.position, root), "size": _safe_value(value.size, root)}
		TYPE_COLOR:
			return {"type": "Color", "r": value.r, "g": value.g, "b": value.b, "a": value.a}
		TYPE_OBJECT:
			if value is Node:
				return {"type": value.get_class(), "path": str(root.get_path_to(value)) if value == root or root.is_ancestor_of(value) else "OUTSIDE_EDITED_SCENE"}
			if value is Resource:
				return {"type": value.get_class(), "resource_path": value.resource_path}
	return {"type": type_string(typeof(value)), "value_omitted": true}


func _inspect(root: Node, state: Dictionary, params: Dictionary) -> Dictionary:
	var node: Node = _resolve_node(root, str(params.get("node_path", ".")))
	if node == null:
		return {"error": "NODE_NOT_FOUND", "state": state}
	var properties: Dictionary = {}
	# Explicit native fields only: never enumerate custom getters or evaluate code.
	if node is Node2D:
		properties["position"] = _safe_value(node.position, root)
		properties["rotation"] = node.rotation
		properties["scale"] = _safe_value(node.scale, root)
	if node is CanvasItem:
		properties["visible"] = node.visible
		properties["modulate"] = _safe_value(node.modulate, root)
		properties["z_index"] = node.z_index
	if node is Control:
		properties["position"] = _safe_value(node.position, root)
		properties["size"] = _safe_value(node.size, root)
		properties["mouse_filter"] = node.mouse_filter
	if node is CollisionObject2D:
		properties["collision_layer"] = node.collision_layer
		properties["collision_mask"] = node.collision_mask
	if node is CollisionShape2D:
		properties["disabled"] = node.disabled
		properties["shape"] = _safe_value(node.shape, root)
	if node is Sprite2D:
		properties["texture"] = _safe_value(node.texture, root)
		properties["centered"] = node.centered
	if node is AnimatedSprite2D:
		properties["animation"] = str(node.animation)
		properties["frame"] = node.frame
		properties["sprite_frames"] = _safe_value(node.sprite_frames, root)
	if node is TileMapLayer:
		properties["collision_enabled"] = node.collision_enabled
		properties["tile_set"] = _safe_value(node.tile_set, root)
	if node is Camera2D:
		properties["zoom"] = _safe_value(node.zoom, root)
	var signals: Array[Dictionary] = []
	var signal_list: Array[Dictionary] = node.get_signal_list()
	for entry: Dictionary in signal_list:
		if signals.size() >= 32:
			break
		var signal_name: StringName = entry["name"]
		var connections: Array[Dictionary] = []
		var connection_list: Array[Dictionary] = node.get_signal_connection_list(signal_name)
		for connection: Dictionary in connection_list:
			if connections.size() >= 8:
				break
			var target: Callable = connection["callable"]
			connections.append({"method": str(target.get_method()), "target": _safe_value(target.get_object(), root), "flags": int(connection["flags"])})
		signals.append({"name": str(signal_name), "connections": connections, "connections_truncated": connection_list.size() > connections.size()})
	var groups: Array[String] = []
	for group: StringName in node.get_groups():
		if not str(group).begins_with("_") and groups.size() < 32:
			groups.append(str(group))
	return {"state": state, "node": _node_info(node, root), "properties": properties, "property_scope": "native_allowlist; custom getters and resource contents omitted", "groups": groups, "signals": signals, "signals_truncated": signal_list.size() > signals.size()}
