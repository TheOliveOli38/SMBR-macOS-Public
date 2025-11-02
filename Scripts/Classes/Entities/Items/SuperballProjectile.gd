class_name SuperballProjectile
extends FireBall

var vertical_direction := 1
const SMOKE = preload("uid://d08nv4qtfouv1")

func _physics_process(delta: float) -> void:
	if is_on_floor() or is_on_ceiling():
		vertical_direction *= -1
	if is_on_wall():
		direction *= -1
	velocity = MOVE_SPEED * Vector2(direction, vertical_direction)
	move_and_slide()

func hit(play_sfx := true) -> void:
	if play_sfx:
		AudioManager.play_sfx("bump", global_position)
	summon_explosion()
	queue_free()

func summon_explosion() -> void:
	var node = SMOKE.instantiate()
	node.global_position = global_position + Vector2(0, 8)
	add_sibling(node)
