extends Node


@onready var remote_container: RemoteContainer = %RemoteContainer
@onready var update_size: CheckButton = $Options/Box/Size
@onready var update_position: CheckButton = $Options/Box/Position
@onready var update_rotation: CheckButton = $Options/Box/Rotation
@onready var update_scale: CheckButton = $Options/Box/Scale
@onready var update_pivot: CheckButton = $Options/Box/Pivot
@onready var global_coordinates: CheckBox = $Options/Box/GlobalCoordinates


func _ready() -> void:
	update_size.toggled.connect(func(toggled_on: bool): remote_container.update_size = toggled_on)
	update_position.toggled.connect(func(toggled_on: bool): remote_container.update_position = toggled_on)
	update_rotation.toggled.connect(func(toggled_on: bool): remote_container.update_rotation = toggled_on)
	update_scale.toggled.connect(func(toggled_on: bool): remote_container.update_scale = toggled_on)
	update_pivot.toggled.connect(func(toggled_on: bool): remote_container.update_pivot_offset = toggled_on)
	global_coordinates.toggled.connect(func(toggled_on: bool): remote_container.use_global_coordinates = toggled_on)
	update_size.toggled.connect(func(toggled_on: bool): remote_container.update_size = toggled_on)
	
	update_size.set_pressed_no_signal(remote_container.update_size)
	update_position.set_pressed_no_signal(remote_container.update_position)
	update_rotation.set_pressed_no_signal(remote_container.update_rotation)
	update_scale.set_pressed_no_signal(remote_container.update_scale)
	update_pivot.set_pressed_no_signal(remote_container.update_pivot_offset)
	global_coordinates.set_pressed_no_signal(remote_container.use_global_coordinates)

