extends StaticBody2D

@export var auto_activate := true

var active := false

static var taken := false

func _ready() -> void:
	$Camera2D.global_position = global_position
	$NinePatchRect.size = get_viewport().get_visible_rect().size
	$NinePatchRect.position = -($NinePatchRect.size / 2)

func level_start() -> void:
	if auto_activate:
		active = true
		activate()

func activate() -> void:
	for i in 2:
		$Camera2D.global_position = global_position
		await get_tree().physics_frame
		$Camera2D.enabled = true
		$Camera2D.make_current()

func start_moving() -> void:
	level_start()
	CameraHandler.solid_cam_bounds = true

func ended() -> void:
	CameraHandler.solid_cam_bounds = false
	await get_tree().process_frame
	$Camera2D.make_current()

func _physics_process(delta: float) -> void:
	$Camera2D.global_position = lerp($Camera2D.global_position, global_position, delta * 5)

func toggle() -> void:
	active = !active
	if active:
		transition_to_self()
	else:
		call_deferred("return_to_old_camera")

func return_to_old_camera() -> void:
	if taken:
		return
	var trans_cam = Camera2D.new()
	get_tree().get_first_node_in_group("Players").recenter_camera()
	for i in ["limit_left", "limit_right", "limit_top", "limit_bottom"]:
		trans_cam.set(i, $Camera2D.get(i))
	get_tree().get_first_node_in_group("Players").camera.add_child(trans_cam)
	trans_cam.make_current()
	trans_cam.position = trans_cam.to_local(global_position)
	trans_cam.reset_physics_interpolation()
	trans_cam.reset_smoothing()
	await create_tween().set_trans(Tween.TRANS_CUBIC).tween_property(trans_cam, "position", Vector2.ZERO, 0.25).finished
	get_tree().get_first_node_in_group("Players").camera_make_current()
	trans_cam.queue_free()

func transition_to_self() -> void:
	taken = true
	var trans_cam = Camera2D.new()
	for i in ["limit_left", "limit_right", "limit_top", "limit_bottom"]:
		trans_cam.set(i, $Camera2D.get(i))
	add_child(trans_cam)
	var old_cam = get_viewport().get_camera_2d()
	trans_cam.make_current()
	trans_cam.global_position = (old_cam.get_screen_center_position())
	trans_cam.reset_physics_interpolation()
	trans_cam.reset_smoothing()
	await create_tween().set_trans(Tween.TRANS_CUBIC).tween_property(trans_cam, "position", Vector2.ZERO, 0.25).finished
	activate()
	trans_cam.queue_free()
	taken = false

func _exit_tree() -> void:
	taken = false
