@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("AudioSyncPlayer", "AudioStreamPlayer", preload("audio_sync_player.gd"), preload("audio_sync_player.svg"))
	add_custom_type("AudioSyncPlayer2D", "AudioStreamPlayer2D", preload("audio_sync_player_2d.gd"), preload("audio_sync_player_2d.svg"))
	add_custom_type("AudioSyncPlayer3D", "AudioStreamPlayer3D", preload("audio_sync_player_3d.gd"), preload("audio_sync_player_3d.svg"))


func _exit_tree():
	remove_custom_type("AudioSyncPlayer")
	remove_custom_type("AudioSyncPlayer2D")
	remove_custom_type("AudioSyncPlayer3D")
