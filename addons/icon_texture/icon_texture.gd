@tool
@icon("icon_texture.svg")

class_name IconTexture extends AtlasTexture


## A texture that draws an icon from a Theme resource.
##
## [Texture2D] resource that dynamically draws an icon property of a [Theme] resource
## by [member icon_name] and [member theme_type].[br][br]
## [b]Note:[/b] [b]IconTexture[/b] shares the same properties and limitations
## as [AtlasTexture].


## [Theme] object to use. If [code]null[/code], the property will fallback
## to [method ThemeDB.get_project_heme] and [method ThemeDB.get_default_theme]
## respectively.
@export var theme: Theme: get = get_theme, set = set_theme

## The [param name] of the icon.
@export var icon_name: StringName = &"": get = get_icon_name, set = set_icon_name

## The [param theme_type] that the icon property is part of.
@export var theme_type: StringName = &"": get = get_theme_type, set = set_theme_type


## Shorthand for setting [member theme_type], [member icon_name] and calling [method update_texture].
func set_icon(new_theme_type: StringName, new_icon_name: StringName) -> void:
	theme_type = new_theme_type
	icon_name = new_icon_name


## Updates the [member AtlasTexture.atlas] with an icon from the [member theme] object.[br][br]
## [b]Note:[/b] This method is is called automatically whenever [member theme], [member theme_type]
## or [member icon_name] are changed.
func update_texture() -> void:
	for current_theme: Theme in [theme, ThemeDB.get_project_theme(), ThemeDB.get_default_theme()]:
		if current_theme != null and current_theme.has_icon(icon_name, theme_type):
			atlas = current_theme.get_icon(icon_name, theme_type)
			return
	
	atlas = ThemeDB.fallback_icon


#region Virtual methods

func _init() -> void:
	update_texture()

#endregion
#region Getters & Setters

# Getters

func get_theme() -> Theme:
	return theme


func get_icon_name() -> StringName:
	return icon_name


func get_theme_type() -> StringName:
	return theme_type

# Setters

func set_theme(value: Theme) -> void:
	theme = value
	update_texture()
	emit_changed()


func set_icon_name(value: StringName) -> void:
	icon_name = value
	update_texture()
	emit_changed()


func set_theme_type(value: StringName) -> void:
	theme_type = value
	update_texture()
	emit_changed()

#endregion
