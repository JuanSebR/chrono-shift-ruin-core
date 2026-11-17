@tool
extends RefCounted
## Closed editor operations. No expression evaluator, arbitrary method dispatcher or file writer.

const NODE_TYPES: Array[String] = ["Node", "Node2D", "Marker2D", "Sprite2D", "AnimatedSprite2D", "Camera2D", "CharacterBody2D", "StaticBody2D", "RigidBody2D", "Area2D", "CollisionShape2D", "CollisionPolygon2D", "Control", "ColorRect", "Label", "Button", "TextureRect", "CanvasLayer", "Timer", "AudioStreamPlayer", "AudioStreamPlayer2D", "TileMapLayer", "Parallax2D"]
const METHODS: Array[String] = ["editor_create_node", "editor_set_properties", "editor_rename_node", "editor_reparent_node", "editor_delete_node", "editor_assign_resource", "editor_connect_signal", "editor_disconnect_signal", "editor_undo", "editor_redo", "editor_save_scene", "editor_open_scene", "editor_reload_scene", "editor_get_viewport_preview"]

var plugin: EditorPlugin
var revision: int = 0
var epoch: String = str(Time.get_ticks_usec())


func setup(value: EditorPlugin) -> void:
	plugin = value
	plugin.get_undo_redo().version_changed.connect(_version_changed)


func _version_changed() -> void:
	revision += 1


func scene_revision(root: Node) -> String:
	if root == null:
		return epoch + ":none"
	var manager: EditorUndoRedoManager = plugin.get_undo_redo()
	var history: UndoRedo = manager.get_history_undo_redo(manager.get_object_history_id(root))
	return "%s:%d:%d" % [epoch, revision, history.get_version()]


func _error(code: String) -> Dictionary:
	return {"error": code}


func execute(method: String, params: Dictionary, root: Node) -> Dictionary:
	if not _valid_params(method, params):
		return _error("INVALID_OPERATION_PARAMS")
	if method == "editor_get_viewport_preview":
		var image: Image = EditorInterface.get_editor_viewport_2d().get_texture().get_image()
		if image == null or image.is_empty():
			return _error("VIEWPORT_NOT_READY")
		image.resize(640, maxi(1, int(image.get_height() * 640.0 / image.get_width())))
		return {"preview_jpeg": Marshalls.raw_to_base64(image.save_jpg_to_buffer(0.8)), "width": image.get_width(), "height": image.get_height()}
	if root == null:
		return _error("NO_EDITED_SCENE")
	if str(params.get("expected_scene_id", "")) != str(root.get_instance_id()):
		return _error("ACTIVE_SCENE_CHANGED")
	if str(params.get("expected_revision", "")) != scene_revision(root):
		return _error("SCENE_REVISION_CHANGED")
	if EditorInterface.is_playing_scene():
		return _error("STOP_GAME_BEFORE_EDITING")
	if method == "editor_reload_scene":
		if root.scene_file_path == "" or root.scene_file_path in EditorInterface.get_unsaved_scenes() or not safe_path(root.scene_file_path, ["tscn"]):
			return _error("RELOAD_REQUIRES_SAVED_PROJECT_SCENE")
		EditorInterface.reload_scene_from_path(root.scene_file_path)
		return {"reloaded": true}
	if method == "editor_open_scene":
		var scene_path: String = str(params.get("scene_path", ""))
		if not safe_path(scene_path, ["tscn"]):
			return _error("SCENE_PATH_NOT_ALLOWED")
		if root.scene_file_path == "" or root.scene_file_path in EditorInterface.get_unsaved_scenes():
			return _error("SAVE_OR_DISCARD_CURRENT_SCENE_FIRST")
		EditorInterface.open_scene_from_path(scene_path)
		return {"opened_scene": scene_path}
	if method == "editor_save_scene":
		if str(params.get("scene_path", "")) != root.scene_file_path or not safe_path(root.scene_file_path, ["tscn"]):
			return _error("SAVE_PATH_MUST_MATCH_ACTIVE_SCENE")
		var audit: Dictionary = _audit_external_resources()
		if audit.has("error"):
			return audit
		var save_error: Error = EditorInterface.save_scene()
		return {"saved_scene": root.scene_file_path, "sha256": FileAccess.get_sha256(root.scene_file_path)} if save_error == OK else _error("EDITOR_SAVE_FAILED_%d" % save_error)
	if method in ["editor_undo", "editor_redo"]:
		return _history_action(method, root)
	var node: Node = _node(root, str(params.get("node_path", ".")))
	if method == "editor_create_node":
		return _create(params, root)
	if node == null:
		return _error("NODE_NOT_FOUND")
	if not _editable(node, root):
		return _error("INSTANCE_INTERNAL_OR_TOOL_SCRIPT_READ_ONLY")
	match method:
		"editor_set_properties":
			return _properties(node, params, root)
		"editor_rename_node", "editor_reparent_node", "editor_delete_node":
			return _structure(method, node, params, root)
		"editor_assign_resource":
			return _assign(node, params, root)
		"editor_connect_signal", "editor_disconnect_signal":
			return _signal_action(method, node, params, root)
	return _error("OPERATION_NOT_ALLOWED")


