extends Control
class_name MobileControls

signal move_changed(value: Vector2)
signal look_dragged(delta: Vector2)
signal interact_pressed

var _stick_origin := Vector2.ZERO
var _stick_touch := -1
var _look_touch := -1
var _stick_radius := 76.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < size.x * 0.42 and _stick_touch == -1:
				_stick_touch = event.index
				_stick_origin = event.position
				_update_stick(event.position)
		elif event.index == _stick_touch:
			_stick_touch = -1
			move_changed.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch:
			_update_stick(event.position)
		elif event.position.x >= size.x * 0.42:
			look_dragged.emit(event.relative)

func _update_stick(point: Vector2) -> void:
	move_changed.emit(((point - _stick_origin) / _stick_radius).limit_length(1.0))
