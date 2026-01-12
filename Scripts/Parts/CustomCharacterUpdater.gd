class_name CustomCharacterUpdater
extends Node

const BASE := {
	"name": "",
	"physics": {
		"PHYSICS_PARAMETERS": {
			"Default": {},
			"Small": {},
			"Big": {},
			"Fire": {},
		},
		"CLASSIC_PARAMETERS": {
			"Default": {},
			"Small": {},
			"Big": {},
			"Fire": {},
		},
		"ENDING_PARAMETERS": {
			"Default": {},
			"Small": {},
			"Big": {},
			"Fire": {},
		},
		"DEATH_PARAMETERS": {
			"Default": {}
		},
		"COSMETIC_PARAMETERS": {
			"Default": {},
			"Small": {},
			"Big": {},
			"Fire": {},
		},
	},
}

static func update_json(json := {}) -> Dictionary:
	var new_json = BASE.duplicate_deep()
	if json.has("physics"):
		for i in json.physics.keys():
			new_json.physics.PHYSICS_PARAMETERS.Default[i] = json.physics[i]
		new_json.physics.PHYSICS_PARAMETERS.Default.COLLISION_SIZE = [8 * json.big_hitbox_scale[0], 28 * json.big_hitbox_scale[1]] 
		new_json.physics.PHYSICS_PARAMETERS.Default.CROUCH_COLLISION_SIZE = [8 * json.big_hitbox_scale[0], 14 * json.big_hitbox_scale[1]]
		new_json.physics.PHYSICS_PARAMETERS.Small.COLLISION_SIZE = [8 * json.big_hitbox_scale[0], 14 * json.big_hitbox_scale[1]]
		new_json.physics.PHYSICS_PARAMETERS.Small.CROUCH_COLLISION_SIZE = [8 * json.big_hitbox_scale[0], 14 * json.big_hitbox_scale[1]]
	new_json.name = json.name
	return new_json
