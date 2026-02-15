extends Node2D

@export var sfx := 0

func play_sfx() -> void:
	AudioManager.play_sfx(AudioManager.sfx_library.keys()[sfx], global_position)
	$SignalExposer.update_animation()
