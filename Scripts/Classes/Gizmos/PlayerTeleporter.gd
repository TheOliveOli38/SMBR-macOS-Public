extends Node2D

func teleport_player() -> void:
	for i: Player in get_tree().get_nodes_in_group("Players"):
		i.teleport_player(global_position + Vector2(0, 8))
