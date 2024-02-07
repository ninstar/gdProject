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
@icon("remote_container.svg")

class_name RemoteContainer extends Container


## [RemoteContainer] pushes its own transform to another [Control] derived
## node in the scene.
##
## RemoteContainer pushes its own transform to another [Control] derived node
## (called the remote node) in the scene.[br][br]
## It can be set to update another node's size, position, rotation, scale and/or
## pivot offset. It can use either global or local coordinates.


## The [NodePath] to the remote node, relative to the RemoteContainer's
## position in the scene.
@export_node_path("Control") var remote_path: NodePath = ^"": get = get_remote_path, set = set_remote_path

## If [code]true[/code], the remote node's size is updated.
@export var update_size: bool = true: get = get_update_size, set = set_update_size

## If [code]true[/code], the remote node's position is updated.
@export var update_position: bool = true: get = get_update_position, set = set_update_position

## If [code]true[/code], the remote node's rotation is updated.
@export var update_rotation: bool = true: get = get_update_rotation, set = set_update_rotation

## If [code]true[/code], the remote node's scale is updated.
@export var update_scale: bool = true: get = get_update_scale, set = set_update_scale

## If [code]true[/code], the remote node's pivot offset is updated.
@export var update_pivot_offset: bool = true: get = get_update_pivot_offset, set = set_update_pivot_offset

## If [code]true[/code], global coordinates are used.
## Else, local coordinates are used.
@export var use_global_coordinates: bool = true: get = get_use_global_coordinates, set = set_use_global_coordinates

var _remote_node: Control


## [b]RemoteContainer[/b] caches the remote node. It may not notice if the
## remote node disappears; [member force_update_cache] forces it to update
## the cache again.
func force_update_cache() -> void:
	_remote_node = get_node_or_null(remote_path)


#region Virtual methods

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		# Notify changes made to the transform of this node
		set_notify_transform(true)
		set_notify_local_transform(true)
	elif(
			what == NOTIFICATION_DRAW
			or what == NOTIFICATION_TRANSFORM_CHANGED
			or what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED
	):
		# Return if there is no valid target
		if not is_instance_valid(_remote_node) or _remote_node == self:
			return
		
		# Update properties of the target node
		if update_size:
			_remote_node.custom_minimum_size = custom_minimum_size
			_remote_node.size = size
		
		if update_position:
			if use_global_coordinates:
				_remote_node.global_position = global_position
			else:
				_remote_node.position = position
		
		if update_rotation:
			_remote_node.rotation = rotation
		
		if update_scale:
			_remote_node.scale = scale
		
		if update_pivot_offset:
			_remote_node.pivot_offset = pivot_offset
	elif what == NOTIFICATION_PRE_SORT_CHILDREN:
		# Apply size flags to child Control nodes
		for child: Node in get_children():
			if child is Control:
				# Skip if Control is top level
				if not child.is_visible_in_tree() or child.top_level:
					continue
				fit_child_in_rect(child, Rect2(Vector2.ZERO, size))

#endregion
#region Getters & Setters

# Getters

func get_remote_path() -> NodePath:
	return remote_path


func get_update_size() -> bool:
	return update_size


func get_update_position() -> bool:
	return update_position


func get_update_rotation() -> bool:
	return update_rotation


func get_update_scale() -> bool:
	return update_scale


func get_update_pivot_offset() -> bool:
	return update_pivot_offset


func get_use_global_coordinates() -> bool:
	return use_global_coordinates


# Setters

func set_remote_path(value: NodePath) -> void:
	remote_path = value
	if not is_node_ready():
		await ready
	force_update_cache()
	queue_redraw()


func set_update_size(value: bool) -> void:
	update_size = value
	queue_redraw()


func set_update_position(value: bool) -> void:
	update_position = value
	queue_redraw()


func set_update_rotation(value: bool) -> void:
	update_rotation = value
	queue_redraw()


func set_update_scale(value: bool) -> void:
	update_scale = value
	queue_redraw()


func set_update_pivot_offset(value: bool) -> void:
	update_pivot_offset = value
	queue_redraw()


func set_use_global_coordinates(value: bool) -> void:
	use_global_coordinates = value
	queue_redraw()

#endregion
