@tool
extends AcceptDialog


signal icon_selected(new_theme_type: StringName, new_icon_name: StringName)
signal layout_save_requested(new_layout: Dictionary)


const CODE_SNIPPET = "set_icon(&\"%s\", &\"%s\")"


@onready var theme_filters: MenuButton = %ThemeFilters
@onready var search: LineEdit = %Search
@onready var type_list: OptionButton = %TypeList
@onready var icon_list: ItemList = %IconList
@onready var view_mode: Button = %ViewMode
@onready var count_label: Label = %Count
@onready var texture_filter: Button = %TextureFilter
@onready var size_box: SpinBox = %SizeBox
@onready var context_menu: PopupMenu = $ContextMenu
@onready var no_results: Label = %NoResults

var layout: Dictionary = {}
var icon_name: StringName = &""
var theme_type: StringName = &""
var icon_theme_resource: Theme = null

var active: bool = false
var linear_filter: bool = false
var grid_view: bool = true
var include_icon_theme: bool = true
var include_project_theme: bool = true
var include_default_theme: bool = false
var context_menu_icon_index: int = 0

var _is_ready: bool = false


func _ready() -> void:
	if not active:
		return
	
	# Hide OK button
	#get_ok_button().hide()
	
	# Set window icons
	theme_filters.icon = get_theme_icon(&"ThemeDock", &"EditorIcons")
	search.right_icon = get_theme_icon(&"Search", &"EditorIcons")
	
	# Load dialog layout
	search.text = layout.get(&"search_text", search.text)
	linear_filter = layout.get(&"linear_filter", linear_filter)
	size_box.set_value_no_signal(layout.get(&"icon_size", size_box.value))
	size_box.prefix = "%d ×" % size_box.value
	grid_view = layout.get(&"grid_view", grid_view)
	include_icon_theme = layout.get(&"include_icon_theme", include_icon_theme)
	include_project_theme = layout.get(&"include_project_theme", include_project_theme)
	include_default_theme = layout.get(&"include_default_theme", include_default_theme)
	
	# Theme filters
	var popup: PopupMenu = theme_filters.get_popup()
	if icon_theme_resource != null:
		popup.set_item_text(0, icon_theme_resource.resource_path.get_file())
	popup.set_item_checked(0, include_icon_theme)
	popup.set_item_checked(1, include_project_theme)
	popup.set_item_checked(2, include_default_theme)
	popup.index_pressed.connect(_on_theme_filters_index_pressed)
	
	# Do not hide popup when toggling themes
	popup.hide_on_checkable_item_selection = false
	
	# Ready
	_is_ready = true
	
	# Update type list
	type_list.tooltip_text = tr("Filter by Type")
	type_list.get_popup().about_to_popup.connect(_on_type_list_about_to_popup)
	update_type_list()
	
	# Auto-select type filter
	var type_filter: String = layout.get(&"type_filter", type_list.get_item_text(type_list.selected))
	for i: int in type_list.item_count:
		if type_list.get_item_text(i) == type_filter:
			type_list.select(i)
			break
	
	# Update icon list
	update_icon_list()
	
	# Focus on selected icon
	for i: int in icon_list.item_count:
		var meta: Dictionary = icon_list.get_item_metadata(i)
		if icon_name == meta.get(&"name", &"") and theme_type == meta.get(&"theme_type", &""):
			icon_list.select(i)
			icon_list.ensure_current_is_visible()
			update_ok_button()
			break


