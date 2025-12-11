extends Node2D

@export_range(-999999, 999999) var target_x := 64.0
@export_range(-999999, 999999) var target_y := 0.0
@export_range(1, 8) var length := 2
@export_range(1, 8) var speed := 3

@export_range(0, 544) var top_point := 256
@export_range(0, 544) var bottom_point := 0
@export var show_rope := true

@export var reverse := false

@export_enum("Moving", "Looping", "Falling", "Rail") var type := 0
@export_enum("Down", "Up") var y_direction := 0

var wave := 0.0

@onready var starting_position := global_position

func _ready() -> void:
	starting_position = global_position
	wave = -1.0

func _physics_process(delta: float) -> void:
	%Sprite.size.x = length * 16
	%Projection.size.x = %Sprite.size.x
	%Sprite.position.x = -(%Sprite.size.x / 2)
	$CollisionShape2D.shape.size.x = length * 16
	match type:
		0:
			handle_back_forth_movement(delta)
		1:
			handle_looping_movement(delta)

func handle_back_forth_movement(delta: float) -> void:
	var target_point = starting_position + Vector2(target_x, target_y)
	var distance = starting_position.distance_to(target_point)
	$Line.show()
	$Line.set_point_position(0, starting_position + Vector2(0, 4))
	$Line.set_point_position(1, target_point + Vector2(0, 4))
	%Projection.show()
	%Projection.global_position = target_point - Vector2(%Projection.size.x / 2, 0)
	if Global.level_editor_is_editing() == false:
		$Line.hide()
		%Projection.hide()
		if distance <= 0:
			return
		wave += delta / (distance / (speed * 32))
		var val = inverse_lerp(-1, 1, sin(wave))
		global_position = lerp(starting_position, target_point, val)

func handle_looping_movement(delta: float) -> void:
	$Rope.visible = show_rope
	$Rope.global_position.y = -top_point + 32
	$Rope.size.y = abs((top_point - bottom_point))
	$Rope.global_position.x = global_position.x - 8
	if Global.level_editor_is_editing() == false:
		global_position.y = wrapf(global_position.y + (((speed * 32) * delta) * [1, -1][y_direction]), -(top_point - 32), -(bottom_point - 32))
