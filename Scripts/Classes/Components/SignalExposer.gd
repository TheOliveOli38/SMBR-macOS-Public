class_name SignalExposer
extends Node2D

signal signal_connected

signal pulse_emitted
signal powered_on
signal powered_off

signal recieved_pulse
signal recieved_power
signal lost_power

enum ConnectorType{INPUT, OUTPUT, IN_OUTPUT}
@export var type := ConnectorType.INPUT

var editing := false

var has_input := false
var has_output := false
var total_inputs := 0

@export_storage var connections := []
@export var do_animation := true

var wire_node: Node2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	show_behind_parent = true
	owner.z_index = -5
	z_index = -10
	top_level = true
	global_position = owner.global_position
	add_child(wire_node)
	await get_tree().create_timer(0.1).timeout
	connect_pre_existing_signals()
	queue_redraw()

func _process(_delta: float) -> void:
	if editing:
		queue_redraw()

func _draw() -> void:
	if editing:
		draw_line(Vector2.ZERO, get_local_mouse_position(), Color.RED, 2, true)
	for x in connections:
		var target_node = get_node_from_index(x[0], x[1])
		draw_line(Vector2.ZERO, to_local(target_node.global_position), Color.RED, 1, true)

func begin_connecting() -> void:
	editing = true
	await signal_connected
	editing = false
	queue_redraw()

func turn_on() -> void:
	update_animation(1.0, 1.2)
	powered_on.emit()

func turn_off() -> void:
	update_animation(1.2, 1.0)
	powered_off.emit()

func emit_pulse() -> void:
	update_animation(1.2, 1.0)
	pulse_emitted.emit()

func connect_pre_existing_signals() -> void:
	for i in connections:
		connect_to_node(i)

func connect_to_node(node_to_recieve := []) -> void:
	has_output = true
	var node: Node = get_node_from_index(node_to_recieve[0], node_to_recieve[1])
	pulse_emitted.connect(node.get_node("SignalExposer").recieved_pulse.emit)
	powered_on.connect(node.get_node("SignalExposer").recieved_power.emit)
	powered_off.connect(node.get_node("SignalExposer").lost_power.emit)
	node.get_node("SignalExposer").has_input = true
	node.get_node("SignalExposer").total_inputs += 1
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

func get_node_from_index(layer_num := 0, tile_index := 0) -> Node:
	if Global.level_editor != null:
		return Global.level_editor.entity_layer_nodes[layer_num].get_child(tile_index)
	else:
		return Global.current_level.get_node("EntityTiles" + str(layer_num + 1)).get_child(tile_index)

func update_animation(from := 1.2, to := 1.0) -> void:
	if do_animation == false:
		return
	owner.scale = Vector2(from, from)
	create_tween().set_trans(Tween.TRANS_CIRC).tween_property(owner, "scale", Vector2(to, to), 0.15)
