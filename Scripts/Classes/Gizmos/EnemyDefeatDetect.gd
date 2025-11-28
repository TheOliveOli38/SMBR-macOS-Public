extends Node2D

signal enemy_killed

func _ready() -> void:
	pass

func get_enemies() -> void:
	for i in get_parent().get_children():
		if i is Enemy:
			i.killed.connect(enemy_killed.emit.unbind(1))