func update_type_list() -> void:
	var previously_selected_type: String = type_list.get_item_text(type_list.selected)
	
	# Clear list
	type_list.clear()
	type_list.add_item(tr("All"))
	type_list.set_item_metadata(0, &"")
	type_list.select(0)
	
	# Filter themes
	var themes: Array[Theme] = []
	if include_icon_theme:
		themes.append(icon_theme_resource)
	if include_project_theme:
		themes.append(ThemeDB.get_project_theme())
	if include_default_theme:
		themes.append(ThemeDB.get_default_theme())
	
	# Find available types from themes
	var types: Array[StringName] = []
	for theme: Theme in themes:
		if theme == null:
			continue
		
		for type: String in theme.get_icon_type_list():
			if not types.has(StringName(type)):
				types.append(StringName(type))
	
	# Add types as options
	types.sort()
	for type: StringName in types:
		var type_icon: Texture2D = get_theme_icon(type, &"EditorIcons")
		if type_icon == ThemeDB.fallback_icon:
			type_icon = get_theme_icon(&"NodeDisabled", &"EditorIcons")
		
		type_list.add_icon_item(type_icon, type)
		type_list.set_item_metadata(type_list.item_count-1, type)
		
		# Auto-select
		if previously_selected_type == type:
			type_list.select(type_list.item_count-1)



func update_icon_list() -> void:
	if not active or not _is_ready:
		return
	
	# Clear list
	icon_list.clear()
	
	# Find available icons from type
	var added_icons: PackedStringArray = []
	var themes: Array[Theme] = [icon_theme_resource, ThemeDB.get_project_theme(), ThemeDB.get_default_theme()]
	var theme_names: Array[StringName] = [&"icon", &"project", &"default"]
	for i: int in themes.size():
		if themes[i] == null:
			continue
		
		# Get selected type
		var selected_type: StringName = type_list.get_selected_metadata()
	
		# Add icons as options
		var popup: PopupMenu = theme_filters.get_popup()
		for type: String in themes[i].get_icon_type_list() if selected_type.is_empty() else PackedStringArray([selected_type]):
			for icon: String in themes[i].get_icon_list(type):
				if(
						not added_icons.has("%s.%s" % [type, icon])
						and (search.text.is_empty()
						or type.containsn(search.text)
						or icon.containsn(search.text))
				):
					var icon_name: String = (type + " - " + icon) if selected_type.is_empty() else icon
					var meta: Dictionary = {
						&"filter": theme_names[i],
						&"name": icon,
						&"theme_type": type,
					}
					
					icon_list.add_item(icon_name, themes[i].get_icon(icon, type))
					icon_list.set_item_tooltip(icon_list.item_count-1, 
							tr("Theme:") + (" %s\n" % tr(popup.get_item_text(i))) +
							tr("Type:") + (" %s\n" % type) +
							tr("Name:") + (" %s" % icon)
						)
					icon_list.set_item_metadata(icon_list.item_count-1, meta)
					added_icons.append("%s.%s" % [type, icon])
	added_icons.clear()

	# Sort list
	icon_list.sort_items_by_text()
	
	# Filter out themes
	var filters: Array[StringName] = []
	if include_icon_theme:
		filters.append(&"icon")
	if include_project_theme:
		filters.append(&"project")
	if include_default_theme:
		filters.append(&"default")
	
	# Remove filtered options
	for i: int in range(icon_list.item_count-1, -1, -1):
		var metadata: Dictionary = icon_list.get_item_metadata(i)
		if not filters.has(metadata.get(&"filter", &"")):
			icon_list.remove_item(i)
		else:
			# Remove text (grid view)
			if grid_view:
				icon_list.set_item_text(i, "")

	# Set view mode
	icon_list.fixed_icon_size = Vector2.ONE * size_box.value
	icon_list.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if linear_filter else CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Update buttons
	size_box.prefix = "%d ×" % size_box.value
	texture_filter.icon = get_theme_icon(&"Line" if linear_filter else &"InterpRaw", &"EditorIcons")
	texture_filter.tooltip_text = "Linear" if linear_filter else "Nearest"
	view_mode.icon = get_theme_icon(&"FileThumbnail" if not grid_view else &"FileList", &"EditorIcons")
	view_mode.tooltip_text = "Grid view" if not grid_view else "List view"
	
	# Update numbers
	var icon_count: int = icon_list.item_count
	count_label.text = tr_n("1 icon", "{num} icons", icon_count).format({"num": str(icon_count)}) if icon_count > 0 else ""
	no_results.visible = icon_count <= 0

	update_ok_button()


