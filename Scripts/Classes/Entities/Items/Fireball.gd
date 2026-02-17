class_name FireBall
extends Projectile

const FIREBALL_EXPLOSION = preload("res://Scenes/Prefabs/Particles/FireballExplosion.tscn")

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = direction
	$Sprite/Animation.speed_scale = direction * 2
	handle_movement(delta)
