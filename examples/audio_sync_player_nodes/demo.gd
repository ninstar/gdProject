extends Node


@onready var audio_sync_player: AudioSyncPlayer = %MainPlayer
@onready var playback: HSlider = %Playback
@onready var play: Button = %Play
@onready var pause: Button = %Pause
@onready var log: TextEdit = %Log
@onready var cycle: Label = %Cycle


func _ready() -> void:
	playback.max_value = audio_sync_player.stream.get_length()


func _process(delta: float) -> void:
	playback.set_value_no_signal(audio_sync_player.get_playback_position())
	cycle.text = str(audio_sync_player._sync_timer.time_left).pad_decimals(2)


func _on_play_pressed() -> void:
	if not audio_sync_player.stream_paused:
		if not audio_sync_player.playing:
			audio_sync_player.play_in_sync()
			pause.disabled = false
			play.text = "◼"
		else:
			audio_sync_player.stop_all()
			pause.disabled = true
			play.text = "▶"


func _on_pause_toggled(toggled_on: bool) -> void:
	audio_sync_player.stream_paused = toggled_on
	play.disabled = toggled_on


func _on_spin_box_value_changed(value: float) -> void:
	audio_sync_player.pitch_scale = value


func _on_playback_value_changed(value: float) -> void:
	audio_sync_player.seek_in_sync(value)


func _on_sync_interval_value_changed(value: float) -> void:
	audio_sync_player.sync_interval = value


func _on_desync_threshold_value_changed(value: float) -> void:
	audio_sync_player.desync_threshold = value


func _on_main_player_sync_log(output: String) -> void:
	log.text = output + log.text
