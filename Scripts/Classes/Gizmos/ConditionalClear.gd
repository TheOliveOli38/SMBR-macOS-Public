class_name ConditionalClear
extends Node2D

@export_enum("Validate", "Fail") var on_power := 0

static var valid := true
static var checked := false

func on_level_start() -> void:
	if checked == false:
		valid = on_power
	checked = true

func powered() -> void:
	if on_power == 0:
		validate()
	else:
		ruin()

func validate() -> void:
	valid = true

func ruin() -> void:
	valid = false
