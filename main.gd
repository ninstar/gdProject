extends Node


const LIST := preload("res://examples/list.gd")


@onready var start: Control = $UI/Start
@onready var menu: MenuButton = $UI/Header/Menu
@onready var icon: TextureRect = $UI/Header/Demo/Box/Icon
@onready var title: Label = $UI/Header/Demo/Box/Title

var current_demo: Node


func _ready() -> void:
	var title: String = ProjectSettings.get_setting("application/config/name", "")
	DisplayServer.window_set_title(title)
	
	var popup: PopupMenu = menu.get_popup()
	popup.index_pressed.connect(_on_menu_index_pressed)
	var list := LIST.new()
	var index: int = 0
	for dict: Dictionary in list.get_list():
		popup.add_icon_item(load(dict.get(&"icon", null)), dict.get(&"title", ""), index)
		popup.set_item_metadata(index, dict.get(&"path", ""))
		index += 1


func _on_menu_index_pressed(index: int) -> void:
	if is_instance_valid(current_demo):
		var queued := current_demo
		queued.queue_free()
	
	var popup: PopupMenu = menu.get_popup()
	var path: String = popup.get_item_metadata(index)
	if not path.is_empty():
		var scene: PackedScene = load("res://examples/%s/demo.tscn" % path)
		current_demo = scene.instantiate()
		add_child(current_demo)
		move_child(current_demo, 0)
	
	icon.texture = popup.get_item_icon(index)
	title.text = popup.get_item_text(index)
	
	icon.visible = icon != null
	title.visible = not title.text.is_empty()
	
	start.visible = current_demo == null
