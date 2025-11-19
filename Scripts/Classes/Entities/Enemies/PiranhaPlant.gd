extends Enemy

@export var player_range := 24

@export_enum("Up", "Down", "Left", "Right") var pipe_direction := 0

@export var rise_animation := "Rise"

@export var upside_down_hitbox: Node2D = null

func _enter_tree() -> void:
	$Animation.play("Hide")

func _ready() -> void:
	upside_down_hitbox.set_deferred("disabled", is_equal_approx(abs(global_rotation_degrees), 180) == false)
	$Timer.start()

func on_timeout() -> void:
	upside_down_hitbox.set_deferred("disabled", is_equal_approx(abs(global_rotation_degrees), 180) == false)
	var player = get_tree().get_first_node_in_group("Players")
	if pipe_direction < 2:
		if abs(player.global_position.x - global_position.x) >= player_range:
			$Animation.play(rise_animation)
	elif (abs(player.global_position.y - global_position.y) >= player_range and abs(player.global_position.x - global_position.x) >= player_range * 2):
			$Animation.play(rise_animation)
	if $Animation.is_playing():
		await $Animation.animation_finished
	$Timer.start()


func on_killed(gib_direction: int) -> void:
	if Settings.file.visuals.extra_particles == 1:
		$GibSpawner.gib_type = 2
	$GibSpawner.summon_gib(gib_direction)
