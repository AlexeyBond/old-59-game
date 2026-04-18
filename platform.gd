extends PathFollow2D

var tw: Tween = null

@export_range(0.1, 2.0) var time = 1.0

func set_open(op: bool):
	var target := 1.0 if op else 0.0
	if tw != null:
		if tw.is_running():
			tw.stop()
		tw = null
	
	tw = get_tree().create_tween()
	tw.tween_property(
		self,
		"progress_ratio",
		target,
		abs(target - progress_ratio) * time,
	)

	tw.play()

func set_closed(closed: bool):
	set_open(not closed)

func open():
	set_open(true)

func close():
	set_open(false)
