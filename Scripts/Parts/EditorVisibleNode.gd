extends Node

func _ready() -> void:
	print(name)
	update()
	if Global.level_editor != null:
		Global.level_editor.editor_start.connect(update)
		Global.level_editor.level_start.connect(update)

func update() -> void:
	var visible = (Global.level_editor_is_editing())
	if Global.level_editor != null:
		visible = Global.level_editor.gizmos_visible or Global.level_editor_is_editing()
	set("visible", visible)
