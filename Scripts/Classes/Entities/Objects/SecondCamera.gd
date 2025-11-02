extends StaticBody2D

func _ready() -> void:
	$Camera2D.global_position = global_position
	$NinePatchRect.size = get_viewport().get_visible_rect().size
	$NinePatchRect.position = -($NinePatchRect.size / 2)

func activate() -> void:
	for i in 2:
		$Camera2D.global_position = global_position
		await get_tree().physics_frame
		$Camera2D.enabled = true
		$Camera2D.make_current()

func ended() -> void:
	$Camera2D.position_smoothing_enabled = false
	$Camera2D.enabled = true
	$Camera2D.make_current()

func _physics_process(delta: float) -> void:
	$Camera2D.global_position = lerp($Camera2D.global_position, global_position, delta * 5)
