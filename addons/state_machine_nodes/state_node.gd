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

@icon("state_node.svg")

class_name StateNode extends Node


## A node that functions as a state for a [StateMachine].
##
## StateNodes can be used to encapsulate and organize complex logic,
## they are managed and ran by StateMachines.[br][br]
## [b]StateNodes[/b] are automatically assigned by a valid [StateMachine] 
## during initialization as long as the node is a child or grandchild
## of the StateMachine. Once initialized, the StateNode will share the same
## [code]owner[/code] as [member StateMachine.state_owner].


var _state_machine: StateMachine


## Called when the node is initialized by a [StateMachine].
func init() -> void:
	pass


## Called by a [StateMachine] when the state is entered.
## [param old_state] is the name of the previous [b]StateNode[/b].
@warning_ignore("unused_parameter")
func enter(old_state: String) -> void:
	pass


## Called by a [StateMachine] when the state is exited.
## [param new_state] is the name of the next [b]StateNode[/b].
@warning_ignore("unused_parameter")
func exit(new_state: String) -> void:
	pass


## Called by a [StateMachine] each process frame (idle) with the
## time since the last process frame as argument ([param delta], in seconds).
## [br][br]
## Use [param return] to specify the name of the target [b]StateNode[/b] the
## [StateMachine] shall transition to or an empty string ([code]""[/code])
## to remain in the current state. Example:
## [codeblock]
## func process_frame(delta):
##     # Go to "Jump" state if Up is pressed and skip the rest of this code.
##     if Input.is_action_pressed("ui_up"):
##         return "Jump"
##
##     # Stay in this state.
##     return ""
## [/codeblock]
@warning_ignore("unused_parameter")
func process_frame(delta: float) -> String:
	return ""


## Called by a [StateMachine] each physics frame with the time since
## the last physics frame as argument ([param delta], in seconds).[br][br]
## Use [param return] to specify the name of the target [b]StateNode[/b] the
## [StateMachine] shall transition to or an empty string ([code]""[/code])
## to remain in the current state (See [method process_frame]).
@warning_ignore("unused_parameter")
func process_physics(delta: float) -> String:
	return ""


## Called by a [StateMachine] when there is an input event.
## Equivalent to [method Node._input].[br][br]
## Use [param return] to specify the name of the target [b]StateNode[/b] the
## [StateMachine] shall transition to or an empty string ([code]""[/code])
## to remain in the current state (See [method process_frame]).
@warning_ignore("unused_parameter")
func process_input(event: InputEvent) -> String:
	return ""


## Called by a [StateMachine] when an [InputEvent] hasn't been consumed by
## [method Node._input] or any GUI [Control] item.
## Equivalent to [method Node._unhandled_input].[br][br]
## Use [param return] to specify the name of the target [b]StateNode[/b] the
## [StateMachine] shall transition to or an empty string ([code]""[/code])
## to remain in the current state (See [method process_frame]).
@warning_ignore("unused_parameter")
func process_unhandled_input(event: InputEvent) -> String:
	return ""


## Returns [code]true[/code] if the node is currently being
## processed by a [StateMachine].
func is_active() -> bool:
	if is_instance_valid(_state_machine):
		return _state_machine.processing_node == self
	else:
		return false


## Returns the [StateMachine] assigned to this node.
func get_machine() -> StateMachine:
	return _state_machine
