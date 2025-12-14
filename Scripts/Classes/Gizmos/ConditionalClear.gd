class_name ConditionalClear
extends Node2D

@export_enum("Validate", "Fail") var on_power := 0

static var valid := true

func on_level_start() -> void:
	valid = on_power

func powered() -> void:
	if on_power == 0:
		validate()
	else:
		ruin()

func validate() -> void:
	valid = true

func ruin() -> void:
	valid = false
