extends Node2D

@export var coin_scene: PackedScene = null

func spawn_coin() -> void:
	var node = coin_scene.instantiate()
	node.global_position = global_position
	add_sibling(node)
	queue_free()


func on_player_entered(_player: Player) -> void:
	hide()
	await get_tree().create_timer(0.25, false).timeout
	AudioManager.play_sfx("hidden_coin", global_position)
	spawn_coin()
