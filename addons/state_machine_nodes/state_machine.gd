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

@icon("state_machine.svg")

class_name StateMachine extends Node


## A node used to manage and process logic on a [StateNode].
## 
## [b]StateMachine[/b] can be used to manage and process logic on different
## StateNodes at time, at least one [StateNode] is needed to use this node.
## [br][br]
## Any StateNode that is a child or grandchild of a StateMachine will be
## automatically assigned during initilization and have [member state_owner]
## set as their [code]owner[/code].


## Emitted when states are changed.
signal state_changed(old_state: String, new_state: String)


## If [code]true[/code], automates the StateMachine initialization
## and the processing of the current StateNode.[br][br]
## Setting this property to [code]false[/code] can be useful if you want
## to explicty set the order in which each method of a StateNodes is processed.
@export var automated: bool = true: get = is_automated, set = set_automated

## The maximum amount of state names the StateMachine will save in its stack.
@export var max_stack_size: int = 5: get = get_max_stack_size, set = set_max_stack_size

## The name of the state the StateMachine will enter once initialized.
@export var initial_state: String = "": get = get_initial_state, set = set_initial_state

## The owner of all [StateNodes] assigned to this StateMachine.
@export var state_owner: Node: set = set_state_owner, get = get_state_owner

var _state_stack: PackedStringArray = []
var _state_table: Dictionary = {}
var _state_node: StateNode


## Assigns and initializes existing children and grandchildren [StateNode]s
## and enters [member initial_state] if one is set.[br][br]
## [b]Note:[/b] This method is called automatically when entering the
## [SceneTree] if [member automated] is set to [code]true[/code].
func init() -> void:
	# Assign state nodes
	for child: Node in find_children("", "StateNode"):
		if child is StateNode:
			assign_state(child as StateNode)
	
	# Initialize state nodes
	for key: String in _state_table.keys() as Array[String]:
		var node: StateNode = _state_table[key]
		node.init()

	# Enter initial state node
	if not initial_state.is_empty():
		change_state(initial_state)


## Assigns a [StateNode] to this [b]StateMachine[/b].
## [member state_owner] will be set as the [code]owner[/code]
## of the StateNode.[br][br]
## [b]Note:[/b] StateNodes assigned manually are not initialized automatically,
## call [method StateNode.init] to initialize them when necessary.
func assign_state(node: StateNode) -> void:
	_state_table[node.name] = node
	if state_owner != null:
		node.owner = state_owner
		node._state_machine = self


## Changes to a different [StateNode] by [code]name[/code]
## ([param new_state]).[br][br]
## This method will first call [method StateNode.exit] on the current node
## and then call [method StateNode.enter] on the new one.
func change_state(new_state: String) -> void:
	var new_node: StateNode = _state_table.get(new_state, null)
	if not is_instance_valid(new_node):
		push_warning("StateMachine: %s not found!" % [new_state])
		return

	# Exit current state
	var old_state: String = ""
	if is_instance_valid(_state_node):
		_state_node.exit(new_state)
		old_state = _state_node.name

	# Enter new state
	new_node.enter(old_state)
	_state_node = new_node

	# Add old state to stack
	if not old_state.is_empty():
		_state_stack.append(old_state)
		if _state_stack.size() > max_stack_size:
			_state_stack.remove_at(0)
	
	state_changed.emit(old_state, new_state)


## Returns a list of names of previous states saved in the stack. 
## The maximum amount of entries is defined by [member max_stack_size].
func get_state_stack() -> PackedStringArray:
	return _state_stack


## Returns the [code]name[/code] of the previous [StateNode]
## if one exists in the stack, otherwise returns [code]""[/code].
func get_previous_state() -> String:
	if _state_stack.size() > 0:
		return _state_stack[_state_stack.size()-1]
	return ""


## Returns the [code]name[/code] of the current [StateNode] if one exists,
## otherwise returns [code]""[/code].
func get_current_state() -> String:
	if is_instance_valid(_state_node):
		return _state_node.name
	return ""


## Returns a [StateNode] by its [code]name[/code] ([param state_name])
## if one exists, otherwise returns [code]null[/code].
func get_state_node(state_name: String) -> StateNode:
	if _state_table.has(state_name):
		return _state_table[state_name] as StateNode
	return null


## Calls [method StateNode.process_frame] on the current [StateNode].[br][br]
## [b]Note:[/b] This method is called automatically if [member automated]
## is set to [code]true[/code].
func process_frame(delta: float) -> void:
	if is_instance_valid(_state_node):
		var new_state: String = _state_node.process_frame(delta)
		if not new_state.is_empty():
			change_state(new_state)


## Calls [method StateNode.process_physics] on the current [StateNode].[br][br]
## [b]Note:[/b] This method is called automatically if [member automated]
## is set to [code]true[/code].
func process_physics(delta: float) -> void:
	if is_instance_valid(_state_node):
		var new_state: String = _state_node.process_physics(delta)
		if not new_state.is_empty():
			change_state(new_state)


## Calls [method StateNode.process_input] on the current [StateNode].[br][br]
## [b]Note:[/b] This method is called automatically if [member automated]
## is set to [code]true[/code].
func process_input(event: InputEvent) -> void:
	if is_instance_valid(_state_node):
		var new_state: String = _state_node.process_input(event)
		if not new_state.is_empty():
			change_state(new_state)


## Calls [method StateNode.process_unhandled_input] on the current
## [StateNode].[br][br]
## [b]Note:[/b] This method is called automatically if [member automated]
## is set to [code]true[/code].
func process_unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_state_node):
		var new_state: String = _state_node.process_unhandled_input(event)
		if not new_state.is_empty():
			change_state(new_state)


#region Signals

func __auto_assign_and_init(node: Node) -> void:
	if node is StateNode:
		assign_state(node)
		node.init()

#endregion
#region Virtual methods

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		if automated:
			if not is_node_ready():
				await ready
			init()


func _process(delta: float) -> void:
	if automated:
		process_frame(delta)


func _physics_process(delta: float) -> void:
	if automated:
		process_physics(delta)


func _input(event: InputEvent) -> void:
	if automated:
		process_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if automated:
		process_unhandled_input(event)

#endregion
#region Getters & Setters

# Getters

func is_automated() -> bool:
	return automated


func get_max_stack_size() -> int:
	return max_stack_size


func get_initial_state() -> String:
	return initial_state


func get_state_owner() -> Node:
	return state_owner


# Setters

func set_automated(value: bool) -> void:
	automated = value
	if automated:
		if not child_entered_tree.is_connected(__auto_assign_and_init):
			child_entered_tree.connect(__auto_assign_and_init)
	else:
		if child_entered_tree.is_connected(__auto_assign_and_init):
			child_entered_tree.disconnect(__auto_assign_and_init)


func set_max_stack_size(value: int) -> void:
	max_stack_size = value
	if _state_stack.size() > max_stack_size:
		_state_stack.resize(max_stack_size)


func set_initial_state(value: String) -> void:
	initial_state = value


func set_state_owner(value: Node) -> void:
	state_owner = value
	if is_node_ready():
		for key: String in _state_table.keys():
			var node := _state_table[key] as StateNode
			node.owner = state_owner

#endregion
