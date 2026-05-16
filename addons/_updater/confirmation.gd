@tool
extends ConfirmationDialog


@onready var original_text: String = $Label.text


func set_list(list: PackedStringArray) -> void:
	var formated_string: String = ""
	for text: String in list:
		if not formated_string.is_empty():
			formated_string += "\n"
		formated_string += "[code]%s[/code]" % text

	$Label.text = original_text % formated_string
