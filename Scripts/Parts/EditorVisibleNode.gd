extends Node2D


func _ready() -> void:
	update()

func update() -> void:
	visible = !LevelEditor.playing_level and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR
