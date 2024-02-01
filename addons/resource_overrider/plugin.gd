@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("ResourceOverrider", "ResourceOverrider", preload("resource_overrider.gd"), preload("resource_overrider.svg"))


func _exit_tree():
	remove_custom_type("ResourceOverrider")
