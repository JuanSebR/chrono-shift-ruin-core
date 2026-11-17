@tool
extends RefCounted
## One resource only. compare() is read-only; cleanup is a separate local one-shot authorization.

const RESOURCE_PATH: String = "res://player_frames.tres"
const ALLOWED_CLASSES: Array[String] = ["SpriteFrames", "AtlasTexture", "CompressedTexture2D", "ImageTexture", "PortableCompressedTexture2D"]
var memory_resources: Array[Resource] = []
var last_poll: int = 0


func private_path(name: String) -> String:
	return OS.get_environment("LOCALAPPDATA").path_join("GodotMCPCodex/private/" + name)


func _hash_bytes(bytes: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _json(value: Variant) -> String:
	return JSON.stringify(value, "", true, true)


func _encode(value: Variant, context: Dictionary, depth: int = 0) -> Variant:
	if depth > 32:
		context["errors"].append("MAX_DEPTH")
		return null
	var kind: int = typeof(value)
	match kind:
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return {"type": type_string(kind), "value": value}
		TYPE_FLOAT:
			if not is_finite(value):
				context["errors"].append("NON_FINITE")
			return {"type": "float", "value": value}
		TYPE_STRING_NAME, TYPE_NODE_PATH:
			return {"type": type_string(kind), "value": str(value)}
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return {"type": type_string(kind), "x": value.x, "y": value.y}
		TYPE_RECT2, TYPE_RECT2I:
			return {"type": type_string(kind), "position": _encode(value.position, context, depth + 1), "size": _encode(value.size, context, depth + 1)}
		TYPE_COLOR:
			return {"type": "Color", "r": value.r, "g": value.g, "b": value.b, "a": value.a}
		TYPE_ARRAY:
			var items: Array = []
			for item: Variant in value:
				items.append(_encode(item, context, depth + 1))
			return {"type": "Array", "items": items}
		TYPE_DICTIONARY:
			var entries: Array[Dictionary] = []
			for key: Variant in value:
				entries.append({"key": _encode(key, context, depth + 1), "value": _encode(value[key], context, depth + 1)})
			entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _json(a["key"]) < _json(b["key"]))
			return {"type": "Dictionary", "entries": entries}
		TYPE_OBJECT:
			if value == null:
				return {"type": "null_resource"}
			if not value is Resource:
				context["errors"].append("NON_RESOURCE_OBJECT")
				return null
			return _encode_resource(value, context, depth + 1)
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_VECTOR4_ARRAY:
			return {"type": type_string(kind), "size": value.size(), "sha256": _hash_bytes(var_to_bytes(value))}
	context["errors"].append("UNSUPPORTED_VARIANT_" + type_string(kind))
	return null


func _encode_resource(resource: Resource, context: Dictionary, depth: int) -> Dictionary:
	var instance_id: int = resource.get_instance_id()
	if context["seen"].has(instance_id):
		return {"ref": context["seen"][instance_id]}
	var id: String = "resource_%d" % context["seen"].size()
	context["seen"][instance_id] = id
	if resource.get_script() != null or not resource.get_class() in ALLOWED_CLASSES:
		context["errors"].append("UNSUPPORTED_OR_SCRIPTED_RESOURCE_" + resource.get_class())
		return {"ref": id}
	context["objects"].append(resource)
	var record: Dictionary = {"id": id, "class": resource.get_class(), "resource_path": resource.resource_path, "serialized": {}}
	context["records"].append(record)
	var properties: Dictionary = {}
	for property: Dictionary in resource.get_property_list():
		if (int(property["usage"]) & PROPERTY_USAGE_STORAGE) != 0:
			properties[str(property["name"])] = property
	var names: Array = properties.keys()
	names.sort()
	for name: String in names:
		record["serialized"][name] = {"declared_type": int(properties[name]["type"]), "value": _encode(resource.get(name), context, depth + 1)}
	if resource is Texture2D and not resource is AtlasTexture:
		var image: Image = resource.get_image()
		if image == null or image.is_empty():
			context["errors"].append("TEXTURE_PIXELS_UNAVAILABLE")
		else:
			record["pixels"] = {"width": image.get_width(), "height": image.get_height(), "format": image.get_format(), "mipmaps": image.has_mipmaps(), "sha256": _hash_bytes(image.get_data())}
		if resource.resource_path.begins_with("res://") and FileAccess.file_exists(resource.resource_path):
			record["source_file_sha256"] = FileAccess.get_sha256(resource.resource_path)
	return {"ref": id}


func _capture(resource: SpriteFrames) -> Dictionary:
	var context: Dictionary = {"seen": {}, "records": [], "objects": [], "errors": []}
	_encode_resource(resource, context, 0)
	var flags: Array[Dictionary] = []
	for item: Resource in context["objects"]:
		flags.append({"id": context["seen"][item.get_instance_id()], "class": item.get_class(), "path": item.resource_path, "instance_id": str(item.get_instance_id()), "edited": EditorInterface.is_object_edited(item), "owned_by_frames": item == resource or item.resource_path.begins_with(RESOURCE_PATH + "::")})
	var animations: Array[Dictionary] = []
	for name: StringName in resource.get_animation_names():
		var frames: Array[Dictionary] = []
		for index: int in resource.get_frame_count(name):
			var texture: Texture2D = resource.get_frame_texture(name, index)
			var frame: Dictionary = {"index": index, "duration": resource.get_frame_duration(name, index), "resource_ref": context["seen"].get(texture.get_instance_id(), "UNENCODED") if texture != null else null}
			if texture is AtlasTexture:
				frame["region"] = _encode(texture.region, context)
				frame["margin"] = _encode(texture.margin, context)
				frame["filter_clip"] = texture.filter_clip
			frames.append(frame)
		animations.append({"name": str(name), "fps": resource.get_animation_speed(name), "loop": resource.get_animation_loop(name), "frames": frames})
	var content: Dictionary = {"resources": context["records"], "animations": animations}
	return {"content": content, "sha256": _json(content).sha256_text(), "flags": flags, "errors": context["errors"], "objects": context["objects"]}


