@tool
@icon("resource_overrider.svg")

class_name ResourceOverrider extends Node


## A node that replaces [Resource]s on-the-fly using suffixes.
##
## [b]ResourceOverrider[/b] is intended to allow easy replacement of
## resources on-the-fly by using suffixes to identify them. This can be
## used for components of your game that may have alternative resources,
## such as character skins and themes. (Alternative resources must
## have a suffix in their filename for this to work.
## (See [member current_suffix])[br][br]
## ResourceOverrider only loads a resource into memory when 
## [method apply], [method apply_to] or
## [method get_applied] gets called.


## Emitted when one or more resources in [member node_properties]
## are overridden.
signal override_applied()


## A path pointing to a node. Any property that can have its resource
## overridden must be appended to [member node_properties].
@export_node_path("Node") var node_path: NodePath: get = get_node_path, set = set_node_path

## A list of properties that can have its resources overridden.
## Colon-separated "subnames" are allowed. (See [NodePath])
## [br][br]
## The following methods can be used to handle these properties using NodePaths
## instead of Strings:
## [method add_node_property_path], [method has_node_property_path],
## [method remove_node_property_path] and [method get_node_property_path_list].
@export var node_properties: PackedStringArray = []: get = get_node_properties, set = set_node_properties

## The suffix being used to override resources in [member node_properties].
## [br][br]
## All resources must reside in the same directory as the default
## one, and have its suffix before the file extension delimited
## with a [code].[/code]. The default resource is the only one
## that does not require a suffix. Example:
## [codeblock]
## medal.png             # Default
## medal.silver.png      # "silver"
## medal.bronze.png      # "bronze"
## [/codeblock]
## The default resource is used when this property is empty ([code]""[/code])
## or the specified override is not found.
@export var current_suffix: String = "": get = get_current_suffix, set = set_current_suffix

## Automatically overrides all [member node_properties] when
## [member current_suffix] is changed. If this property is set to
## [code]false[/code] it will be necessary to manually call
## [method apply] for changes to take effect.
@export var apply_on_change: bool = true: get = get_apply_on_change, set = set_apply_on_change

## If [code]true[/code], resources can be overridden while
## being processed in the editor. Else, resources can only be overridden
## at runtime.
@export var apply_on_editor: bool = false: get = get_apply_on_editor, set = set_apply_on_editor


## Overrides all [member node_properties] that points to a resource.
## [br][br] 
## [b]Note:[/b] This method is called automatically if changes are made to
## [member current_suffix] or [member node_properties] while [member apply_on_change]
## is [code]true[/code].
func apply() -> void:
	if Engine.is_editor_hint() and not apply_on_editor:
		return
	
	var node := get_node_or_null(node_path) as Node
	if is_instance_valid(node):
		var total_applied: int = 0
		
		# Override resources of the specified properties only if its different
		for property: String in node_properties:
			var old_res: Resource = node.get_indexed(property)
			var new_res: Resource = ResourceOverrider.get_applied(old_res, current_suffix)
			if old_res != new_res:
				node.set_indexed(property, new_res)
				total_applied += 1
		
		if total_applied > 0:
			override_applied.emit()


## Adds the property identified by the given [param path] to the list
## of [member node_properties].
func add_node_property_path(path: NodePath) -> void:
	var path_string: String = str(path)
	if not node_properties.has(path_string):
		node_properties.append(path_string)


## Removes the property identified by the given [param path]
## from the list of [member node_properties].
func remove_node_property_path(path: NodePath) -> void:
	var property_pos: int = node_properties.find(str(path))
	if property_pos > -1:
		node_properties.remove_at(property_pos)


## Returns whether the given [param path] is in the list of
## [member node_properties].
func has_node_property_path(path: NodePath) -> void:
	return node_properties.has(str(path))


## Returns a list of all [member node_properties] as [NodePath]s.
func get_node_property_path_list() -> Array[NodePath]:
	var path_list: Array[NodePath] = []
	for property_string: String in node_properties:
		path_list.append(NodePath(property_string))
	return path_list


## Returns a [Resource] with an override applied. [param override] is
## the suffix of the resource that will be loaded as an override.
## (See [member current_suffix])
static func get_applied(resource: Resource, override: String = "") -> Resource:
	if resource == null:
		return null

	var res: Resource = resource
	var path: String = resource.resource_path.get_base_dir()+"/"
	var file: String = resource.resource_path.get_file()
	var extension: String = resource.resource_path.get_extension()

	# Remove extensions
	for i: int in file.count("."):
		file = file.get_basename()

	# Load resource
	var override_file: String = path + file + "." + override + "." + extension
	var default_file: String = path + file + "." + extension

	if ResourceLoader.exists(override_file):
		res = load(override_file)
	elif ResourceLoader.exists(default_file):
		res = load(default_file)

	return res


## Overrides the [Resource] of an [Object]'s property directly. [param override]
## is the suffix of the resource that will be loaded as an override.
## (See [member current_suffix])
static func apply_to(object: Object, property: NodePath, override: String = "") -> void:
	var res: Resource = object.get_indexed(property)
	object.set_indexed(property, ResourceOverrider.get_applied(res, override))


#region Getters & Setters

# Getters

func get_node_path() -> NodePath:
	return node_path


func get_node_properties() -> PackedStringArray:
	return node_properties


func get_current_suffix() -> String:
	return current_suffix


func get_apply_on_change() -> bool:
	return apply_on_change


func get_apply_on_editor() -> bool:
	return apply_on_editor


# Setters

func set_node_path(value: NodePath) -> void:
	node_path = value


func set_node_properties(value: PackedStringArray) -> void:
	node_properties = value
	if not is_node_ready():
		await ready
	if apply_on_change:
		apply()


func set_current_suffix(value: String) -> void:
	current_suffix = value
	if not is_node_ready():
		await ready
	if apply_on_change:
		apply()


func set_apply_on_change(value: bool) -> void:
	apply_on_change = value


func set_apply_on_editor(value: bool) -> void:
	apply_on_editor = value

#endregion
