extends Node3D
## Procedural low-poly city district for CITY BOSS.

const KenneyCityAssets = preload("res://scripts/assets/kenney_city_assets.gd")

var player: CharacterBody3D

func _ready() -> void:
	if OS.get_name() == "Android":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	_build_environment()
	_build_city()
	_spawn_player()
	_create_hud()

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.20, 0.39, 0.64)
	sky_material.sky_horizon_color = Color(0.72, 0.80, 0.88)
	sky_material.ground_bottom_color = Color(0.16, 0.18, 0.20)
	sky_material.ground_horizon_color = Color(0.55, 0.59, 0.62)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.68, 0.73, 0.82)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _build_city() -> void:
	# Continuous terrain, avenue, sidewalks and painted road markings.
	_box("City ground", Vector3(0, -0.3, -25), Vector3(150, 0.6, 180), Color(0.30, 0.38, 0.32), true)
	_box("Main avenue", Vector3(0, 0.015, -25), Vector3(15, 0.12, 180), Color(0.105, 0.12, 0.14), true)
	for side in [-1.0, 1.0]:
		_box("Sidewalk", Vector3(side * 9.5, 0.08, -25), Vector3(4.0, 0.22, 180), Color(0.56, 0.57, 0.55), true)
		_box("Curb", Vector3(side * 7.45, 0.16, -25), Vector3(0.22, 0.28, 180), Color(0.76, 0.75, 0.69), true)

	for z in range(-100, 55, 8):
		_box("Lane dash", Vector3(0, 0.09, float(z)), Vector3(0.16, 0.025, 3.2), Color(0.92, 0.88, 0.68), false)

	# Side streets and pedestrian crossings make the district read as a real grid.
	for z in [-12.0, -42.0, -72.0]:
		_box("Cross street", Vector3(0, 0.025, z), Vector3(110, 0.13, 9), Color(0.12, 0.135, 0.15), true)
		for stripe in range(7):
			_box("Crosswalk marking", Vector3(-5.4 + stripe * 1.8, 0.11, z + 4.9), Vector3(0.95, 0.035, 2.0), Color(0.88, 0.88, 0.82), false)

	# Six varied buildings on each side of the main avenue.
	var palettes := [
		Color(0.72, 0.48, 0.34), Color(0.48, 0.57, 0.64),
		Color(0.76, 0.70, 0.57), Color(0.42, 0.48, 0.49),
		Color(0.66, 0.42, 0.34), Color(0.58, 0.62, 0.66)
	]
	var heights := [12.0, 19.0, 14.0, 23.0, 16.0, 20.0]
	var positions := [-91.0, -65.0, -39.0, -13.0, 13.0, 39.0]
	for side in [-1.0, 1.0]:
		for i in range(positions.size()):
			var h: float = heights[i]
			var palette: Color = palettes[(i + (1 if side < 0.0 else 0)) % palettes.size()]
			_build_building(side * 23.0, positions[i], 13.0, 19.0, h, palette, i)

	# Street furniture, trees, parked cars and recognizable city props.
	for z in range(-94, 48, 18):
		for side in [-1.0, 1.0]:
			_build_streetlight(side * 7.0, float(z))
			_build_tree(side * 12.5, float(z) - 5.0)
	for z in [-55.0, -28.0, 8.0, 32.0]:
		_build_car(-5.1 if int(z) % 2 == 0 else 5.1, z, int(z) % 2 == 0)

	_add_shop_sign(Vector3(-16.35, 3.5, -12.0), "MARKET", Color(0.18, 0.55, 0.36))
	_add_shop_sign(Vector3(16.35, 3.5, -40.0), "CITY CAFE", Color(0.70, 0.34, 0.20))
	_add_interaction(Vector3(-12.0, 1.0, -12.0), "Market", "Your first business opportunity is coming soon.")
	_add_interaction(Vector3(12.0, 1.0, -40.0), "Cafe", "A place to meet people and find work.")

	var traffic_light := KenneyCityAssets.create_model("traffic-light")
	if traffic_light != null:
		traffic_light.position = Vector3(7.0, 0.12, -12.0)
		traffic_light.scale = Vector3.ONE * 3.0
		add_child(traffic_light)
	var dumpster := KenneyCityAssets.create_model("dumpster")
	if dumpster != null:
		dumpster.position = Vector3(15.0, 0.12, -17.0)
		dumpster.scale = Vector3.ONE * 3.0
		add_child(dumpster)

