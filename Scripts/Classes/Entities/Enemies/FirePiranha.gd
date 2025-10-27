extends Node

var direction := Vector2(-1, 1)

var target_player: Player = null

var shooting := false

@export var fireball_scene: PackedScene = null

func _physics_process(_delta: float) -> void:
	if not shooting:
		handle_aiming()

func handle_aiming() -> void:
	target_player = get_tree().get_first_node_in_group("Players")
	if target_player == null: return
	var sprite = %Sprite
	var sign_x = sign(target_player.global_position.x - owner.global_position.x)
	var sign_y = sign(target_player.global_position.y + 4 - owner.global_position.y)
	match owner.pipe_direction:
		0:
			direction.x = sign_x
			direction.y = sign_y
		1:
			direction.x = -sign_x
			direction.y = -sign_y
		2:
			direction.x = sign_y
			direction.y = -sign_x
		3:
			direction.x = -sign_y
			direction.y = sign_x
	sprite.scale.x = direction.x
	if shooting:
		sprite.play("ShootUp" if direction.y == -1 else "ShootDown")
	else:
		sprite.play("AimUp" if direction.y == -1 else "AimDown")

func shoot() -> void:
	shooting = true
	for i in get_meta("shoot_amount", 1):
		handle_aiming()
		spawn_fireball()
		await get_tree().create_timer(0.25, false).timeout
	await get_tree().create_timer(1, false).timeout
	shooting = false

func spawn_fireball() -> void:
	var node = fireball_scene.instantiate()
	node.global_position = %Sprite.global_position
	var shoot_direction = node.global_position.direction_to(target_player.global_position)
	node.direction = shoot_direction
	owner.add_sibling(node)
