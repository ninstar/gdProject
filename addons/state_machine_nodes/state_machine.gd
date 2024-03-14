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
## Any StateNodes that are direct children of a StateMachine will be
## automatically assigned to it once it enters the [SceneTree].
## Each StateNode requires its own unique [code]name[/code].


## Emitted when the state is changed.
signal state_changed(previous_state: String, new_state: String)


## If [code]true[/code], automates the processing of StateNodes.[br][br]
## Setting this property to [code]false[/code] can be useful if you want
## to explicty set the order in which each method of a [StateNode] is processed.
@export var automated: bool = true: get = is_automated, set = set_automated

## The maximum amount of state names the StateMachine will save in its history.
@export_range(0, 255, 1, "or_greater", "suffix: state(s)") var history_limit: int = 1: get = get_history_limit, set = set_history_limit

## The [StateNode] the StateMachine will enter once it is ready.
@export var initial_state: StateNode: get = get_initial_state, set = set_initial_state

## A target [Node] that can be accesed by any assigned [StateNode] via
## [method StateNode.get_target].
@export var target_node: Node: set = set_target_node, get = get_target_node


## The [code]name[/code] of the current [StateNode] of the StateMachine.
## Changing this value directly will trigger a state transition
## ([method StateNode.enter]/[method StateNode.exit]) if a valid StateNode of
## the same name is assigned to this StateMachine, otherwise the value stay
## the same and an error is logged.
## [br][br]
## For more control over state transitions, check [method change_state].
var state: String = "": set = set_state, get = get_state


## A list with names of previous StateNodes.
## The maximum amount of entries is defined by [member history_limit].
var history: Array[String] = []: set = set_history, get = get_history


var _state_table: Dictionary = {}
var _state_node: StateNode
var _silent_exit: bool = false
var _silent_enter: bool = false
var _silent_signal: bool = false


## Changes to a different [StateNode] by [code]name[/code]
## ([param new_state]).[br][br]
## This method will first call [method StateNode.exit] on the current StateNode
## (if [param trans_exit] is [code]true[/code]), call
## [method StateNode.enter] on the new one (if [param trans_enter]
## is [code]true[/code]) and then emit [signal state_changed] (if 
## [param trans_signal] is [code]true[/code]).
func change_state(new_state: String, trans_exit: bool = true, trans_enter: bool = true, trans_signal: bool = true) -> void:
	_silent_exit = not trans_exit
	_silent_enter = not trans_enter
	_silent_signal = not trans_signal
	set_state(new_state)


## Returns the [code]name[/code] of the previous [StateNode]
## if one exists in the history, otherwise returns [code]""[/code].
func get_previous_state() -> String:
	if history.size() > 0:
		return history[history.size()-1]
	return ""


## Returns a [StateNode] by its [code]name[/code] ([param state_name])
## if one exists, otherwise returns [code]null[/code].
func get_state_node(state_name: String) -> StateNode:
	if _state_table.has(state_name):
		return _state_table[state_name] as StateNode
	return null


## Returns a list with the names of all avaiable StateNodes.
func get_state_list() -> Array[String]:
	return _state_table.keys()


## Calls [method StateNode.process_frame] on the current [StateNode].[br][br]
## [b]Note:[/b] This method is called automatically if [member automated]
## is set to [code]true[/code].
func process_frame(delta: float) -> void:
	if is_instance_valid(_state_node):
		var new_state: String = _state_node.process_frame(delta)
		if not new_state.is_empty():
			set_state(new_state)


## Calls [method StateNode.process_physics] on the current [StateNode].[br][br]
## [b]Note:[/b] This method is called automatically if [member automated]
## is set to [code]true[/code].
func process_physics(delta: float) -> void:
	if is_instance_valid(_state_node):
		var new_state: String = _state_node.process_physics(delta)
		if not new_state.is_empty():
			set_state(new_state)


## Calls [method StateNode.process_input] on the current [StateNode].[br][br]
## [b]Note:[/b] This method is called automatically if [member automated]
## is set to [code]true[/code].
func process_input(event: InputEvent) -> void:
	if is_instance_valid(_state_node):
		var new_state: String = _state_node.process_input(event)
		if not new_state.is_empty():
			set_state(new_state)


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

func __on_child_entered_tree(node: Node) -> void:
	if node.get_parent() == self and node is StateNode:
		_state_table[node.name] = node
		node._state_machine = self
	

func __on_child_exiting_tree(node: Node) -> void:
	if node.get_parent() == self and node is StateNode:
		if _state_table.has(node.name):
			_state_table.erase(node.name)


#endregion
#region Virtual methods

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		child_entered_tree.connect(__on_child_entered_tree)
		child_exiting_tree.connect(__on_child_exiting_tree)
	elif what == NOTIFICATION_READY:
		for key: String in _state_table.keys():
			var node := _state_table[key] as StateNode
			node.state_machine_ready()
		if is_instance_valid(initial_state):
			if initial_state.get_parent() == self:
				_state_node = initial_state
				_state_node.entered("")


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


func get_history_limit() -> int:
	return history_limit


func get_initial_state() -> StateNode:
	return initial_state


func get_target_node() -> Node:
	return target_node


func get_state() -> String:
	return state


func get_history() -> Array[String]:
	return history

# Setters

func set_automated(value: bool) -> void:
	automated = value
	set_process(automated)
	set_physics_process(automated)
	set_process_input(automated)
	set_process_unhandled_input(automated)


func set_history_limit(value: int) -> void:
	history_limit = value
	if history.size() > history_limit:
		history.resize(history_limit)


func set_initial_state(value: StateNode) -> void:
	initial_state = value


func set_target_node(value: Node) -> void:
	target_node = value


func set_state(value: String) -> void:
	var unmute_transitions = func():
		_silent_exit = false
		_silent_enter = false
		_silent_signal = false
	
	var previous_node: StateNode = _state_node
	var next_node: StateNode = _state_table.get(value, null)
	
	if not is_instance_valid(next_node):
		push_error("StateNode not found found: \"%s\"" % value)
		unmute_transitions.call()
		return
	else:
		if state == value:
			unmute_transitions.call()
			return
		state = value

	# Exit current state
	if is_instance_valid(previous_node):
		if not _silent_exit:
			previous_node.exited(next_node.name)
		
		# Add to history
		if history_limit == 1 and history.size() > 0:
			history[0] = previous_node.name
		elif history_limit >= 1:
			history.append(previous_node.name)
			if history.size() > history_limit:
				history.remove_at(0)
	
	# Enter new state
	if not _silent_enter:
		next_node.entered(previous_node.name)
	
	_state_node = next_node
	
	if not _silent_signal:
		state_changed.emit(previous_node.name, next_node.name)

	unmute_transitions.call()


func set_history(value: Array[String]) -> void:
	history = value

#endregion
