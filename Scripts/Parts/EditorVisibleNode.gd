extends Node

func _ready() -> void:
	print(name)
	update()
	if Global.level_editor != null:
		Global.level_editor.editor_start.connect(update)
		Global.level_editor.level_start.connect(update)

func update() -> void:
	var visible = (!LevelEditor.playing_level and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR)
	set("visible", visible)
