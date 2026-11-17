extends SceneTree

func _init() -> void:
	print("EDITOR_EDITED_API ", EditorInterface.has_method("is_object_edited"), " ", EditorInterface.has_method("set_object_edited"))
	quit()
