@tool
extends EditorPlugin


const ADDONS = {
	"nine_patch_sprite_2d": {
		"zip_url": "https://github.com/ninstar/Godot-NinePatchSprite2D/archive/refs/heads/main.zip",
		"addon_path": "res://addons/nine_patch_sprite_2d",
		"addon_config": "res://addons/nine_patch_sprite_2d/plugin.cfg",
		"addon_icon": "res://addons/nine_patch_sprite_2d/nine_patch_sprite_2d.svg",
		"example_path": "res://examples/nine_patch_sprite_2d",
		"example_scene": "res://examples/nine_patch_sprite_2d/scene.tscn",
	},
	"range_container": {
		"zip_url": "https://github.com/ninstar/Godot-RangeContainer/archive/refs/heads/main.zip",
		"addon_path": "res://addons/range_container",
		"addon_config": "res://addons/range_container/plugin.cfg",
		"addon_icon": "res://addons/range_container/range_container.svg",
		"example_path": "res://examples/range_container",
		"example_scene": "res://examples/range_container/scene.tscn",
	},
	"remote_container": {
		"zip_url": "https://github.com/ninstar/Godot-RemoteContainer/archive/refs/heads/main.zip",
		"addon_path": "res://addons/remote_container",
		"addon_config": "res://addons/remote_container/plugin.cfg",
		"addon_icon": "res://addons/remote_container/remote_container.svg",
		"example_path": "res://examples/remote_container",
		"example_scene": "res://examples/remote_container/scene.tscn",
	},
	"resource_overrider": {
		"zip_url": "https://github.com/ninstar/Godot-ResourceOverrider/archive/refs/heads/main.zip",
		"addon_path": "res://addons/resource_overrider",
		"addon_config": "res://addons/resource_overrider/plugin.cfg",
		"addon_icon": "res://addons/resource_overrider/resource_overrider.svg",
		"example_path": "res://examples/resource_overrider",
		"example_scene": "res://examples/resource_overrider/scene.tscn",
	},
	"icon_texture": {
		"zip_url": "https://github.com/ninstar/Godot-IconTexture/archive/refs/heads/main.zip",
		"addon_path": "res://addons/icon_texture",
		"addon_config": "res://addons/icon_texture/plugin.cfg",
		"addon_icon": "res://addons/icon_texture/icon_texture.svg",
		"example_path": "res://examples/icon_texture",
		"example_scene": "res://examples/icon_texture/scene.tscn",
	},
	"state_machine_nodes": {
		"zip_url": "https://github.com/ninstar/Godot-StateMachineNodes/archive/refs/heads/main.zip",
		"addon_path": "res://addons/state_machine_nodes",
		"addon_config": "res://addons/state_machine_nodes/plugin.cfg",
		"addon_icon": "res://addons/state_machine_nodes/state_machine.svg",
		"example_path": "res://examples/state_machine_nodes",
		"example_scene": "res://examples/state_machine_nodes/scene.tscn",
	},
}

const HTTPDownloader = preload("http.gd")
const CustomProgressDialog = preload("progress.gd")
const CustomConfirmationDialog = preload("confirmation.gd")

var http := HTTPDownloader.new()
var progress_dialog: CustomProgressDialog = preload("progress.tscn").instantiate()
var confirmation_dialog: CustomConfirmationDialog = preload("confirmation.tscn").instantiate()

var _startup: bool = true
var _pending_fs_changes: bool = false


func _enter_tree() -> void:
	add_tool_menu_item("Update gdProject add-ons", _on_update_option_pressed)
	add_child(http)
	
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)

	progress_dialog.set_unparent_when_invisible(true)
	progress_dialog.confirmed.connect(_on_progress_canceled)
	progress_dialog.canceled.connect(_on_progress_canceled)
	
	confirmation_dialog.set_unparent_when_invisible(true)
	confirmation_dialog.confirmed.connect(_on_confirmation_dialog_confirmed)
	confirmation_dialog.canceled.connect(_on_progress_canceled)
	
	http.etags_update_finished.connect(_on_etags_update_finished)
	http.content_update_finished.connect(_on_content_update_finished)
	http.content_update_progress.connect(_on_content_update_progress)


func _exit_tree() -> void:
	remove_tool_menu_item("Update gdProject Add-ons")
	
	progress_dialog.queue_free()
	confirmation_dialog.queue_free()
	http.queue_free()


func _on_update_option_pressed() -> void:
	if http.requesting:
		return
	
	http.update_etags(ADDONS)
	
	EditorInterface.popup_dialog_centered(progress_dialog)
	progress_dialog.label.text = "Checking for updates..."
	progress_dialog.bar.indeterminate = true


func _on_progress_canceled() -> void:
	http.cancel_progress()
	
	EditorInterface.get_editor_toaster().push_toast("Update canceled. To manually perform new updates, select: Project ➜ Tools ➜ Update gdProject Add-ons",
			EditorToaster.SEVERITY_WARNING)


func _on_etags_update_finished(available_addon_list: PackedStringArray) -> void:
	if progress_dialog.visible:
		progress_dialog.hide()
	
	if not available_addon_list.is_empty():
		EditorInterface.popup_dialog_centered(confirmation_dialog)
		confirmation_dialog.set_list(available_addon_list)
	else:
		EditorInterface.get_editor_toaster().push_toast("All gdProject add-ons are up to date.",
				EditorToaster.SEVERITY_INFO)


func _on_confirmation_dialog_confirmed() -> void:
	if http.requesting:
		return
	
	http.update_content()
	
	EditorInterface.popup_dialog_centered(progress_dialog)
	progress_dialog.label.text = "Updating Add-ons..."


func _on_content_update_finished() -> void:
	if progress_dialog.visible:
		progress_dialog.hide()
	
	EditorInterface.get_resource_filesystem().scan_sources()
	
	_pending_fs_changes = true
	
	EditorInterface.get_editor_toaster().push_toast("All gdProject add-ons have been updated.",
			EditorToaster.SEVERITY_INFO)


func _on_content_update_progress(index: int, total: int) -> void:
	progress_dialog.bar.indeterminate = false
	progress_dialog.bar.value = float(index)
	progress_dialog.bar.max_value = float(total)


func _on_filesystem_changed() -> void:
	# Check for updates
	if _startup:
		_on_update_option_pressed()
		_startup = false
	
	# Update add-ons state
	if _pending_fs_changes:
		generate_gallery_list()
		_pending_fs_changes = false


func generate_gallery_list() -> void:
	var list: Array[Dictionary] = []
	
	for key: String in ADDONS.keys():
		if FileAccess.file_exists(ADDONS[key]["addon_config"]):
			if not EditorInterface.is_plugin_enabled(key):
				EditorInterface.set_plugin_enabled(key, true)
			
			var dict: Dictionary = {
				"icon": ADDONS[key]["addon_icon"],
				"scene": ADDONS[key]["example_scene"],
				"config": ADDONS[key]["addon_config"],
			}
			list.append(dict)
	
	var file := FileAccess.open("res://main/list.json", FileAccess.WRITE)
	file.store_line(JSON.stringify(list, "\t"))
	file.close()
