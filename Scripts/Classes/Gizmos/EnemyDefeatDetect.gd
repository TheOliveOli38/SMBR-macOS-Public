extends Node2D

signal enemy_killed

var bind = enemy_killed.emit.unbind(1)

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	for i in get_parent().get_children():
		if i is Enemy:
			if i.killed.is_connected(bind) == false:
				i.killed.connect(bind)
