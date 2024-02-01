extends "common_state.gd"


func enter(_old_state: String) -> void:
	sprite.play(&"idle")


func exit(_new_state: String) -> void:
	pass


func process_physics(_delta: float) -> String:
	if player.is_on_floor():
		if Input.get_axis(&"ui_left", &"ui_right") != 0.0:
			return "Walk"
		elif Input.is_action_just_pressed(&"ui_accept"):
			return "Jump"
		elif Input.is_action_just_pressed(&"ui_down"):
			return "Crouch"
	else:
		return "Fall"
	
	return ""
