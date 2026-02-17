extends State

var can_fall = true

var falling := false

var can_land := false

func enter(_msg := {}) -> void:
	can_fall = true
	falling = false
	can_land = false
	%Sprite.play("Jump")
	owner.velocity.x = 0
	owner.velocity.y = -300
	if await wait(0.5) == false:
		return
	%Sprite.play("GroundPoundAir")
	can_fall = false
	if await wait(0.5) == false:
		return
	can_land = true
	falling = true
	can_fall = true

func physics_update(delta: float) -> void:
	if can_fall:
		if falling:
			%Movement.apply_gravity(delta)
		%Movement.handle_movement(delta)
	if owner.is_on_floor() and can_land:
		%Sprite.play("GroundPoundLand")
		can_land = false
		AudioManager.play_global_sfx("cannon")
		get_tree().call_group("Players", "do_earthquake")
		Global.screen_shaker.shake_screen(8.0, 0.5)
		if await wait(0.5) == false:
			return
		state_machine.transition_to("Idle")
