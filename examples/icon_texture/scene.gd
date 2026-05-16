extends MarginContainer


@export var icon_texture: IconTexture

@onready var theme_type: LineEdit = %ThemeType
@onready var icon_name: LineEdit = %IconName
@onready var action_icons: GridContainer = %ActionIcons
@onready var node_icons: ItemList = %NodeIcons
@onready var resource_icons: HFlowContainer = %ResourceIcons


func _ready() -> void:
	for child: Node in action_icons.get_children():
		if child is Button:
			child.pressed.connect(_on_action_button_pressed.bind(child))
	
	for child: Node in resource_icons.get_children():
		if child is Button:
			child.pressed.connect(_on_resource_button_pressed.bind(child))


func _on_theme_type_text_changed(new_text: String) -> void:
	icon_texture.theme_type = new_text


func _on_icon_name_text_changed(new_text: String) -> void:
	icon_texture.icon_name = new_text


func _on_node_icons_item_selected(index: int) -> void:
	theme_type.text = &"Nodes"
	icon_name.text = node_icons.get_item_text(index)

	icon_texture.theme_type = theme_type.text
	icon_texture.icon_name = icon_name.text


func _on_action_button_pressed(button: Button) -> void:
	theme_type.text = &"Actions"
	icon_name.text = button.name.to_snake_case()
	
	icon_texture.theme_type = theme_type.text
	icon_texture.icon_name = icon_name.text


func _on_resource_button_pressed(button: Button) -> void:
	theme_type.text = &"Resources"
	icon_name.text = button.name.to_snake_case()

	icon_texture.theme_type = theme_type.text
	icon_texture.icon_name = icon_name.text
