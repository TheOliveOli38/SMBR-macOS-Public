extends PlayerState

var can_fall := false

func enter(msg := {}) -> void:
	if not player.DEATH_COLLISION:
		player.z_index = 20
		for i in 16:
			player.set_collision_mask_value(i + 1, false)
	can_fall = false
	player.velocity = Vector2.ZERO
	player.stop_all_timers()
	if player.DEATH_HANG_TIMER > 0: # SkyanUltra: Not sure if this is needed, but its just there to avoid weird behavior with negative values.
		await get_tree().create_timer(player.DEATH_HANG_TIMER).timeout
	can_fall = true
	player.gravity = player.DEATH_FALL_GRAVITY
	if msg["Pit"] == false: 
		player.velocity = Vector2(player.DEATH_X_VELOCITY, -player.DEATH_JUMP_HEIGHT * player.gravity_vector.y) # nabbup : Flip death gravity when upside down

func physics_update(delta: float) -> void:
	player.sprite.speed_scale = 1
	player.play_animation(get_animation_name()) # SkyanUltra: Consolidated animation behavior into get_animation_name()
	if can_fall:
		# nabbup : Flip death gravity when upside down
		player.velocity.y += (player.JUMP_GRAVITY / delta) * delta * player.gravity_vector.y
		player.velocity.y = clamp(player.velocity.y, -player.MAX_DEATH_FALL_SPEED, player.MAX_DEATH_FALL_SPEED) # wish this could be better than just substituting -INF but you can't win em all ~ nabbup
		player.move_and_slide()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump_0"):
			player.death_load()
		if player.is_actually_on_floor():
			deceleration(delta)

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
	player.velocity.x = move_toward(player.velocity.x, 0, (player.DEATH_DECEL / delta) * delta)
