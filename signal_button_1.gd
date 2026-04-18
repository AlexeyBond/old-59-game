extends Area2D


func _ready() -> void:
	var p: Node = get_parent()
	
	while p != get_tree().root:
		if p is ASignal:
			p.register_source(self)
			return
		p = p.get_parent()

func is_set() -> bool:
	return get_overlapping_bodies().size() > 0
