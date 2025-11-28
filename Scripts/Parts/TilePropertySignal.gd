class_name SignalProperty
extends Control

signal start_connecting()

var connections := 0
var node: Node = null

func _ready() -> void:
	$Connections.text = "Connections: (" + str(connections) + "):"

func start_connection() -> void:
	start_connecting.emit()

func node_selected() -> void:
	pass