func update_ok_button() -> void:
	get_ok_button().text = "Select" if icon_list.item_count > 0 and icon_list.is_anything_selected() else "Close"


func confirm_selection() -> void:
	if not active:
		return
	
	if icon_list.is_anything_selected():
		var meta: Dictionary = icon_list.get_item_metadata(icon_list.get_selected_items()[0])
		icon_name = meta.get(&"name", &"")
		theme_type = meta.get(&"theme_type", &"")
		icon_selected.emit(theme_type, icon_name)


func _on_visibility_changed() -> void:
	if not active:
		return
	
	if not visible:
		layout = {
			&"window_rect": Rect2i(position, size),
			&"search_text": search.text,
			&"type_filter": type_list.get_item_text(type_list.selected),
			&"linear_filter": linear_filter,
			&"icon_size": size_box.value,
			&"grid_view": grid_view,
			&"include_icon_theme": include_icon_theme,
			&"include_project_theme": include_project_theme,
			&"include_default_theme": include_default_theme,
		}
		layout_save_requested.emit(layout)
		queue_free()


func _on_texture_filter_pressed() -> void:
	if not active:
		return
	
	linear_filter = not linear_filter
	update_icon_list()


func _on_view_mode_pressed() -> void:
	if not active:
		return
	
	grid_view = not grid_view
	update_icon_list()


func _on_type_list_about_to_popup() -> void:
	if not active:
		return
	
	type_list.get_popup().min_size.y = 0
	type_list.get_popup().max_size.y = 384


func _on_theme_filters_index_pressed(index: int) -> void:
	var popup: PopupMenu = theme_filters.get_popup()
	match index:
		0:
			popup.set_item_checked(0, not popup.is_item_checked(0))
			include_icon_theme = popup.is_item_checked(0)
		1:
			popup.set_item_checked(1, not popup.is_item_checked(1))
			include_project_theme = popup.is_item_checked(1)
		2:
			popup.set_item_checked(2, not popup.is_item_checked(2))
			include_default_theme = popup.is_item_checked(2)
	
	update_type_list()
	update_icon_list()


func _on_icon_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		context_menu.clear()
		context_menu.add_icon_item(get_theme_icon(&"Node", &"EditorIcons"), "%s %s" % [tr("Copy"), tr("Type")])
		context_menu.set_item_metadata(context_menu.item_count-1, &"copy_theme_type")
		context_menu.add_icon_item(get_theme_icon(&"ActionCopy", &"EditorIcons"), "Copy Name")
		context_menu.set_item_metadata(context_menu.item_count-1, &"copy_icon_name")
		context_menu.add_icon_item(get_theme_icon(&"GDScriptInternal", &"EditorIcons"), "%s Snippet" % tr("Copy"))
		context_menu.set_item_metadata(context_menu.item_count-1, &"copy_snippet")
		
		if not icon_list.get_item_icon(index).is_built_in():
			context_menu.add_separator()
			context_menu.add_icon_item(get_theme_icon(&"ShowInFileSystem", &"EditorIcons"), "Show in FileSystem")
			context_menu.set_item_metadata(context_menu.item_count-1, &"show_in_filesystem")
		
		context_menu_icon_index = index
		
		context_menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


func _on_context_menu_index_pressed(index: int) -> void:
	var icon_index: int = context_menu_icon_index
	match context_menu.get_item_metadata(index) as StringName:
		&"copy_icon_name":
			DisplayServer.clipboard_set(icon_list.get_item_metadata(icon_index)[&"name"])
		&"copy_theme_type":
			DisplayServer.clipboard_set(icon_list.get_item_metadata(icon_index)[&"theme_type"])
		&"copy_snippet":
			DisplayServer.clipboard_set(CODE_SNIPPET % [
				icon_list.get_item_metadata(icon_index)[&"theme_type"],
				icon_list.get_item_metadata(icon_index)[&"name"]])
		&"show_in_filesystem":
			EditorInterface.select_file(icon_list.get_item_icon(icon_index).resource_path)
			hide()
