extends Area2D
class_name Exit

@export_file_path("*.tscn") var next_level

func _ready() -> void:
	assert(next_level != null)

func _on_body_entered(body: Node2D) -> void:
	body.do_exit(self)
