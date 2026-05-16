@tool
@icon("range_container.svg")

class_name RangeContainer extends ScrollContainer


## A [ScrollContainer] that can be controlled by external [Range] nodes.


@export_group("Shared Range Nodes", "shared_")

## [Range] node bound to the [HScrollBar] of the container.
@export var shared_horizontal_range: Array[Range]: get = get_shared_horizontal_range, set = set_shared_horizontal_range 

## [Range] node bound to the [VScrollBar] of the container.
@export var shared_vertical_range: Array[Range]: get = get_shared_vertical_range, set = set_shared_vertical_range

@export_group("Scroll Bar Focus Mode", "focus_mode_")

## The focus access mode for the [HScrollBar] (None, Click or All).
## Only one Control can be focused at the same time, and it will receive
## keyboard, gamepad, and mouse signals.
@export var focus_mode_horizontal_scroll_bar := Control.FocusMode.FOCUS_NONE: get = get_focus_mode_horizontal_scroll_bar, set = set_focus_mode_horizontal_scroll_bar

## The focus access mode for the [VScrollBar] (None, Click or All).
## Only one Control can be focused at the same time, and it will receive
## keyboard, gamepad, and mouse signals.
@export var focus_mode_vertical_scroll_bar := Control.FocusMode.FOCUS_NONE: get = get_focus_mode_vertical_scroll_bar, set = set_focus_mode_vertical_scroll_bar

@export_group("Follow Focus Tween", "follow_focus_tween_")

## If [code]true[/code], the ScrollContainer will use a [Tween] to automatically scroll
## to focused children (including indirect children) to make sure they are
## fully visible.[br][br]
## [b]Note:[/b] This property overrides the behaviour of [member focus_mode].
@export var follow_focus_tween_enabled: bool = true: get = get_follow_focus_tween_enabled, set = set_follow_focus_tween_enabled

## The amount of time to finish scrolling to focused children.
## (See [member follow_focus_tween_enabled])
@export var follow_focus_tween_duration: float = 0.15: get = get_follow_focus_tween_duration, set = set_follow_focus_tween_duration

## The transition type when scrolling to focused children.
## (See [member follow_focus_tween_enabled])
@export var follow_focus_tween_transition_type := Tween.TransitionType.TRANS_SINE: get = get_follow_focus_tween_transition_type, set = set_follow_focus_tween_transition_type

## The ease type when scrolling to focused children.
## (See [member follow_focus_tween_enabled])
@export var follow_focus_tween_ease_type := Tween.EaseType.EASE_OUT: get = get_follow_focus_tween_ease_type, set = set_follow_focus_tween_ease_type


var __tween: Tween


#region Signals

func __on_scroll_bar_changed(scroll_bar: ScrollBar) -> void:
	for node: Node in (shared_horizontal_range if scroll_bar == HScrollBar else shared_vertical_range):
		var range := node as Range
		
		if is_instance_valid(range):
			if range is ScrollBar:
				(range as ScrollBar).custom_step = scroll_bar.custom_step
				range.step = scroll_bar.step
			elif range is Slider:
				range.step = maxf(0.0, scroll_bar.custom_step)
			elif range is SpinBox:
				range.step = 1.0 if scroll_bar.custom_step <= 0.0 else scroll_bar.custom_step
			else:
				range.step = scroll_bar.step
				
			range.min_value = scroll_bar.min_value
			range.max_value = scroll_bar.max_value - (scroll_bar.page * float(range is not ScrollBar))
			range.page = scroll_bar.page * float(range is ScrollBar)


func __on_scroll_bar_value_changed(value: float, scroll_bar: ScrollBar) -> void:
	for range: Range in (shared_horizontal_range if scroll_bar == HScrollBar else shared_vertical_range):
		if is_instance_valid(range):
			range.set_value_no_signal(value)


func __on_external_range_value_changed(value: float, horizontal: bool) -> void:
	if horizontal:
		scroll_horizontal = value
	else:
		scroll_vertical = value


func __on_gui_focus_changed(node: Control) -> void:
	if follow_focus_tween_enabled and is_ancestor_of(node):
		follow_focus = false
		
		var start_h: int = scroll_horizontal
		var start_v: int = scroll_vertical
		
		ensure_control_visible(node)
		
		if __tween:
			__tween.kill()
		
		__tween = create_tween()
		__tween.set_trans(follow_focus_tween_transition_type).set_ease(follow_focus_tween_ease_type).set_parallel()
		__tween.tween_property(self, ^"scroll_horizontal", scroll_horizontal, follow_focus_tween_duration).from(start_h)
		__tween.tween_property(self, ^"scroll_vertical", scroll_vertical, follow_focus_tween_duration).from(start_v)

