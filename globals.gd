extends Node

@export_file_path("*.tscn") var start_level: String

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_all"):
		get_tree().change_scene_to_file(start_level)
	elif event.is_action_pressed("reset_level"):
		get_tree().reload_current_scene()
