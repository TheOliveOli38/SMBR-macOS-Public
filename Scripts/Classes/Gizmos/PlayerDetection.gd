extends Node2D

@export_range(1, 16) var size_x := 1
@export_range(1, 16) var size_y := 1

func _physics_process(_delta: float) -> void:
	$PlayerDetection.scale = Vector2(size_x, size_y)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-size_x / 2.0, -size_y / 2.0) * 16, Vector2(size_x, size_y) * 16), Color.WHITE, false, 1.0)
