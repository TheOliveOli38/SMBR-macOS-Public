class_name FireDetection
extends Node

@export var hitbox: Area2D = null

signal fiery_object_hit(node: Node2D)

signal fireball_hit(fireball: FireBall)
signal burner_hit(burner: Node2D)
signal angry_sun_hit(sun: Node2D)
signal bowser_flame_hit(flame: Node2D)
signal podoboo_hit(podoboo: Node2D)

func _ready() -> void:
	if hitbox != null:
		hitbox = hitbox.duplicate()
		await owner.ready
		add_sibling(hitbox)
		hitbox.area_entered.connect(area_entered)
		hitbox.set_collision_mask_value(1, false)
		hitbox.set_collision_mask_value(11, true)

func area_entered(area: Area2D) -> void:
	var node = area.owner
	fiery_object_hit.emit(node)
	if node is FireBall or node is PlantFireball:
		fireball_hit.emit(node)
	elif node is Burner:
		burner_hit.emit(node)
	elif node is AngrySun:
		angry_sun_hit.emit(node)
	elif node is BowserFlame:
		bowser_flame_hit.emit(node)
	elif node is Podoboo:
		podoboo_hit.emit(node)
