extends Control


func on_item_selected(index: int) -> void:
	for i in %Guides.get_children():
		i.hide()
	%Guides.get_child(index).show()
