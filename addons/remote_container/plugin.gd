@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("RemoteContainer", "Container", preload("remote_container.gd"), preload("remote_container.svg"))


func _exit_tree():
	remove_custom_type("RemoteContainer")
