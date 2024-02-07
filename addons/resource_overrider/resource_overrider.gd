# Copyright (c) 2024 NinStar
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@tool
@icon("resource_overrider.svg")

class_name ResourceOverrider extends Node


## A node that replaces [Resource]s on-the-fly using suffixes.
##
## [b]ResourceOverrider[/b] is intended to allow easy replacement of
## [Resource]s on-the-fly by using suffixes to identify them, this can
## be useful for resources with alternative skins or themes.[br][br]
## The resource file name requires a suffix for this to work.
## (See [member override_suffix]).[br][br]
## ResourceOverrider doesn't preload resources. They are only loaded when
## [method apply_override], [method get_resource_override] or
## [method override_property] gets called.


## A path pointing to a node. properties that can have their [Resource]
## overridden must be appended to [member override_properties].
@export_node_path("Node") var node_path: NodePath: get = get_node_path, set = set_node_path

## A list of properties that can have its [Resource]s overridden.
## Colon-separated "subnames" are allowed (See [NodePath]).
@export var override_properties: PackedStringArray = []: get = get_override_properties, set = set_override_properties

## The suffix of the current override.[br][br]
## All [Resource]s must reside in the same directory as the default
## resource and have its suffix before the file extension delimited
## with a [code].[/code]. The default resource is the only one
## that doesn't need a suffix. Example:
## [codeblock]
## medal.png             # Default
## medal.silver.png      # "silver"
## medal.bronze.png      # "bronze"
## [/codeblock]
## If this property is empty ([code]""[/code]) or a resource is not found it
## falls back to the default resource. 
@export var override_suffix: String = "": get = get_override_suffix, set = set_override_suffix

## Automatically overrides all [member override_properties] that points
## to a [Resource] when [member override_suffix] changes. If this
## property is set to [code]false[/code] it will be necessary to manually call
## [method override_resources] for the changes to take effect.
@export var override_on_change: bool = true: get = get_override_on_change, set = set_override_on_change

## If [code]true[/code], [Resource]s can be overridden while
## being processed in the editor. Else, resources can only be overridden
## at runtime.
@export var override_on_editor: bool = false: get = get_override_on_editor, set = set_override_on_editor


## Overrides all [member override_properties] that points to a [Resource].
## [br][br] 
## [b]Note:[/b] This method is called automatically if [member apply_on_change]
## is [code]true[/code] and changes are made to [member override_suffix]
## or [member override_properties].
func override_resources() -> void:
	if Engine.is_editor_hint() and not override_on_editor:
		return
	
	var node := get_node_or_null(node_path) as Node
	if is_instance_valid(node):
		# Override resources of the specified properties
		for property: String in override_properties:
			ResourceOverrider.override_property(node, NodePath(property), override_suffix)


## Returns a [Resource] with an override applied. [param suffix] is
## the override suffix (see [member override_suffix]).
static func get_resource_override(resource: Resource, suffix: String = "") -> Resource:
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
	var override_file: String = path + file + "." + suffix + "." + extension
	var default_file: String = path + file + "." + extension

	if ResourceLoader.exists(override_file):
		res = load(override_file)
	elif ResourceLoader.exists(default_file):
		res = load(default_file)

	return res


## Overrides the [Resource] of an [Object]'s [param property] directly.
## [param suffix] is the override suffix (see [member override_suffix]).
static func override_property(object: Object, property: NodePath, suffix: String = "") -> void:
	var res: Resource = object.get_indexed(property)
	object.set_indexed(property, ResourceOverrider.get_resource_override(res, suffix))


#region Getters & Setters

# Getters

func get_node_path() -> NodePath:
	return node_path


func get_override_properties() -> PackedStringArray:
	return override_properties


func get_override_suffix() -> String:
	return override_suffix


func get_override_on_change() -> bool:
	return override_on_change


func get_override_on_editor() -> bool:
	return override_on_editor


# Setters

func set_node_path(value: NodePath) -> void:
	node_path = value


func set_override_properties(value: PackedStringArray) -> void:
	override_properties = value
	if not is_node_ready():
		await ready
	if override_on_change:
		override_resources()


func set_override_suffix(value: String) -> void:
	override_suffix = value
	if not is_node_ready():
		await ready
	if override_on_change:
		override_resources()


func set_override_on_change(value: bool) -> void:
	override_on_change = value


func set_override_on_editor(value: bool) -> void:
	override_on_editor = value

#endregion

