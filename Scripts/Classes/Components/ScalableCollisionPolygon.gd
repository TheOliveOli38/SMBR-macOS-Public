@tool
extends CollisionPolygon2D

@export var offset := Vector2.ZERO
@export var hitbox := Vector2.ONE

var crouching := false

var sloped_floor_corner := false

func _physics_process(_delta: float) -> void:
	update()

func update() -> void:
	update_polygon()
	position = offset

func update_polygon() -> void:
	## Bottom Half
	polygon[5].x = -(hitbox.x / 2)
	polygon[6].x = -(hitbox.x / 2) + 2
	polygon[0].x = (hitbox.x / 2)
	polygon[7].x = (hitbox.x / 2) - 2
	
	## Top Half
	polygon[1].x = (hitbox.x / 2)
	polygon[4].x = -(hitbox.x / 2)
	
	polygon[2].x = (hitbox.x / 2) - 3
	polygon[3].x = -(hitbox.x / 2) + 3
	
	var corner_height := 0
	if sloped_floor_corner:
		corner_height = -3
	polygon[5].y = corner_height
	polygon[0].y = corner_height
	
	polygon[2].y = -hitbox.y
	polygon[3].y = -hitbox.y
	polygon[1].y = -hitbox.y + 6
	polygon[4].y = -hitbox.y + 6
