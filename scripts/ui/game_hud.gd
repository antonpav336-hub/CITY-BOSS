extends CanvasLayer
class_name GameHUD

var money_label: Label
var energy_label: Label
var hint_label: Label
var controls: MobileControls

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	money_label = _label(root, "$ 1,250", Vector2(24, 22), 26)
	energy_label = _label(root, "ENERGY 100%", Vector2(24, 58), 17)
	hint_label = _label(root, "CITY BOSS  •  Find your first opportunity", Vector2(24, 92), 15)
	controls = MobileControls.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(controls)

func _label(parent: Control, value: String, pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func set_energy(value: float) -> void:
	energy_label.text = "ENERGY %d%%" % roundi(value)

func show_interaction(label: String, message: String) -> void:
	hint_label.text = "%s — %s" % [label, message]
