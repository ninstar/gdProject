extends PanelContainer


@onready var playback: Label = %Playback

@export var audio_player: AudioStreamPlayer


func _ready() -> void:
	%PlayerName.text = audio_player.name
	%Duration.text = time_to_string(audio_player.stream.get_length())
	%Slider.set_value_no_signal(db_to_linear(audio_player.volume_db))


func _process(delta: float) -> void:
	playback.text = time_to_string(audio_player.get_playback_position())


func _on_volume_value_changed(value: float) -> void:
	audio_player.volume_db = linear_to_db(value)


func time_to_string(time: float) -> String:
	var seconds: float = fmod(time, 60.0)
	var minutes: float = floorf(time / 60.0)
	return "%s:%s" % [minutes, "%02d" % seconds]
