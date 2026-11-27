extends Control
class_name MobileControls

signal move_changed(value: Vector2)
signal look_dragged(delta: Vector2)
signal interact_pressed

var _stick_origin := Vector2.ZERO
var _stick_touch := -1
var _look_touch := -1
var _stick_vector := Vector2.ZERO
var _stick_radius := 68.0
var _interact_rect := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(false)
	queue_redraw()

func _draw() -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	var center := Vector2(112, size.y - 122)
	draw_circle(center, _stick_radius, Color(0.08, 0.10, 0.13, 0.30))
	draw_arc(center, _stick_radius, 0, TAU, 48, Color(1, 1, 1, 0.35), 2.0)
	draw_circle(center + _stick_vector * _stick_radius, 30, Color(0.72, 0.78, 0.86, 0.48))
	_interact_rect = Rect2(size.x - 132, size.y - 150, 104, 104)
	draw_circle(_interact_rect.get_center(), 48, Color(0.25, 0.48, 0.72, 0.65))
	draw_arc(_interact_rect.get_center(), 48, 0, TAU, 48, Color(1, 1, 1, 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, _interact_rect.position + Vector2(22, 60), "USE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _interact_rect.has_point(event.position):
				interact_pressed.emit()
				accept_event()
			elif event.position.x < size.x * 0.42 and _stick_touch == -1:
				_stick_touch = event.index
				_stick_origin = Vector2(112, size.y - 122)
				_update_stick(event.position)
				accept_event()
			elif event.position.x >= size.x * 0.42:
				_look_touch = event.index
		else:
			if event.index == _stick_touch:
				_stick_touch = -1
				_stick_vector = Vector2.ZERO
				move_changed.emit(Vector2.ZERO)
				queue_redraw()
			if event.index == _look_touch:
				_look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch:
			_update_stick(event.position)
			accept_event()
		elif event.index == _look_touch:
			look_dragged.emit(event.relative)
			accept_event()

func _update_stick(point: Vector2) -> void:
	_stick_vector = ((point - _stick_origin) / _stick_radius).limit_length(1.0)
	move_changed.emit(_stick_vector)
	queue_redraw()