#endregion
#region Vritual methods

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		var h_scroll_bar: HScrollBar = get_h_scroll_bar()
		var v_scroll_bar: VScrollBar = get_v_scroll_bar()
		
		h_scroll_bar.changed.connect(__on_scroll_bar_changed.bind(h_scroll_bar))
		v_scroll_bar.changed.connect(__on_scroll_bar_changed.bind(v_scroll_bar))
		h_scroll_bar.value_changed.connect(__on_scroll_bar_value_changed.bind(h_scroll_bar))
		v_scroll_bar.value_changed.connect(__on_scroll_bar_value_changed.bind(v_scroll_bar))
		
		get_viewport().gui_focus_changed.connect(__on_gui_focus_changed)

#endregion
#region Getters & Setters

# Getters

func get_shared_horizontal_range() -> Array[Range]:
	return shared_horizontal_range


func get_shared_vertical_range() -> Array[Range]:
	return shared_vertical_range


func get_focus_mode_horizontal_scroll_bar() -> Control.FocusMode:
	return focus_mode_horizontal_scroll_bar


func get_focus_mode_vertical_scroll_bar() -> Control.FocusMode:
	return focus_mode_vertical_scroll_bar


func get_follow_focus_tween_enabled() -> bool:
	return follow_focus_tween_enabled


func get_follow_focus_tween_duration() -> float:
	return follow_focus_tween_duration


func get_follow_focus_tween_transition_type() -> Tween.TransitionType:
	return follow_focus_tween_transition_type


func get_follow_focus_tween_ease_type() -> Tween.EaseType:
	return follow_focus_tween_ease_type

# Setters

func set_shared_horizontal_range(nodes: Array[Range]) -> void:
	if is_node_ready():
		for range: Range in nodes:
			if is_instance_valid(range) and range.value_changed.is_connected(__on_external_range_value_changed):
				range.value_changed.disconnect(__on_external_range_value_changed)
	
	shared_horizontal_range = nodes
	
	if not is_node_ready():
		await ready
	
	for range: Range in nodes:
		if is_instance_valid(range):
			range.value_changed.connect(__on_external_range_value_changed.bind(true))


func set_shared_vertical_range(nodes: Array[Range]) -> void:
	if is_node_ready():
		for range: Range in nodes:
			if is_instance_valid(range) and range.value_changed.is_connected(__on_external_range_value_changed):
				range.value_changed.disconnect(__on_external_range_value_changed)
	
	shared_vertical_range = nodes
	
	if not is_node_ready():
		await ready
	
	for range: Range in nodes:
		if is_instance_valid(range):
			range.value_changed.connect(__on_external_range_value_changed.bind(false))


func set_focus_mode_horizontal_scroll_bar(scroll_bar_focus_mode: Control.FocusMode) -> void:
	focus_mode_horizontal_scroll_bar = scroll_bar_focus_mode
	
	if not is_node_ready():
		await ready
	
	var scroll_bar: ScrollBar = get_v_scroll_bar()
	scroll_bar.focus_mode = focus_mode_horizontal_scroll_bar
	if focus_mode_horizontal_scroll_bar != Control.FocusMode.FOCUS_NONE:
		scroll_bar.focus_neighbor_left = ^"."
		scroll_bar.focus_neighbor_right = ^"."


func set_focus_mode_vertical_scroll_bar(scroll_bar_focus_mode: Control.FocusMode) -> void:
	focus_mode_vertical_scroll_bar = scroll_bar_focus_mode
	
	if not is_node_ready():
		await ready
	
	var scroll_bar: ScrollBar = get_v_scroll_bar()
	scroll_bar.focus_mode = focus_mode_vertical_scroll_bar
	if focus_mode_vertical_scroll_bar != Control.FocusMode.FOCUS_NONE:
		scroll_bar.focus_neighbor_top = ^"."
		scroll_bar.focus_neighbor_bottom = ^"."


func set_follow_focus_tween_enabled(enabled: bool) -> void:
	follow_focus_tween_enabled = enabled


func set_follow_focus_tween_duration(value: float) -> void:
	follow_focus_tween_duration = value


func set_follow_focus_tween_transition_type(trans_type: Tween.TransitionType) -> void:
	follow_focus_tween_transition_type = trans_type


func set_follow_focus_tween_ease_type(ease_type: Tween.EaseType) -> void:
	follow_focus_tween_ease_type = ease_type

#endregion
