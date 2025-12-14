class_name LevelEditorToggleDetection
extends Node

signal toggled

signal level_start
signal editor_start

func _ready() -> void:
	if is_instance_valid(Global.level_editor):
		if Global.level_editor.current_state != LevelEditor.EditorState.PLAYTESTING:
			Global.level_editor.level_start.connect(toggled.emit)
			Global.level_editor.level_start.connect(level_start.emit)
			Global.level_editor.editor_start.connect(editor_start.emit)
			Global.level_editor.editor_start.connect(toggled.emit)
			return
	level_start.emit()