func _audit_external_resources() -> Dictionary:
	# Native scene saving also saves dirty external cached resources. Refuse first.
	if not EditorInterface.has_method("is_object_edited"):
		return _error("SAFE_SAVE_REQUIRES_RESOURCE_EDITED_API")
	var directories: Array[String] = ["res://"]
	var resources: Array[Resource] = []
	var seen: Dictionary = {}
	var scanned: int = 0
	while not directories.is_empty():
		var directory_path: String = directories.pop_back()
		var directory: DirAccess = DirAccess.open(directory_path)
		if directory == null:
			return _error("SAVE_RESOURCE_AUDIT_FAILED")
		for name: String in directory.get_directories():
			if name.begins_with("."):
				continue
			if directory.is_link(name):
				return _error("SAVE_RESOURCE_AUDIT_REFUSES_LINKS")
			directories.append(directory_path.path_join(name))
		for name: String in directory.get_files():
			scanned += 1
			if scanned > 20000:
				return _error("SAVE_RESOURCE_AUDIT_TOO_LARGE")
			var path: String = directory_path.path_join(name)
			if ResourceLoader.has_cached(path):
				if directory.is_link(name):
					return _error("SAVE_RESOURCE_AUDIT_REFUSES_LINKS")
				resources.append(ResourceLoader.get_cached_ref(path))
	while not resources.is_empty():
		var resource: Resource = resources.pop_back()
		if resource == null or seen.has(resource.get_instance_id()):
			continue
		seen[resource.get_instance_id()] = true
		if seen.size() > 20000:
			return _error("SAVE_RESOURCE_AUDIT_TOO_LARGE")
		if resource.get_script() != null:
			return _error("SAVE_SCRIPTED_RESOURCE_REQUIRES_MANUAL_REVIEW")
		if not resource is PackedScene and resource.resource_path.begins_with("res://") and EditorInterface.is_object_edited(resource):
			return {"error": "EXTERNAL_RESOURCE_HAS_UNSAVED_CHANGES", "resource_path": resource.resource_path.get_slice("::", 0)}
		for property: Dictionary in resource.get_property_list():
			if (int(property["usage"]) & PROPERTY_USAGE_STORAGE) == 0 or not int(property["type"]) in [TYPE_OBJECT, TYPE_ARRAY, TYPE_DICTIONARY]:
				continue
			var nested: Array[Variant] = [resource.get(property["name"])]
			var count: int = 0
			while not nested.is_empty():
				count += 1
				if count > 20000:
					return _error("SAVE_RESOURCE_AUDIT_TOO_LARGE")
				var value: Variant = nested.pop_back()
				if value is Resource:
					resources.append(value)
				elif value is Array:
					nested.append_array(value)
				elif value is Dictionary:
					nested.append_array(value.values())
	return {"external_resources_clean": true}


func _valid_params(method: String, params: Dictionary) -> bool:
	var fields: Dictionary = {
		"editor_create_node": ["parent_path", "name", "node_type", "properties"],
		"editor_set_properties": ["node_path", "properties"],
		"editor_rename_node": ["node_path", "name"],
		"editor_reparent_node": ["node_path", "parent_path", "index", "keep_global_transform"],
		"editor_delete_node": ["node_path", "confirm_subtree"],
		"editor_assign_resource": ["node_path", "property", "resource_path"],
		"editor_connect_signal": ["node_path", "signal", "target_path", "method"],
		"editor_disconnect_signal": ["node_path", "signal", "target_path", "method"],
		"editor_save_scene": ["scene_path"], "editor_open_scene": ["scene_path"],
		"editor_undo": [], "editor_redo": [], "editor_reload_scene": [], "editor_get_viewport_preview": []}
	if not fields.has(method):
		return false
	var allowed: Array = fields[method] + ["expected_scene_id", "expected_revision"]
	for key: Variant in params:
		if not key is String or not key in allowed:
			return false
		if key == "properties":
			if not params[key] is Dictionary:
				return false
		elif key in ["keep_global_transform", "confirm_subtree"]:
			if not params[key] is bool:
				return false
		elif key == "index":
			if not _number(params[key]) or float(params[key]) != floorf(float(params[key])):
				return false
		elif not params[key] is String or str(params[key]).length() > 1024:
			return false
	return true


