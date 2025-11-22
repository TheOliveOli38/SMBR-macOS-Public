extends Node2D

func _physics_process(delta: float) -> void:
	$VineJoint.global_position.y = 40
	$VineJoint/Vine.top_point = global_position.y

func _ready() -> void:
	if Global.level_editor_is_playtesting():
		$VineJoint/Vine.do_cutscene()
