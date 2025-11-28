class_name Broadcaster
extends Node2D

static var active_channels := []

@export_range(0, 99) var channel := 0
@export_enum("Send and Recieve", "Send Only", "Recieve Only") var mode := 0

signal recieved_signal

func _ready() -> void:
	await get_tree().create_timer(0.2, false).timeout
	check_channels()

func check_channels() -> void:
	if mode == 1:
		return
	if active_channels.has(channel):
		$Status.show()
		$Status.flip_v = true
		recieved_signal.emit()
		await get_tree().process_frame
		if active_channels.has(channel):
			active_channels.erase(channel)
		await get_tree().create_timer(0.5, false).timeout
		$Status.hide()

func emit_broadcast() -> void:
	if mode == 2:
		return
	$Status.show()
	$Status.flip_v = false
	$SignalExposer.update_animation()
	active_channels.append(channel)
	for i in get_tree().get_nodes_in_group("Broadcasters"):
		if i != self:
			i.check_channels()
	await get_tree().create_timer(0.5, false).timeout
	$Status.hide()
