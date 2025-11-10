class_name Projectile
extends Enemy

@export var is_friendly := false
@export var PARTICLE := load("") 
@export var SFX_COLLIDE := "bump"
@export var DESTROY_ON_HIT := false

@export var HAS_COLLISION := false
@export var GROUND_BOUNCE := false
@export var WALL_BOUNCE := false
@export var CEIL_BOUNCE := false

@export var COLLECT_COINS := false

@export var LIFETIME := -1
@export var MOVE_SPEED := 0
@export var DECEL := 0
@export var GRAVITY := 0
@export var BOUNCE_HEIGHT := 0
@export var MAX_FALL_SPEED := 280.0

func _ready() -> void:
	if not HAS_COLLISION: $Collision.disabled = true
	if LIFETIME >= 0:
		await get_tree().create_timer(LIFETIME).timeout
		hit(true, true)

func _physics_process(delta: float) -> void:
	$Sprite.flip_h = direction == 1
	handle_movement(delta)
	handle_collection()

func handle_movement(delta: float) -> void:
	var CUR_GRAVITY = GRAVITY * (Global.entity_gravity * 0.1)
	velocity.y += (CUR_GRAVITY / delta) * delta
	velocity.y = clamp(velocity.y, -INF, MAX_FALL_SPEED)
	if is_on_floor():
		if GROUND_BOUNCE: velocity.y = -BOUNCE_HEIGHT
		else: hit()
	if is_on_ceiling():
		if CEIL_BOUNCE: velocity.y = BOUNCE_HEIGHT
		else: hit()
	if is_on_wall():
		if WALL_BOUNCE:
			direction *= -1
		else: hit()
	MOVE_SPEED = move_toward(MOVE_SPEED, 0, (DECEL / delta) * delta)
	velocity.x = MOVE_SPEED * direction
	move_and_slide()


func damage_player(player: Player) -> void:
	if !is_friendly:
		player.damage(damage_type if damage_type != "Normal" else "")

func hit(play_sfx := true, force_destroy := false) -> void:
	if play_sfx and SFX_COLLIDE != "":
		AudioManager.play_sfx(SFX_COLLIDE, global_position)
	summon_explosion()
	if DESTROY_ON_HIT or force_destroy:
		queue_free()

func summon_explosion() -> void:
	if PARTICLE is PackedScene and PARTICLE.can_instantiate():
		var node = PARTICLE.instantiate()
		node.global_position = global_position
		add_sibling(node)

func handle_collection() -> void:
	if COLLECT_COINS:
		var areas = get_node_or_null("Hitbox").get_overlapping_areas()
		for i in areas:
			if i.owner.is_in_group("Coins"): i.owner.collect()
