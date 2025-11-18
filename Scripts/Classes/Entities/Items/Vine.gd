class_name Vine
extends Node2D

@export var top_point := -256

const SPEED := 32.0
@onready var collision: CollisionShape2D = $Hitbox/Collision
@onready var visuals: NinePatchRect = $Visuals
@onready var hitbox: Area2D = $Hitbox


@export var cutscene = false
@export var can_tele := true

var can_stop := true

signal stopped

var can_grow := false

@export_range(2, 16) var length := 3.0

func _ready() -> void:
	if cutscene:
		do_cutscene()
	if has_meta("block_item"):
		$SFX.play()
		can_grow = true
		global_position.y -= 1

func do_cutscene() -> void:
	$SFX.play()
	can_grow = true
	for i in get_tree().get_nodes_in_group("Players"):
		i.global_position = global_position + Vector2(0, 24)
		i.hide()
		i.state_machine.transition_to("Freeze")
	await stopped
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.show()
		for x in [1, 2]:
			i.set_collision_mask_value(x, false)
		i.state_machine.transition_to("Climb", {"Vine" = self, "Cutscene" = true})
		var climb_state = i.get_node("States/Climb")
		climb_state.climb_direction = -1
		await get_tree().create_timer(1.5, false).timeout
		i.direction = -1
		climb_state.climb_direction = 0
		await get_tree().create_timer(0.5, false).timeout
		i.state_machine.transition_to("Normal")
		for x in [1, 2]:
			i.set_collision_mask_value(x, true)

func _physics_process(delta: float) -> void:
	if global_position.y >= top_point and can_grow:
		global_position.y -= SPEED * delta
		visuals.size.y += SPEED * delta
		collision.shape.size.y += SPEED * delta
		collision.position.y += (SPEED / 2) * delta
	elif can_stop:
		can_stop = false
		stopped.emit()
	
	handle_player_interaction(delta)
	$WarpHitbox/CollisionShape2D.set_deferred("disabled", global_position.y > top_point)

func handle_player_interaction(delta: float) -> void:
	for i in hitbox.get_overlapping_areas():
		if i.owner is Player:
			if Global.player_action_pressed("move_up", i.owner.player_id) and i.owner.state_machine.state.name == "Normal":
				i.owner.state_machine.transition_to("Climb", {"Vine": self})
			elif i.owner.state_machine.state.name == "Climb" and global_position.y >= top_point and can_grow:
				i.owner.global_position.y -= SPEED * delta


func on_player_entered(_player: Player) -> void:
	if can_tele == false:
		return
	Level.vine_return_level = Global.current_level.scene_file_path
	if Global.level_editor_is_playtesting():
		Global.level_editor.transition_to_sublevel(CoinHeavenWarpPoint.subarea_to_warp_to)
	elif Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
		Global.transition_to_scene(NewLevelBuilder.sub_levels[CoinHeavenWarpPoint.subarea_to_warp_to])
	else:
		Global.transition_to_scene(Level.vine_warp_level)


func on_area_exited(area: Area2D) -> void:
	if area.owner is Player and area.name != "HammerHitbox":
		if area.owner.state_machine.state.name == "Climb":
			area.owner.state_machine.transition_to("Normal")