func safe_path(path: String, extensions: Array[String]) -> bool:
	if not path.begins_with("res://") or path.contains("\\") or path.contains("::"):
		return false
	var relative: String = path.trim_prefix("res://")
	if relative.simplify_path() != relative or relative.split("/").has("..") or relative.split("/").has(".") or relative.contains(":"):
		return false
	if relative.split("/")[0] in [".godot", ".codex", "addons"] or not relative.get_extension().to_lower() in extensions:
		return false
	var current: String = ProjectSettings.globalize_path("res://")
	var directory: DirAccess = DirAccess.open("res://")
	for part: String in relative.split("/"):
		current = current.path_join(part)
		if directory.is_link(current):
			return false
	return FileAccess.file_exists(path)


func _node(root: Node, path: String) -> Node:
	if path == "" or path.begins_with("/") or path.contains(":") or path.contains("\\") or path.split("/").has(".."):
		return null
	var found: Node = root if path == "." else root.get_node_or_null(NodePath(path))
	return found if found != null and (found == root or root.is_ancestor_of(found)) else null


func _editable(node: Node, root: Node) -> bool:
	var script_resource: Script = node.get_script() as Script
	return (node == root or node.owner == root) and (script_resource == null or not script_resource.is_tool())


func _name_ok(value: String) -> bool:
	return not value.is_empty() and value.length() <= 80 and value.validate_node_name() == value and not value.contains("\\") and not value.begins_with("@")


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	var cursor: int = 0
	while cursor < nodes.size() and nodes.size() < 5001:
		nodes.append_array(nodes[cursor].get_children())
		cursor += 1
	return nodes


func _begin(label: String, root: Node) -> EditorUndoRedoManager:
	var manager: EditorUndoRedoManager = plugin.get_undo_redo()
	manager.create_action("MCP: " + label, UndoRedo.MERGE_DISABLE, root)
	return manager


func _set_values(node: Node, values: Dictionary) -> void:
	for key: String in values:
		node.set(key, values[key])


func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and absf(float(value)) <= 1000000000.0


func _convert(value: Variant, expected: int) -> Dictionary:
	if expected == TYPE_BOOL and value is bool:
		return {"value": value}
	if expected == TYPE_STRING and value is String and str(value).length() <= 2048:
		return {"value": value}
	if expected == TYPE_FLOAT and _number(value):
		return {"value": float(value)}
	if expected == TYPE_INT and _number(value) and float(value) == floorf(float(value)):
		return {"value": int(value)}
	if not value is Dictionary:
		return _error("PROPERTY_TYPE_MISMATCH")
	var data: Dictionary = value
	if expected == TYPE_VECTOR2 and data.get("type") == "Vector2" and data.size() == 3 and _number(data.get("x")) and _number(data.get("y")):
		return {"value": Vector2(float(data["x"]), float(data["y"]))}
	if expected == TYPE_COLOR and data.get("type") == "Color" and data.size() == 5:
		for field: String in ["r", "g", "b", "a"]:
			if not _number(data.get(field)) or float(data[field]) < 0.0 or float(data[field]) > 1.0:
				return _error("COLOR_COMPONENT_OUT_OF_RANGE")
		return {"value": Color(float(data["r"]), float(data["g"]), float(data["b"]), float(data["a"]))}
	if expected == TYPE_TRANSFORM2D and data.get("type") == "Transform2D" and data.size() == 4:
		var x: Dictionary = _convert(data.get("x"), TYPE_VECTOR2)
		var y: Dictionary = _convert(data.get("y"), TYPE_VECTOR2)
		var origin: Dictionary = _convert(data.get("origin"), TYPE_VECTOR2)
		if x.has("value") and y.has("value") and origin.has("value"):
			return {"value": Transform2D(x["value"], y["value"], origin["value"])}
	return _error("PROPERTY_TYPE_MISMATCH")


