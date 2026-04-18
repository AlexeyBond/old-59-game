extends CharacterBody2D


@export_range(1, 500) var speed: float = 300.0


func _on_playing_state_physics_processing(_delta: float) -> void:
	velocity = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	) * speed

	move_and_slide()

@onready var state: StateChart = $StateChart

func _ready() -> void:
	$CanvasLayer.show()

var exit: Exit = null

func do_exit(e: Exit):
	state.send_event("exit")
	self.exit = e

func _on_exiting_state_processing(_delta: float) -> void:
	visible = Time.get_ticks_msec() % 100 > 50


func _on_exited_state_entered() -> void:
	get_tree().change_scene_to_file(exit.next_level)
