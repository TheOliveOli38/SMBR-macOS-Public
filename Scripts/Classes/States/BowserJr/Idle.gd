extends State

func enter(_msg := {}) -> void:
	%Sprite.play("Idle")
	await wait(0.5)
	while choose_attack() == false:
		await wait(0.5)

func physics_update(delta: float) -> void:
	%Movement.handle_movement(delta)

func choose_attack() -> bool:
	var chosen_state = ["Fire", "Hop", "Fire", "Hop", "GroundPound"].pick_random()
	if chosen_state in ["GroundPound", "Hop"] and owner.is_on_floor() == false:
		return false
	state_machine.transition_to(chosen_state)
	return true
