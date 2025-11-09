extends PlayerState

func enter(_msg := {}) -> void:
	player.can_hurt = false
	player.has_jumped = false
	player.crouching = false
	player.in_cutscene = true
	player.get_node("CameraCenterJoint/RightWall").set_collision_layer_value(1, false)

func physics_update(delta: float) -> void:
	if player.is_posing:
		player.velocity.x = 0
		return
	player.input_direction = 1
	player.can_run = false
	player.normal_state.handle_movement(delta)
	player.normal_state.handle_animations()

func _physics_process(_delta: float) -> void:
	# SkyanUltra: Moved PoseDoor behavior to LevelExit for easier access and easier sorting
	# of player behavior. Additionally added similar behavior for Toad and Peach NPCs in
	# castle levels.
	if player.in_cutscene:
		for i: Node2D in get_tree().get_nodes_in_group("EndCastles"):
			player.speed_mult = player.physics_params("FLAG_SPEED_MULT", player.ENDING_PARAMETERS)
			player.accel_mult = player.physics_params("FLAG_ACCEL_MULT", player.ENDING_PARAMETERS)
			var pose_position = i.global_position + Vector2(player.physics_params("DOOR_POSE_OFFSET", player.ENDING_PARAMETERS), 0)
			if (player.global_position >= pose_position and player.global_position <= pose_position + Vector2(24, 0)) and player.can_pose_anim and player.sprite.sprite_frames.has_animation("PoseDoor"):
				player.is_posing = true; player.can_pose_anim = false
				player.global_position = pose_position
				player.play_animation("PoseDoor")
				player.sprite.animation_finished.connect(on_pose_finished.bind())
				player.sprite.animation_looped.connect(on_pose_finished.bind())
		for i: Node2D in get_tree().get_nodes_in_group("CastleNPCs"):
			var pose_type; var pose_offset
			if i.play_end_music:
				pose_type = "PosePeach"; pose_offset = Vector2(player.physics_params("PEACH_POSE_OFFSET", player.ENDING_PARAMETERS), 0)
				player.speed_mult = player.physics_params("PEACH_SPEED_MULT", player.ENDING_PARAMETERS)
				player.accel_mult = player.physics_params("PEACH_ACCEL_MULT", player.ENDING_PARAMETERS)
			else:
				pose_type = "PoseToad"; pose_offset = Vector2(player.physics_params("TOAD_POSE_OFFSET", player.ENDING_PARAMETERS), 0)
				player.speed_mult = player.physics_params("TOAD_SPEED_MULT", player.ENDING_PARAMETERS)
				player.accel_mult = player.physics_params("TOAD_ACCEL_MULT", player.ENDING_PARAMETERS)
			var pose_position = i.global_position + pose_offset
			if (player.global_position >= pose_position and player.global_position <= pose_position + Vector2(24, 0)) and not player.is_posing:
				player.velocity.x = 0
				player.global_position = pose_position
				player.is_posing = true
				player.normal_state.handle_animations()
			if player.can_pose_castle_anim:
				player.can_pose_castle_anim = false
				player.play_animation(pose_type)

func on_pose_finished() -> void:
	player.is_posing = false
	player.z_index = -2
