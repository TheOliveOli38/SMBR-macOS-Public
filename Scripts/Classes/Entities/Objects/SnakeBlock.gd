class_name SnakeBlock
extends Node2D

@export var path := []
@export_range(4, 12) var length := 6
@export_range(1, 4) var speed := 1

var editing := false

var moving := false

const DIRECTIONS := [
	Vector2i.UP, # 0
	Vector2i.RIGHT, # 1
	Vector2i.DOWN, # 2
	Vector2i.LEFT # 3
]

var mouse_in_areas := 0
var last_direction := Vector2i.RIGHT

func _ready() -> void:
	for i in get_tree().get_nodes_in_group("SnakePieces"):
		i.get_node("PlayerDetection").player_entered.connect(start_travelling.unbind(1))
	print(path)
	update_pieces()

func update_pieces() -> void:
	var pos := Vector2i.ZERO
	$PlacePreview.position = pos
	if path.size() <= 0:
		return
	last_direction = path[path.size() - 1]
	for i in path:
		pos += i * 16
	$PlacePreview.position = pos
	for i in $PlacePreview.get_children():
		i.modulate = Color.RED if -last_direction == DIRECTIONS[i.get_index()] else Color.YELLOW
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if Global.level_editor != null:
		if Global.level_editor.current_state != LevelEditor.EditorState.PLAYTESTING:
			handle_editor_stuff()
		else:
			pass
	else:
		pass

func handle_editor_stuff() -> void:
	$PlacePreview.visible = editing
	if Input.is_action_pressed("mb_left") and editing and mouse_in_areas > 0:
		for i in 8:
			if is_mouse_in_area(i):
				if SnakeBlock.DIRECTIONS[i] == -last_direction:
					remove_last_piece()
				else:
					add_piece(SnakeBlock.DIRECTIONS[i])
				break
	if editing and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		if Input.is_action_just_pressed("editor_open_menu") or Input.is_action_just_pressed("ui_cancel"):
			editing = false
			Global.level_editor.current_state = LevelEditor.EditorState.IDLE
			update_pieces()

func remove_last_piece() -> void:
	if path.size() >= 1:
		path.pop_back()
	if path.size() <= 0:
		last_direction = Vector2i.ZERO
	update_pieces()

func add_piece(new_direction := Vector2i.ZERO) -> void:
	path.append(new_direction)
	update_pieces()

func on_mouse_entered(area_idx := 0) -> void:
	mouse_in_areas |= (1 << area_idx)

func on_mouse_exited(area_idx := 0) -> void:
	mouse_in_areas &= ~(1 << area_idx)

func is_mouse_in_area(area_idx := 0) -> bool:
	return mouse_in_areas & (1 << area_idx) != 0

func _draw() -> void:
	if $PathPreview.visible == false:
		return
	var pos := Vector2i(-8, -8)
	for i in path:
		draw_texture_rect_region($PlacePreview/N.texture,Rect2i(pos, Vector2i(16, 16)),Rect2i(Vector2i(16 * DIRECTIONS.find(i), 0), Vector2i(16, 16)), Color(1, 1, 1, 0.98))
		pos += i * 16
	draw_texture_rect_region($PlacePreview/N.texture,Rect2i(pos, Vector2i(16, 16)),Rect2i(Vector2i(64, 0), Vector2i(16, 16)), Color(1, 1, 1, 0.98))

func start_travelling() -> void:
	if moving:
		return
	moving = true
	var idx := 0
	var move_speed = 1.0 / (speed * 1.5)
	for i in get_tree().get_nodes_in_group("SnakePieces"):
		i.get_node("Sprite").play("Moving")
	for i in (path.size()) - (length - 1):
		var head_dir = path[idx + length - 1]
		var tail_dir = path[idx]
		var head_tween = $Tweens.create_tween().tween_property($Head, "position", $Head.position + Vector2(head_dir * 16), move_speed)
		var tail_tween = $Tweens.create_tween().tween_property($Tail, "position", $Tail.position + Vector2(tail_dir * 16), move_speed)
		await tail_tween.finished
		$Pieces.get_child(idx % (length - 1)).position = $Head.position
		idx += 1
	for i in get_tree().get_nodes_in_group("SnakePieces"):
		i.get_node("Sprite").play("Stopped")
