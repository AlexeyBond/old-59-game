extends Node2D
class_name ASignal

@export var active: bool = false

@export_color_no_alpha var tint_passive: Color = Color.DARK_RED
@export_color_no_alpha var tint_active: Color = Color.RED

var tween: Tween

var sources: Array[Node]

signal changed(bool)
signal activated
signal deactivated

func _emit_signals():
	changed.emit(active)
	if active:
		activated.emit()
	else:
		deactivated.emit()

func register_source(src: Node):
	sources.append(src)

func _ready() -> void:
	modulate = tint_active if active else tint_passive
	_emit_signals()

func is_set() -> bool:
	for source in sources:
		if source.is_set():
			return true
	return false

func _process(_delta: float) -> void:
	var a := is_set()
	
	if a == active:
		return

	active = a
	_emit_signals()

	if tween != null:
		if tween.is_running():
			tween.stop()
		tween = null

	tween = get_tree().create_tween()

	tween.tween_property(
		self,
		"modulate",
		tint_active if active else tint_passive,
		0.2,
	)
	
	tween.play()
