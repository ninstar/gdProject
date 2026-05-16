@tool
extends EditorPlugin


const IconTextureInspector = preload("inspector.gd")
const IconTexturePreviewer = preload("previewer.gd")
const IconTextureDialog = preload("dialog.gd")


var editing_resource: IconTexture = null
var previewer: IconTexturePreviewer = null
var inspector: IconTextureInspector = null
var dialog_layout: Dictionary = {}


func _enter_tree() -> void:
	add_custom_type("IconTexture", "AtlasTexture", preload("icon_texture.gd"), preload("icon_texture.svg"))
	
	# Inspector
	inspector = IconTextureInspector.new()
	inspector.button_pressed.connect(_on_inspector_button_pressed)
	add_inspector_plugin(inspector)
	
	# Preview generator
	previewer = IconTexturePreviewer.new()
	EditorInterface.get_resource_previewer().add_preview_generator(previewer)


func _exit_tree():
	EditorInterface.get_resource_previewer().remove_preview_generator(previewer)
	remove_inspector_plugin(inspector)
	remove_custom_type("IconTexture")

# Signals

func _on_inspector_button_pressed(icon_texture: IconTexture) -> void:
	if icon_texture != null:
		editing_resource = icon_texture
		
		var dialog: IconTextureDialog = preload("./dialog.tscn").instantiate()
		dialog.active = true
		dialog.layout = dialog_layout
		
		# IconTexture properties
		dialog.icon_theme_resource = editing_resource.theme
		dialog.theme_type = editing_resource.theme_type
		dialog.icon_name = editing_resource.icon_name
		
		# Signals
		dialog.icon_selected.connect(_on_dialog_icon_selected)
		dialog.layout_save_requested.connect(_on_dialog_layout_save_requested)
		
		if dialog_layout.has(&"window_rect"):
			EditorInterface.popup_dialog(dialog, dialog_layout[&"window_rect"])
		else:
			EditorInterface.popup_dialog_centered(dialog)


func _on_dialog_icon_selected(new_theme_type: StringName, new_icon_name: StringName) -> void:
	if editing_resource != null:
		
		# Add undo/redo action
		var undo_redo: EditorUndoRedoManager = get_undo_redo()
		undo_redo.create_action("Set theme_type and icon_name")
		undo_redo.add_do_property(editing_resource, &"theme_type", new_theme_type)
		undo_redo.add_do_property(editing_resource, &"icon_name", new_icon_name)
		undo_redo.add_undo_property(editing_resource, &"theme_type", editing_resource.theme_type)
		undo_redo.add_undo_property(editing_resource, &"icon_name", editing_resource.icon_name)
		undo_redo.commit_action()
		
		# Update IconTexture
		editing_resource.theme_type = new_theme_type
		editing_resource.icon_name = new_icon_name


func _on_dialog_layout_save_requested(new_layout: Dictionary) -> void:
	dialog_layout = new_layout
