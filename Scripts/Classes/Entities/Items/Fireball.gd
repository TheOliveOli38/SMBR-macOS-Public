class_name FireBall
extends CharacterBody2D

const CHARACTERS := ["Mario", "Luigi", "Toad", "Toadette"]

var character := "Mario"

var direction := 1
const FIREBALL_EXPLOSION = preload("res://Scenes/Prefabs/Particles/FireballExplosion.tscn")

@export var MOVE_SPEED := 220

func _physics_process(delta: float) -> void:
	$Sprite.scale.x = direction
	$Sprite/Animation.speed_scale = direction * 2
	handle_movement(delta)
