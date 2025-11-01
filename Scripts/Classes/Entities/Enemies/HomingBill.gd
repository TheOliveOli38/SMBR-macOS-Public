extends Enemy


var target_player: Player = null
var direction_vector := Vector2.LEFT

var direction_angle := 0.0

const SPEED := 75.0

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_visuals()

func handle_movement(delta: float) -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	direction_vector = ((target_player.global_position + Vector2(0, -8)) - global_position).normalized()
	if abs(direction_vector.x) > 0:
		direction = sign(direction_vector.x)
	velocity = SPEED * direction_vector
	move_and_slide()
	if is_on_wall():
		hit_solid()

func handle_visuals() -> void:
	var angle = snapped(rad_to_deg(direction_vector.angle()), 45)
	var diagonal = angle % 90 != 0
	print(diagonal)
	$Sprite.global_rotation_degrees = angle + (180 if direction == -1 else 0)
	if diagonal:
		$Sprite.global_rotation_degrees += (45 if direction == 1 else 135)
	$ParticlesRotation.global_rotation_degrees = angle
	$Sprite.play("Diagonal" if diagonal else "Normal")
	$Sprite.scale.x = direction

func hit_solid() -> void:
	queue_free()
