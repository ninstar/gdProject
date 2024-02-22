extends AudioSyncPlayer


signal sync_log(output: String)


func sync() -> void:
	var stored_position: Array[float] = []
	for i: int in audio_players.size():
		if is_instance_valid(audio_players[i]):
			stored_position.append(audio_players[i].get_playback_position())
	
	super()
	
	var output: String = ""
	for i: int in stored_position.size():
		var current_position: float = audio_players[i].get_playback_position()
		if current_position != stored_position[i]:
			output += "SubPlayer%s // %s s \n" % [i+1, str(stored_position[i]-current_position).pad_decimals(3)]

	sync_log.emit(output)
