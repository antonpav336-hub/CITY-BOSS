extends Node3D
## Stage 1 greybox world. Replace generated primitives with approved Blender assets later.

var player: CharacterBody3D

func _ready() -> void:
	_build_environment()
	_build_apartment_and_yard()
	_spawn_player()
	_create_hud()

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.68, 0.78)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

func _build_apartment_and_yard() -> void:
	_box("Courtyard", Vector3(0, -0.15, 0), Vector3(34, 0.3, 34), Color(0.24, 0.29, 0.27), true)
	_box("Apartment floor", Vector3(0, 0.02, -5), Vector3(10, 0.2, 9), Color(0.48, 0.45, 0.4), true)
	_box("Back wall", Vector3(0, 1.6, -9.4), Vector3(10, 3.2, 0.25), Color(0.72, 0.69, 0.62), true)
	_box("Left wall", Vector3(-4.9, 1.6, -5), Vector3(0.25, 3.2, 9), Color(0.72, 0.69, 0.62), true)
	_box("Right wall", Vector3(4.9, 1.6, -5), Vector3(0.25, 3.2, 9), Color(0.72, 0.69, 0.62), true)
	_box("Front wall left", Vector3(-3.2, 1.6, -0.55), Vector3(3.6, 3.2, 0.25), Color(0.72, 0.69, 0.62), true)
	_box("Front wall right", Vector3(3.2, 1.6, -0.55), Vector3(3.6, 3.2, 0.25), Color(0.72, 0.69, 0.62), true)
	_box("Bed", Vector3(-2.6, 0.45, -7.1), Vector3(2.5, 0.65, 2.0), Color(0.35, 0.43, 0.52), false)
	_box("Kitchen counter", Vector3(2.8, 0.55, -8.4), Vector3(3.2, 1.0, 0.8), Color(0.34, 0.31, 0.28), false)
	_box("Wardrobe", Vector3(-4.1, 1.1, -3.0), Vector3(1.0, 2.2, 1.4), Color(0.30, 0.23, 0.18), false)
	_box("Courtyard path", Vector3(0, 0.03, 7), Vector3(4, 0.08, 14), Color(0.38, 0.39, 0.37), true)
	_box("Street", Vector3(0, 0.0, 17), Vector3(34, 0.12, 5), Color(0.12, 0.13, 0.14), true)
	_box("Building block", Vector3(12, 3.0, -5), Vector3(8, 6, 12), Color(0.48, 0.51, 0.53), true)
	_box("Building block 2", Vector3(-12, 4.0, -8), Vector3(7, 8, 10), Color(0.55, 0.50, 0.44), true)
	_add_interaction(Vector3(0, 0.9, -0.2), "Rest", "Resting spot — recovery arrives in Stage 3.")
	_add_interaction(Vector3(0, 0.9, 1.4), "Door", "Apartment entrance")

func _box(label: String, pos: Vector3, box_size: Vector3, color: Color, collision: bool) -> void:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.name = label
	root.position = pos
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	mesh.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mesh.material_override = mat
	root.add_child(mesh)
	if collision:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = box_size
		shape.shape = box_shape
		root.add_child(shape)
	add_child(root)

func _add_interaction(pos: Vector3, label: String, message: String) -> void:
	var area := Area3D.new()
	area.position = pos
	area.set_meta("interaction_label", label)
	area.set_meta("interaction_message", message)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)

func _spawn_player() -> void:
	var script = load("res://scripts/player/player_controller.gd")
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(script)
	player.position = Vector3(0, 0.15, 3.0)
	add_child(player)

func _create_hud() -> void:
	var hud_script = load("res://scripts/ui/game_hud.gd")
	var hud = CanvasLayer.new()
	hud.set_script(hud_script)
	add_child(hud)
	hud.controls.move_changed.connect(player.set_move_input)
	hud.controls.look_dragged.connect(player.apply_touch_look)
	hud.controls.interact_pressed.connect(player.request_interact)
	player.interaction_requested.connect(hud.show_interaction)
