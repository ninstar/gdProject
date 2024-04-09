extends Node


const EXAMPLES := preload("examples.gd")


@onready var background: ColorRect = $Background
@onready var start: Control = $UI/Start
@onready var menu: MenuButton = $UI/Header/Menu
@onready var icon: TextureRect = $UI/Header/Demo/Box/Icon
@onready var title: Label = $UI/Header/Demo/Box/Title

var current_demo: Node
var opacity_tween: Tween


func _ready() -> void:
	var window_title: String = ProjectSettings.get_setting("application/config/name", "")
	DisplayServer.window_set_title(window_title)
	
	var popup: PopupMenu = menu.get_popup()
	popup.index_pressed.connect(_on_menu_index_pressed)
	var examples := EXAMPLES.new()
	var index: int = 0
	for dict: Dictionary in examples.get_list():
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
		var scene: PackedScene = load(path)
		current_demo = scene.instantiate()
		add_child(current_demo)
		move_child(current_demo, 1)
	
	icon.texture = popup.get_item_icon(index)
	title.text = popup.get_item_text(index)
	
	icon.visible = icon != null
	title.visible = not title.text.is_empty()
	
	start.visible = current_demo == null


func _on_opacity_pressed() -> void:
	if opacity_tween:
		opacity_tween.kill()
	
	opacity_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	opacity_tween.tween_property(background, ^"color:a", 0.5 if background.color.a > 0.75 else 1.0, 1.0)
