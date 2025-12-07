class_name SignalExposer
extends Node2D

signal signal_connected

signal pulse_emitted
signal powered_on
signal powered_off

signal recieved_pulse
signal recieved_power
signal lost_power

var turned_on := false

enum ConnectorType{INPUT, OUTPUT, IN_OUTPUT}
@export var type := ConnectorType.INPUT

var editing := false

var has_input := false
var has_output := false
var total_inputs := 0

@export_storage var connections := []
@export var do_animation := true

var wire_node: Node2D = null
var save_string := ""

func _ready() -> void:
	set_visibility_layer_bit(0, false)
	set_visibility_layer_bit(1, true)
	add_to_group("SignalExposers")
	save_string = owner.get_meta("save_string", "")
	if save_string != "":
		apply_string(save_string)
		owner.remove_meta("save_string")
	process_mode = Node.PROCESS_MODE_ALWAYS
	show_behind_parent = true
	owner.z_index = -5
	z_index = -10
	top_level = true
	global_position = owner.global_position
	await get_tree().process_frame
	connect_pre_existing_signals()
	queue_redraw()

func _process(_delta: float) -> void:
	if editing:
		queue_redraw()

func _draw() -> void:
	if editing:
		draw_square_line(Vector2.ZERO, get_local_mouse_position())
	for x in connections:
		var target_node = get_node_from_tile(x[0], x[1])
		draw_square_line(Vector2.ZERO, to_local(target_node.global_position))

func draw_square_line(from := Vector2.ZERO, to := Vector2.ZERO) -> void:
	var colour = Color.RED
	if turned_on:
		colour = Color.GREEN
	from = from.snapped(Vector2(16, 16))
	to = to.snapped(Vector2(16, 16))
	var dist_x = abs(from.x - to.x)
	var dist_y = abs(from.y - to.y)
	if dist_x == dist_y and dist_x > 16:
		draw_dashed_line(from, to, colour, 1.5, 2.0, false)
	elif dist_x > dist_y:
		draw_dashed_line(from, Vector2(to.x, from.y), colour, 1)
		draw_dashed_line(Vector2(to.x, from.y), to, colour, 1)
	else:
		draw_dashed_line(from, Vector2(from.x, to.y), colour, 1)
		draw_dashed_line(Vector2(from.x, to.y), to, colour, 1)

func begin_connecting() -> void:
	update_animation(1.0, 1.2)
	editing = true
	await signal_connected
	editing = false
	update_animation(1.2, 1.0)
	queue_redraw()

func turn_on() -> void:
	update_animation(1.0, 1.2)
	powered_on.emit()
	turned_on = true
	queue_redraw()

func turn_off() -> void:
	update_animation(1.2, 1.0)
	powered_off.emit()
	turned_on = false
	queue_redraw()

func emit_pulse() -> void:
	update_animation(1.2, 1.0)
	pulse_emitted.emit()
	turned_on = true
	queue_redraw()
	await get_tree().create_timer(0.1, false).timeout
	turned_on = false
	queue_redraw()

func connect_pre_existing_signals() -> void:
	for i in connections:
		connect_to_node(i)

func connect_to_node(node_to_recieve := []) -> void:
	has_output = true
	var node: Node = get_node_from_tile(node_to_recieve[0], node_to_recieve[1])
	pulse_emitted.connect(node.get_node("SignalExposer").recieved_pulse.emit)
	powered_on.connect(node.get_node("SignalExposer").recieved_power.emit)
	powered_off.connect(node.get_node("SignalExposer").lost_power.emit)
	node.get_node("SignalExposer").has_input = true
	node.get_node("SignalExposer").total_inputs += 1
	node.get_node("SignalExposer").update_animation(1.2, 1.0, true)
	node.tree_exiting.connect(remove_node_connection.bind(node_to_recieve))
	tree_exiting.connect(node.get_node("SignalExposer").input_removed)
	if connections.has(node_to_recieve) == false:
		connections.append(node_to_recieve.duplicate())
	signal_connected.emit()

func remove_node_connection(node := []) -> void:
	if is_inside_tree():
		connections.erase(node)
		queue_redraw()
	if connections.is_empty():
		has_output = false

func input_removed() -> void:
	total_inputs -= 1
	if total_inputs <= 0:
		has_input = false

func get_string() -> String:
	var entity_string := ""
	for i in connections:
		entity_string += ",&"
		entity_string += str(i[0]) + "," + str(i[1].x) + "," + str(i[1].y)
	return entity_string

func apply_string(string := "") -> void:
	print(string)
	var arr := []
	if string.contains("&"):
		string = string.substr(string.find("&"))
		arr = string.split("&", false)
	for i in arr:
		var signal_arr = i.split(",")
		connections.append([int(signal_arr[0]), Vector2i(int(signal_arr[1]), int(signal_arr[2]))])

func get_node_from_tile(layer_num := 0, tile_position := Vector2i.ZERO) -> Node:
	for i in get_tree().get_nodes_in_group("SignalExposers"):
		print([i.owner, i.owner.get_meta("tile_position", i.owner.get_parent())])
		if i.owner.get_meta("tile_position", Vector2i.ZERO) == tile_position and i.owner.get_parent() == Global.current_level.get_node("EntityLayer" + str(layer_num + 1)):
			return i.owner
	return null

func update_animation(from := 1.2, to := 1.0, force := false) -> void:
	if (do_animation == false or is_visible_in_tree() == false) and not force:
		return
	owner.scale = Vector2(from, from)
	create_tween().set_trans(Tween.TRANS_CIRC).tween_property(owner, "scale", Vector2(to, to), 0.15)
