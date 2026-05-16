extends EditorInspectorPlugin


signal button_pressed(icon_texture: IconTexture)


func _can_handle(object: Object) -> bool:
	if object is IconTexture:
		return true
	
	return false


func _parse_property(object: Object, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	if name == "atlas":
		var button := Button.new()
		button.text = "Icons"
		button.icon = EditorInterface.get_editor_theme().get_icon(&"ImageTexture", &"EditorIcons")
		button.theme_type_variation = &"InspectorActionButton"
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(func() -> void: button_pressed.emit(object as IconTexture))
		add_custom_control(button)
		
		return true
	
	return false