func _allowed_properties(node: Node) -> Dictionary:
	var allowed: Dictionary = {}
	if node is Node2D:
		allowed.merge({"position": TYPE_VECTOR2, "rotation": TYPE_FLOAT, "scale": TYPE_VECTOR2, "skew": TYPE_FLOAT, "transform": TYPE_TRANSFORM2D})
	if node is CanvasItem:
		allowed.merge({"visible": TYPE_BOOL, "modulate": TYPE_COLOR, "self_modulate": TYPE_COLOR, "z_index": TYPE_INT})
	if node is Control:
		allowed.merge({"position": TYPE_VECTOR2, "size": TYPE_VECTOR2, "scale": TYPE_VECTOR2, "rotation": TYPE_FLOAT, "custom_minimum_size": TYPE_VECTOR2})
	if node is ColorRect:
		allowed["color"] = TYPE_COLOR
	if node is Label or node is Button:
		allowed["text"] = TYPE_STRING
	if node is CollisionObject2D:
		allowed.merge({"collision_layer": TYPE_INT, "collision_mask": TYPE_INT})
	if node is CollisionShape2D:
		allowed.merge({"disabled": TYPE_BOOL, "one_way_collision": TYPE_BOOL})
	if node is Sprite2D:
		allowed.merge({"centered": TYPE_BOOL, "flip_h": TYPE_BOOL, "flip_v": TYPE_BOOL})
	if node is AnimatedSprite2D:
		allowed.merge({"flip_h": TYPE_BOOL, "flip_v": TYPE_BOOL, "speed_scale": TYPE_FLOAT})
	if node is Camera2D:
		allowed.merge({"zoom": TYPE_VECTOR2, "enabled": TYPE_BOOL})
	if node is Timer:
		allowed.merge({"wait_time": TYPE_FLOAT, "one_shot": TYPE_BOOL, "autostart": TYPE_BOOL})
	if node is TileMapLayer:
		allowed["collision_enabled"] = TYPE_BOOL
	return allowed


func _prepare_properties(node: Node, raw: Variant) -> Dictionary:
	if not raw is Dictionary or raw.is_empty() or raw.size() > 20:
		return _error("EXPECTED_1_TO_20_PROPERTIES")
	var allowed: Dictionary = _allowed_properties(node)
	var values: Dictionary = {}
	if raw.has("transform") and (raw.has("position") or raw.has("rotation") or raw.has("scale") or raw.has("skew")):
		return _error("TRANSFORM_CONFLICT")
	for key: Variant in raw:
		if not key is String or not allowed.has(key):
			return _error("PROPERTY_NOT_ALLOWLISTED")
		var converted: Dictionary = _convert(raw[key], int(allowed[key]))
		if converted.has("error"):
			return converted
		var value: Variant = converted["value"]
		if key == "z_index" and (int(value) < -4096 or int(value) > 4096):
			return _error("PROPERTY_OUT_OF_RANGE")
		if key in ["collision_layer", "collision_mask"] and (int(value) < 0 or int(value) > 4294967295):
			return _error("PROPERTY_OUT_OF_RANGE")
		if key == "wait_time" and float(value) <= 0.0:
			return _error("PROPERTY_OUT_OF_RANGE")
		if key in ["size", "custom_minimum_size"] and (value.x < 0.0 or value.y < 0.0):
			return _error("PROPERTY_OUT_OF_RANGE")
		values[key] = value
	return {"values": values}


func _properties(node: Node, params: Dictionary, root: Node) -> Dictionary:
	var prepared: Dictionary = _prepare_properties(node, params.get("properties"))
	if prepared.has("error"):
		return prepared
	var values: Dictionary = prepared["values"]
	var previous: Dictionary = {}
	for key: String in values:
		previous[key] = node.get(key)
	var manager: EditorUndoRedoManager = _begin("set properties", root)
	manager.add_do_method(self, "_set_values", node, values)
	manager.add_undo_method(self, "_set_values", node, previous)
	manager.commit_action()
	return {"modified_node": str(root.get_path_to(node)), "properties": values.keys()}


func _create(params: Dictionary, root: Node) -> Dictionary:
	var parent: Node = _node(root, str(params.get("parent_path", ".")))
	var node_name: String = str(params.get("name", ""))
	var type_name: String = str(params.get("node_type", ""))
	if parent == null or not _editable(parent, root) or (parent != root and parent.scene_file_path != ""):
		return _error("PARENT_NOT_EDITABLE")
	if not _name_ok(node_name) or parent.has_node(NodePath(node_name)):
		return _error("INVALID_OR_DUPLICATE_NODE_NAME")
	if not type_name in NODE_TYPES:
		return _error("NODE_TYPE_NOT_ALLOWLISTED")
	var node: Node = ClassDB.instantiate(type_name) as Node
	node.name = node_name
	var values: Dictionary = {}
	if params.has("properties"):
		var prepared: Dictionary = _prepare_properties(node, params["properties"])
		if prepared.has("error"):
			node.free()
			return prepared
		values = prepared["values"]
	var manager: EditorUndoRedoManager = _begin("create " + node_name, root)
	manager.add_do_method(self, "_attach", node, parent, root, values)
	manager.add_do_reference(node)
	manager.add_undo_method(parent, "remove_child", node)
	manager.commit_action()
	return {"created_node": str(root.get_path_to(node)), "node_type": type_name}