func _build_building(x: float, z: float, width: float, depth: float, height: float, color: Color, style: int) -> void:
	_box("Building", Vector3(x, height * 0.5, z), Vector3(width, height, depth), color, true)
	_box("Roof parapet", Vector3(x, height + 0.25, z), Vector3(width + 0.35, 0.5, depth + 0.35), color.darkened(0.18), false)
	var road_side := -1.0 if x > 0.0 else 1.0
	var face_x := x + road_side * (width * 0.5 + 0.075)
	var floors := int(height / 3.2)
	for floor_index in range(floors):
		var y := 2.0 + float(floor_index) * 3.1
		for window_index in range(3):
			var window_z := z - 5.0 + float(window_index) * 5.0
			_box("Window", Vector3(face_x, y, window_z), Vector3(0.12, 1.45, 2.0), Color(0.20, 0.34, 0.43), false)
			_box("Window sill", Vector3(face_x + road_side * 0.08, y - 0.82, window_z), Vector3(0.18, 0.12, 2.2), Color(0.78, 0.76, 0.68), false)
	# Ground-floor shopfront and doorway.
	_box("Shopfront glass", Vector3(face_x + road_side * 0.015, 1.55, z), Vector3(0.14, 2.35, 5.2), Color(0.13, 0.25, 0.30), false)
	_box("Shop awning", Vector3(face_x + road_side * 0.35, 3.0, z), Vector3(0.9, 0.28, 6.4), [Color(0.72,0.28,0.18), Color(0.18,0.42,0.55), Color(0.72,0.58,0.25)][style % 3], false)

func _add_shop_sign(pos: Vector3, title: String, color: Color) -> void:
	var sign := Label3D.new()
	sign.text = title
	sign.position = pos
	sign.font_size = 48
	sign.pixel_size = 0.012
	sign.modulate = Color.WHITE
	sign.outline_size = 8
	sign.outline_modulate = Color(0.06, 0.07, 0.08)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sign)
	_box("Shop sign backing", pos + Vector3(0, 0, 0.08), Vector3(0.18, 0.9, 4.8), color, false)

func _build_streetlight(x: float, z: float) -> void:
	_box("Lamp post", Vector3(x, 3.0, z), Vector3(0.16, 6.0, 0.16), Color(0.12, 0.14, 0.16), false)
	_box("Lamp arm", Vector3(x * 0.94, 5.85, z), Vector3(0.95, 0.13, 0.14), Color(0.12, 0.14, 0.16), false)
	_box("Lamp", Vector3(x * 0.88, 5.72, z), Vector3(0.65, 0.16, 0.42), Color(1.0, 0.86, 0.58), false)

func _build_tree(x: float, z: float) -> void:
	_box("Tree trunk", Vector3(x, 1.0, z), Vector3(0.42, 2.0, 0.42), Color(0.28, 0.18, 0.12), false)
	var crown := SphereMesh.new()
	crown.radius = 1.55
	crown.height = 3.1
	var tree := MeshInstance3D.new()
	tree.mesh = crown
	tree.position = Vector3(x, 3.0, z)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.42, 0.25)
	material.roughness = 1.0
	tree.material_override = material
	add_child(tree)

func _build_car(x: float, z: float, dark: bool) -> void:
	var body_color := Color(0.12, 0.18, 0.24) if dark else Color(0.66, 0.20, 0.14)
	_box("Parked car body", Vector3(x, 0.72, z), Vector3(2.15, 0.85, 4.1), body_color, false)
	_box("Car cabin", Vector3(x, 1.35, z - 0.15), Vector3(1.72, 0.72, 2.1), Color(0.20, 0.32, 0.39), false)
	for wheel_z in [-1.35, 1.35]:
		for wheel_x in [-1.0, 1.0]:
			_box("Car wheel", Vector3(x + wheel_x, 0.42, z + wheel_z), Vector3(0.22, 0.58, 0.72), Color(0.035, 0.04, 0.045), false)

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
	sphere.radius = 1.8
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
