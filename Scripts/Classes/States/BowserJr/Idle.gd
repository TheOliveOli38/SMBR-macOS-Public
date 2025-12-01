extends State

func enter(_msg := {}) -> void:
	%Sprite.play("Idle")
	if await wait(0.5):
		choose_attack()

func physics_update(delta: float) -> void:
	%Movement.handle_movement(delta)

func choose_attack() -> void:
	state_machine.transition_to(["Fire", "Hop", "GroundPound"].pick_random())
