extends PlayerState

var can_fall := false

func enter(msg := {}) -> void:
	if not death_params("collision"):
		player.z_index = 20
		for i in 16:
			player.set_collision_mask_value(i + 1, false)
	can_fall = false
	player.velocity = Vector2.ZERO
	player.stop_all_timers()
	if death_params("hang_timer") > 0: # SkyanUltra: Not sure if this is needed, but its just there to avoid weird behavior with negative values.
		await get_tree().create_timer(death_params("hang_timer")).timeout
	can_fall = true
	player.gravity = death_params("fall_gravity")
	if msg["Pit"] == false: 
		player.velocity = Vector2(death_params("x_velocity"), -death_params("jump_height") * player.gravity_vector.y) # nabbup : Flip death gravity when upside down

func physics_update(delta: float) -> void:
	player.sprite.speed_scale = 1
	player.play_animation(get_animation_name()) # SkyanUltra: Consolidated animation behavior into get_animation_name()
	if can_fall:
		# nabbup : Flip death gravity when upside down
		player.velocity.y += (death_params("fall_gravity") / delta) * delta * player.gravity_vector.y
		player.velocity.y = clamp(player.velocity.y, -death_params("max_fall_speed"), death_params("max_fall_speed")) # wish this could be better than just substituting -INF but you can't win em all ~ nabbup
		player.move_and_slide()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump_0"):
			player.death_load()
		if player.is_actually_on_floor():
			deceleration(delta)

func death_params(type: String):
	return player.DEATH_PARAMETERS[player.last_damage_source][type]

func get_animation_name():
	if can_fall:
		if player.is_actually_on_floor():
			if abs(player.velocity.x) >= 5 and not player.is_actually_on_wall():
				return "DieMove"
			else:
				return "DieIdle"
		elif player.velocity.y < 0:
			return "DieRise"
		else:
			return "DieFall"
	else:
		return "DieFreeze"

func deceleration(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0, (death_params("decel") / delta) * delta)
