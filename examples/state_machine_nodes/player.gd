extends CharacterBody2D


var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var state_machine: StateMachine = $StateMachine


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * 2.0 * delta
	state_machine.process_physics(delta)
	move_and_slide()


func _on_state_machine_state_changed(_old_state: String, new_state: String) -> void:
	$State.text = new_state