func compare() -> Dictionary:
	memory_resources.clear()
	if not EditorInterface.has_method("is_object_edited") or not FileAccess.file_exists(RESOURCE_PATH):
		return {"error": "RESOURCE_OR_DOCUMENTED_API_UNAVAILABLE"}
	var disk_hash_before: String = FileAccess.get_sha256(RESOURCE_PATH)
	var cached: SpriteFrames = ResourceLoader.get_cached_ref(RESOURCE_PATH) as SpriteFrames
	if cached == null:
		return {"error": "RESOURCE_NOT_CURRENTLY_CACHED"}
	var before: Dictionary = _capture(cached)
	# Independent read, no replacement of the cached resource or any scene.
	var disk_copy: SpriteFrames = ResourceLoader.load(RESOURCE_PATH, "SpriteFrames", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as SpriteFrames
	if disk_copy == null:
		return {"error": "DISK_RESOURCE_READ_FAILED"}
	var disk: Dictionary = _capture(disk_copy)
	var after_read: Dictionary = _capture(cached)
	var disk_hash_after: String = FileAccess.get_sha256(RESOURCE_PATH)
	var stable: bool = before["sha256"] == after_read["sha256"] and before["flags"] == after_read["flags"] and disk_hash_before == disk_hash_after
	memory_resources.assign(before["objects"])
	var complete: bool = before["errors"].is_empty() and disk["errors"].is_empty()
	return {"resource_path": RESOURCE_PATH, "engine": Engine.get_version_info(), "cached_instance_id": str(cached.get_instance_id()), "disk_file_sha256": disk_hash_after, "memory_content_sha256": before["sha256"], "disk_content_sha256": disk["sha256"], "complete": complete, "equal": complete and stable and before["sha256"] == disk["sha256"], "read_only_stable": stable, "memory": before["content"], "disk": disk["content"], "memory_flags": before["flags"], "memory_errors": before["errors"], "disk_errors": disk["errors"]}


func conditional_cleanup(authorization: Dictionary) -> Dictionary:
	var before: Dictionary = compare()
	if before.get("equal", false) != true:
		return {"cleaned": false, "reason": "CONTENT_DIFFERENCE_OR_INCOMPLETE_COMPARISON", "before": before}
	for key: String in ["disk_file_sha256", "memory_content_sha256", "cached_instance_id"]:
		if authorization.get(key) != before[key]:
			return {"cleaned": false, "reason": "AUTHORIZED_SNAPSHOT_CHANGED", "before": before}
	if authorization.get("authorize_state_only_cleanup", false) != true or not EditorInterface.has_method("set_object_edited"):
		return {"cleaned": false, "reason": "DOCUMENTED_API_OR_AUTHORIZATION_MISSING", "before": before}
	var version: Dictionary = Engine.get_version_info()
	if int(version["major"]) != 4 or int(version["minor"]) != 7 or int(version["patch"]) != 2:
		return {"cleaned": false, "reason": "ENGINE_VERSION_CHANGED", "before": before}
	var targets: Array[Resource] = []
	var labels: Array[String] = []
	for resource: Resource in memory_resources:
		if resource.resource_path == RESOURCE_PATH or resource.resource_path.begins_with(RESOURCE_PATH + "::"):
			if EditorInterface.is_object_edited(resource):
				targets.append(resource)
				labels.append(resource.resource_path)
	for resource: Resource in targets:
		EditorInterface.set_object_edited(resource, false)
	var after: Dictionary = compare()
	if after.get("equal", false) != true or after.get("memory_content_sha256") != before["memory_content_sha256"] or after.get("disk_file_sha256") != before["disk_file_sha256"]:
		for resource: Resource in targets:
			EditorInterface.set_object_edited(resource, true)
		return {"cleaned": false, "reason": "POSTCHECK_FAILED_FLAGS_RESTORED", "before": before, "after": after}
	return {"cleaned": true, "api": "EditorInterface.set_object_edited(resource, false)", "resources_cleaned": labels, "before": before, "after": after}


func process_authorized_cleanup() -> Dictionary:
	if Time.get_ticks_msec() - last_poll < 1000:
		return {}
	last_poll = Time.get_ticks_msec()
	var request_path: String = private_path("frames-cleanup-authorized.json")
	if not FileAccess.file_exists(request_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(request_path))
	var result: Dictionary = conditional_cleanup(parsed) if parsed is Dictionary else {"cleaned": false, "reason": "INVALID_LOCAL_AUTHORIZATION"}
	# Consume the fixed local request. No remote cleanup command is registered.
	DirAccess.rename_absolute(request_path, private_path("frames-cleanup-authorized.processed.json"))
	return result


func write_cleanup_evidence(result: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(private_path("frames-cleanup-result.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(_json(result))
