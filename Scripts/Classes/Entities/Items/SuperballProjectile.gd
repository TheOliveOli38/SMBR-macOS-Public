class_name SuperballProjectile
extends Projectile

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = direction
	handle_movement(delta)
