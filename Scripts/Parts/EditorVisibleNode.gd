extends Node2D

func _enter_tree() -> void:
	hide()

func _process(delta: float) -> void:
	hide()

func _physics_process(delta: float) -> void:
	hide()

func _ready() -> void:
	hide()

func update() -> void:
	visible = !LevelEditor.playing_level and Global.current_game_mode == Global.GameMode.LEVEL_EDITOR
