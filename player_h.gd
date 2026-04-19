extends CharacterBody2D


@export_range(1, 500) var speed: float = 300.0
@export_range(24, 128) var step: float = 64
@export_range(0.05, 0.5) var step_time: float = 0.2
@onready var state: StateChart = $StateChart

func _ready() -> void:
	$CanvasLayer.show()
	ghost.global_position = global_position
	ghost.hide()
	$ghost_player.play("idle")

var exit: Exit = null

func do_exit(e: Exit):
	state.send_event("exit")
	self.exit = e

func _on_exiting_state_processing(_delta: float) -> void:
	visible = Time.get_ticks_msec() % 100 > 50


func _on_exited_state_entered() -> void:
	get_tree().change_scene_to_file(exit.next_level)


func _pos_try(pos: Position, dir: Vector2i) -> Position:
	var target: Vector2 = pos.world_pos + Vector2(dir) * step
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query.from = pos.world_pos
	query.to = target
	query.exclude = [self.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.hit_from_inside = true

	var res := get_world_2d().direct_space_state.intersect_ray(query)

	if len(res) != 0:
		return null
	
	var new_pos: Position = Position.new(target, pos)
	if dir.length_squared() == 1:
		pos.next[dir] = new_pos
	else:
		pos.next[Vector2i(dir / dir.length())] = new_pos

	return new_pos

func _pos_build_3(pos: Position, dir: Vector2i):
	var p := _pos_try(pos, dir)
	if p != null:
		p.is_final = true

func _pos_build_2(pos: Position, dir1: Vector2i, dir2: Vector2i):
	var p := _pos_try(pos, dir1)
	if p != null:
		_pos_build_3(p, dir2)
		_pos_build_3(p, -dir2)
	
	_pos_build_3(pos, dir2 * 2)
	_pos_build_3(pos, -dir2 * 2)

func _pos_build_1(pos: Position, dir1: Vector2i, dir2: Vector2i):
	var p := _pos_try(pos, dir1)
	if p != null:
		_pos_build_2(p, dir1, dir2)

var root_position: Position
var ghost_position: Position

func _pos_build():
	var pos := Position.new(get_global_transform().get_origin(), null)
	_pos_build_1(pos, Vector2i.UP, Vector2i.LEFT)
	_pos_build_1(pos, Vector2i.DOWN, Vector2i.LEFT)
	_pos_build_1(pos, Vector2i.LEFT, Vector2i.UP)
	_pos_build_1(pos, Vector2i.RIGHT, Vector2i.UP)
	if root_position != null:
		_pos_drop(root_position)
	root_position = pos
	ghost_position = pos
	queue_redraw()

func _pos_drop(pos: Position):
	for p in pos.next.values():
		_pos_drop(p)
	pos.next.clear()

func _pos_draw():
	if ghost_position == null:
		return

	for pos in ghost_position.next.values():
		var col: Color = Color.SKY_BLUE if pos.has_final() else Color.DIM_GRAY
		draw_line(
			to_local(ghost_position.world_pos),
			to_local(pos.world_pos),
			col,
			2.0,
		)

	var pos := ghost_position

	while pos.parent != null:
		draw_line(
			to_local(pos.parent.world_pos),
			to_local(pos.world_pos),
			Color.GREEN,
			2.0,
		)
		pos = pos.parent

func _draw() -> void:
	_pos_draw()

var ghost_tween: Tween

@export var ghost: Sprite2D

func _move_ghost(pos: Position):
	ghost.show()
	ghost_position = pos
	if ghost_tween != null:
		if ghost_tween.is_running():
			ghost_tween.stop()
	ghost_tween = get_tree().create_tween()
	ghost_tween.tween_property(
		ghost,
		"global_position",
		pos.world_pos,
		step_time * ghost.global_position.distance_to(pos.world_pos) / step,
	)
	if pos.is_final:
		ghost_tween.tween_callback(
			func():
				ghost.hide()
				self.ghost_position = null
				self.queue_redraw()
		)
		ghost_tween.tween_property(
			self,
			"global_position",
			pos.world_pos,
			0.5,
		)
		ghost_tween.tween_callback(
			func():
				ghost.global_position = self.global_position
				self._pos_build()
		)
	ghost_tween.play()
	queue_redraw()

func _try_move_ghost(dir: Vector2i):
	if ghost_position == null:
		return
	if dir in ghost_position.next:
		var p := ghost_position.next[dir]
		if p.has_final():
			_move_ghost(p)

class Position:
	var world_pos: Vector2
	var parent: Position
	var next: Dictionary[Vector2i, Position]
	var is_final: bool

	func _init(
		wp: Vector2,
		p: Position,
	):
		self.world_pos = wp
		self.parent = p
		self.is_final = false
		self.next = {}
	
	func has_final() -> bool:
		if self.is_final:
			return true
		for p in self.next.values():
			if p.has_final():
				return true
		return false


func _on_playing_state_entered() -> void:
	pass # Replace with function body.


func _on_playing_state_processing(_delta: float) -> void:
	if root_position == null:
		_pos_build()

	if Input.is_action_just_pressed("move_down"):
		_try_move_ghost(Vector2i.DOWN)
	elif Input.is_action_just_pressed("move_up"):
		_try_move_ghost(Vector2i.UP)
	elif Input.is_action_just_pressed("move_left"):
		_try_move_ghost(Vector2i.LEFT)
	elif Input.is_action_just_pressed("move_right"):
		_try_move_ghost(Vector2i.RIGHT)


func _on_exiting_state_entered() -> void:
	if ghost_tween != null:
		if ghost_tween.is_running():
			ghost_tween.stop()
		ghost_tween = null