func _attach(node: Node, parent: Node, owner: Node, values: Dictionary) -> void:
	parent.add_child(node)
	node.owner = owner
	_set_values(node, values)


func _owners(node: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child: Node in _all_nodes(node):
		result.append({"node": child, "owner": child.owner})
	return result


func _restore_owners(owners: Array[Dictionary]) -> void:
	for entry: Dictionary in owners:
		var node: Node = entry["node"]
		node.owner = entry["owner"]


func _relative_nodepath(origin: String, target: String) -> String:
	var from_parts: PackedStringArray = origin.split("/", false) if origin != "." else PackedStringArray()
	var to_parts: PackedStringArray = target.split("/", false) if target != "." else PackedStringArray()
	var shared: int = 0
	while shared < mini(from_parts.size(), to_parts.size()) and from_parts[shared] == to_parts[shared]:
		shared += 1
	var parts: PackedStringArray = PackedStringArray()
	for index: int in range(shared, from_parts.size()):
		parts.append("..")
	for index: int in range(shared, to_parts.size()):
		parts.append(to_parts[index])
	return "/".join(parts) if not parts.is_empty() else "."


func _contains_reference(value: Variant, depth: int = 0) -> bool:
	if depth > 8:
		return true
	if value is NodePath:
		return not value.is_empty()
	if value is Node:
		return true
	if value is Array:
		for item: Variant in value:
			if _contains_reference(item, depth + 1):
				return true
	if value is Dictionary:
		for key: Variant in value:
			if _contains_reference(key, depth + 1) or _contains_reference(value[key], depth + 1):
				return true
	return false


func _path_changes(root: Node, moved: Node, new_path: String, deleting: bool) -> Dictionary:
	var changes: Array[Dictionary] = []
	var nodes: Array[Node] = _all_nodes(root)
	if nodes.size() > 5000:
		return _error("SCENE_TOO_LARGE_FOR_SAFE_REFACTOR")
	var old_path: String = str(root.get_path_to(moved))
	for origin: Node in nodes:
		if origin is AnimationMixer and not origin.get_animation_library_list().is_empty():
			return _error("ANIMATION_PATH_REFACTOR_REQUIRES_MANUAL_REVIEW")
		var origin_path: String = str(root.get_path_to(origin))
		var origin_script: Script = origin.get_script() as Script
		if origin_script != null:
			var script_text: String = origin_script.source_code
			if script_text.contains("$") or script_text.contains("get_node") or script_text.contains("NodePath"):
				return _error("SCRIPT_LITERAL_NODEPATHS_REQUIRE_MANUAL_REVIEW")
		if deleting:
			for signal_entry: Dictionary in origin.get_signal_list():
				for connection: Dictionary in origin.get_signal_connection_list(signal_entry["name"]):
					if (int(connection["flags"]) & CONNECT_PERSIST) == 0:
						continue
					var callable: Callable = connection["callable"]
					var target: Object = callable.get_object()
					if target is Node:
						var source_inside: bool = origin == moved or moved.is_ancestor_of(origin)
						var target_inside: bool = target == moved or moved.is_ancestor_of(target)
						if source_inside != target_inside:
							return _error("DISCONNECT_CROSS_SUBTREE_SIGNALS_BEFORE_DELETE")
		var origin_moved: bool = origin == moved or moved.is_ancestor_of(origin)
		var new_origin: String = new_path + origin_path.trim_prefix(old_path) if origin_moved else origin_path
		for property: Dictionary in origin.get_property_list():
			var type_id: int = int(property["type"])
			if (int(property["usage"]) & PROPERTY_USAGE_STORAGE) != 0 and type_id in [TYPE_ARRAY, TYPE_DICTIONARY]:
				if _contains_reference(origin.get(property["name"])):
					return _error("CONTAINER_NODE_REFERENCES_REQUIRE_MANUAL_REVIEW")
			if type_id != TYPE_NODE_PATH and type_id != TYPE_OBJECT:
				continue
			if (int(property["usage"]) & PROPERTY_USAGE_STORAGE) == 0 or str(property["name"]) in ["owner", "script"]:
				continue
			var value: Variant = origin.get(property["name"])
			if type_id == TYPE_OBJECT:
				if value is Resource and value.get_script() != null:
					return _error("SCRIPTED_RESOURCE_REFERENCES_REQUIRE_MANUAL_REVIEW")
				if deleting and not origin_moved and value is Node and (value == moved or moved.is_ancestor_of(value)):
					return _error("NODE_REFERENCED_BY_ANOTHER_PROPERTY")
				continue
			var path: NodePath = value
			if path.is_empty():
				continue
			if path.is_absolute():
				return _error("ABSOLUTE_NODEPATH_REQUIRES_MANUAL_REVIEW")
			var target: Node = origin.get_node_or_null(NodePath(path.get_concatenated_names()))
			if target == null or (target != root and not root.is_ancestor_of(target)):
				return _error("UNRESOLVED_NODEPATH_REQUIRES_MANUAL_REVIEW")
			var target_moved: bool = target == moved or moved.is_ancestor_of(target)
			if deleting:
				if target_moved and not origin_moved:
					return _error("NODE_REFERENCED_BY_NODEPATH")
				continue
			if not origin_moved and not target_moved:
				continue
			if not _editable(origin, root):
				return _error("REFERENCE_IN_INSTANCE_REQUIRES_MANUAL_REVIEW")
			var target_path: String = str(root.get_path_to(target))
			var new_target: String = new_path + target_path.trim_prefix(old_path) if target_moved else target_path
			var replacement: String = _relative_nodepath(new_origin, new_target)
			if path.get_subname_count() > 0:
				replacement += ":" + str(path.get_concatenated_subnames())
			changes.append({"node": origin, "property": str(property["name"]), "old": path, "new": NodePath(replacement)})
	return {"changes": changes}


func _structure(method: String, node: Node, params: Dictionary, root: Node) -> Dictionary:
	if node == root:
		return _error("SCENE_ROOT_STRUCTURAL_CHANGE_NOT_ALLOWED")
	var first_node_header: String = ""
	if FileAccess.file_exists(root.scene_file_path):
		for line: String in FileAccess.get_file_as_string(root.scene_file_path).split("\n"):
			if line.begins_with("[node "):
				first_node_header = line
				break
	if first_node_header.contains("instance="):
		return _error("INHERITED_SCENE_STRUCTURE_REQUIRES_MANUAL_REVIEW")
	var previous_parent: Node = node.get_parent()
	var parent: Node = previous_parent
	var previous_name: String = str(node.name)
	var new_name: String = previous_name
	var index: int = node.get_index()
	var new_index: int = index
	var deleting: bool = method == "editor_delete_node"
	if method == "editor_rename_node":
		new_name = str(params.get("name", ""))
		if not _name_ok(new_name) or (new_name != previous_name and parent.has_node(NodePath(new_name))):
			return _error("INVALID_OR_DUPLICATE_NODE_NAME")
	if method == "editor_reparent_node":
		parent = _node(root, str(params.get("parent_path", ".")))
		if parent == null or parent == node or node.is_ancestor_of(parent) or not _editable(parent, root) or (parent != root and parent.scene_file_path != ""):
			return _error("INVALID_REPARENT_TARGET")
		if parent != previous_parent and parent.has_node(NodePath(new_name)):
			return _error("DUPLICATE_NODE_NAME")
		new_index = int(params.get("index", parent.get_child_count() - (1 if parent == previous_parent else 0)))
		if new_index < 0 or new_index >= parent.get_child_count() + (0 if parent == previous_parent else 1):
			return _error("CHILD_INDEX_OUT_OF_RANGE")
	if deleting and node.get_child_count() > 0 and params.get("confirm_subtree", false) != true:
		return _error("CONFIRM_SUBTREE_REQUIRED")
	var new_path: String = str(root.get_path_to(parent)).path_join(new_name).trim_prefix("./")
	var planned: Dictionary = _path_changes(root, node, new_path, deleting)
	if planned.has("error"):
		return planned
	var owners: Array[Dictionary] = _owners(node)
	var local_transform: Dictionary = {"transform": node.transform} if node is Node2D else ({"position": node.position, "rotation": node.rotation, "scale": node.scale} if node is Control else {})
	var manager: EditorUndoRedoManager = _begin(method.trim_prefix("editor_"), root)
	if deleting:
		manager.add_do_method(previous_parent, "remove_child", node)
		manager.add_undo_method(self, "_restore_deleted", node, previous_parent, index, owners)
		manager.add_undo_reference(node)
	else:
		manager.add_do_method(self, "_relocate", node, parent, new_index, new_name, owners, {}, bool(params.get("keep_global_transform", true)), planned["changes"], true)
		manager.add_undo_method(self, "_relocate", node, previous_parent, index, previous_name, owners, local_transform, false, planned["changes"], false)
	manager.commit_action()
	return {"operation": method, "previous_path": str(params.get("node_path")), "node_path": "" if deleting else str(root.get_path_to(node)), "updated_nodepaths": planned["changes"].size()}


func _restore_deleted(node: Node, parent: Node, index: int, owners: Array[Dictionary]) -> void:
	parent.add_child(node)
	parent.move_child(node, index)
	_restore_owners(owners)


func _relocate(node: Node, parent: Node, index: int, node_name: String, owners: Array[Dictionary], transform_values: Dictionary, keep_global: bool, changes: Array, forward: bool) -> void:
	if node.get_parent() != parent:
		node.reparent(parent, keep_global)
	node.name = node_name
	parent.move_child(node, index)
	_restore_owners(owners)
	_set_values(node, transform_values)
	for change: Dictionary in changes:
		var origin: Node = change["node"]
		origin.set(change["property"], change["new"] if forward else change["old"])


func _safe_script(path: String, depth: int = 0) -> bool:
	if depth > 8 or not safe_path(path, ["gd"]):
		return false
	var text: String = FileAccess.get_file_as_string(path)
	var unsafe_pattern: RegEx = RegEx.new()
	unsafe_pattern.compile("@tool|\\b(static|preload|load|ResourceLoader)\\b")
	if unsafe_pattern.search(text) != null:
		return false
	for line: String in text.split("\n"):
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("extends "):
			var base: String = trimmed.trim_prefix("extends ").strip_edges()
			if base.begins_with('"') and base.ends_with('"'):
				return _safe_script(base.trim_prefix('"').trim_suffix('"'), depth + 1)
			return base in NODE_TYPES
	return false


func _assign(node: Node, params: Dictionary, root: Node) -> Dictionary:
	var property: String = str(params.get("property", ""))
	var path: String = str(params.get("resource_path", ""))
	var allowed: bool = (property == "script") or (property == "texture" and (node is Sprite2D or node is TextureRect)) or (property == "sprite_frames" and node is AnimatedSprite2D) or (property == "shape" and node is CollisionShape2D) or (property == "tile_set" and node is TileMapLayer) or (property == "stream" and (node is AudioStreamPlayer or node is AudioStreamPlayer2D))
	if not allowed:
		return _error("RESOURCE_PROPERTY_NOT_ALLOWED")
	if not safe_path(path, ["gd", "png", "jpg", "jpeg", "webp", "svg", "ogg", "wav", "tres"]):
		return _error("RESOURCE_PATH_NOT_ALLOWED")
	if property == "script" and not _safe_script(path):
		return _error("SCRIPT_REQUIRES_NON_TOOL_NO_STATIC_OR_LOAD_NATIVE_BASE")
	if path.get_extension() == "tres":
		var text: String = FileAccess.get_file_as_string(path)
		var script_pattern: RegEx = RegEx.new()
		script_pattern.compile('(?m)^\\s*script\\s*=')
		var header_pattern: RegEx = RegEx.new()
		header_pattern.compile('^\\[gd_resource type="([^"]+)"')
		var header_match: RegExMatch = header_pattern.search(text)
		if header_match == null or not header_match.get_string(1) in ["SpriteFrames", "RectangleShape2D", "CircleShape2D", "CapsuleShape2D", "SegmentShape2D", "ConvexPolygonShape2D", "ConcavePolygonShape2D", "TileSet"]:
			return _error("RESOURCE_CLASS_NOT_ALLOWLISTED")
		if text.contains('type="Script"') or script_pattern.search(text) != null:
			return _error("SCRIPTED_RESOURCE_NOT_ALLOWED")
		var sub_pattern: RegEx = RegEx.new()
		sub_pattern.compile('\\[sub_resource type="([^"]+)"')
		for sub_match: RegExMatch in sub_pattern.search_all(text):
			if not sub_match.get_string(1) in ["AtlasTexture", "RectangleShape2D", "CircleShape2D", "CapsuleShape2D", "SegmentShape2D", "ConvexPolygonShape2D", "ConcavePolygonShape2D", "TileSetAtlasSource", "TileSetScenesCollectionSource", "TileData", "PhysicsMaterial"]:
				return _error("RESOURCE_SUBCLASS_NOT_ALLOWLISTED")
		# Imported resource dependencies must also stay inside this project.
		var regex: RegEx = RegEx.new()
		regex.compile('path="([^"]+)"')
		for matched: RegExMatch in regex.search_all(text):
			if not safe_path(matched.get_string(1), ["png", "jpg", "jpeg", "webp", "svg", "ogg", "wav"]):
				return _error("RESOURCE_DEPENDENCY_NOT_ALLOWED")
	var resource: Resource = ResourceLoader.load(path)
	if resource == null or resource.get_script() != null:
		return _error("RESOURCE_FAILED_OR_SCRIPTED")
	var valid_type: bool = (property == "script" and resource is GDScript and not resource.is_tool() and ClassDB.is_parent_class(node.get_class(), resource.get_instance_base_type())) or (property == "texture" and resource is Texture2D) or (property == "sprite_frames" and resource is SpriteFrames) or (property == "shape" and resource is Shape2D) or (property == "tile_set" and resource is TileSet) or (property == "stream" and resource is AudioStream)
	if not valid_type:
		return _error("RESOURCE_TYPE_MISMATCH")
	var old: Variant = node.get(property)
	var manager: EditorUndoRedoManager = _begin("assign " + property, root)
	manager.add_do_property(node, property, resource)
	manager.add_undo_property(node, property, old)
	manager.commit_action()
	return {"assigned_node": str(root.get_path_to(node)), "property": property, "resource_path": path}


func _signal_action(method: String, node: Node, params: Dictionary, root: Node) -> Dictionary:
	var target: Node = _node(root, str(params.get("target_path", "")))
	var signal_name: StringName = str(params.get("signal", ""))
	var target_method: StringName = str(params.get("method", ""))
	if target == null or not _editable(target, root) or not node.has_signal(signal_name):
		return _error("INVALID_SIGNAL_ENDPOINT")
	var callable: Callable = Callable(target, target_method)
	var existing_flags: int = 0
	var found: bool = false
	for connection: Dictionary in node.get_signal_connection_list(signal_name):
		var connection_callable: Callable = connection["callable"]
		if connection_callable.get_object() == target and connection_callable.get_method() == target_method:
			if connection_callable.get_bound_arguments_count() != 0 or connection_callable.get_unbound_arguments_count() != 0:
				return _error("BOUND_SIGNAL_REQUIRES_MANUAL_REVIEW")
			found = true
			existing_flags = int(connection["flags"])
	if method == "editor_connect_signal":
		if found:
			return _error("SIGNAL_ALREADY_CONNECTED")
		if not target.has_method(target_method):
			return _error("TARGET_METHOD_NOT_FOUND")
		var allowed: bool = target is CanvasItem and str(target_method) in ["show", "hide"]
		var script_resource: Script = target.get_script() as Script
		if script_resource != null and str(target_method).begins_with("_on_"):
			for declared: Dictionary in script_resource.get_script_method_list():
				if str(declared["name"]) == str(target_method):
					allowed = true
		if not allowed:
			return _error("TARGET_METHOD_NOT_ALLOWLISTED")
		var signal_args: int = -1
		for entry: Dictionary in node.get_signal_list():
			if entry["name"] == signal_name:
				signal_args = entry["args"].size()
		for entry: Dictionary in target.get_method_list():
			if entry["name"] == target_method:
				var count: int = entry["args"].size()
				if signal_args > count or signal_args < count - entry["default_args"].size():
					return _error("SIGNAL_ARGUMENT_COUNT_MISMATCH")
	elif not found:
		return _error("SIGNAL_NOT_CONNECTED")
	var manager: EditorUndoRedoManager = _begin(method.trim_prefix("editor_"), root)
	if method == "editor_connect_signal":
		manager.add_do_method(node, "connect", signal_name, callable, CONNECT_PERSIST)
		manager.add_undo_method(node, "disconnect", signal_name, callable)
	else:
		manager.add_do_method(node, "disconnect", signal_name, callable)
		manager.add_undo_method(node, "connect", signal_name, callable, existing_flags)
	manager.commit_action()
	return {"signal": str(signal_name), "source_node": str(root.get_path_to(node)), "target_node": str(root.get_path_to(target)), "method": str(target_method), "connected": method == "editor_connect_signal"}


func _history_action(method: String, root: Node) -> Dictionary:
	var manager: EditorUndoRedoManager = plugin.get_undo_redo()
	var history: UndoRedo = manager.get_history_undo_redo(manager.get_object_history_id(root))
	var index: int = history.get_current_action() + (1 if method == "editor_redo" else 0)
	if index < 0 or index >= history.get_history_count():
		return _error("NO_HISTORY_ACTION")
	var action_name: String = history.get_action_name(index)
	if not action_name.begins_with("MCP: "):
		return _error("REFUSE_TO_UNDO_OR_REDO_USER_ACTION")
	var changed: bool = history.undo() if method == "editor_undo" else history.redo()
	return {"history_action": action_name, "direction": method, "changed": changed}
