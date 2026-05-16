@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("RangeContainer", "ScrollContainer", preload("range_container.gd"), preload("range_container.svg"))


func _exit_tree():
	remove_custom_type("RangeContainer")
