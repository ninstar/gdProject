extends "common_state.gd"


func enter(_old_state: String) -> void:
	sprite.play(&"crouch")


func process_physics(_delta: float) -> String:
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, SPEED * 0.025)
		
		if Input.is_action_just_released(&"ui_down"):
			return get_machine().get_previous_state()
	else:
		return "Fall"
	
	return ""
