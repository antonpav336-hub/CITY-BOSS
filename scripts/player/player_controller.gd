extends CharacterBody3D
class_name PlayerController

signal energy_changed(value: float)
signal interaction_requested(label: String, message: String)

@export var walk_speed := 4.2
@export var sprint_speed := 6.4
@export var acceleration := 18.0
@export var gravity := 20.0
@export var look_sensitivity := 0.008

var energy := 100.0
var move_input := Vector2.ZERO
var look_delta := Vector2.ZERO
var _camera_yaw := 0.0
var _camera_pitch := -0.18
var _camera: Camera3D
var _spring_arm: SpringArm3D
var _interact_area: Area3D

func _ready() -> void:
	_make_collision()
	_make_visual()
	_make_camera()
	_interact_area = Area3D.new()
	_interact_area.name = "InteractionProbe"
	var probe_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.0
	probe_shape.shape = sphere
	_interact_area.add_child(probe_shape)
	_interact_area.position = Vector3(0, 1.0, -0.5)
	add_child(_interact_area)
	add_to_group("player")

func _make_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

func _make_visual() -> void:
	# Stylized CITY BOSS protagonist: layered hoodie, cargo trousers,
	# chestnut textured hair, skin and sneakers. The collision capsule stays separate.
	var visual := Node3D.new()
	visual.name = "ProtagonistVisual"
	add_child(visual)

	var hoodie := _material(Color(0.075, 0.085, 0.105), 0.92)
	var hoodie_light := _material(Color(0.13, 0.145, 0.17), 0.9)
	var shirt := _material(Color(0.38, 0.40, 0.43), 0.95)
	var pants := _material(Color(0.075, 0.105, 0.16), 0.9)
	var pants_detail := _material(Color(0.12, 0.15, 0.20), 0.95)
	var skin := _material(Color(0.72, 0.49, 0.36), 0.78)
	var hair := _material(Color(0.19, 0.105, 0.065), 0.88)
	var hair_tip := _material(Color(0.48, 0.31, 0.17), 0.82)
	var shoes := _material(Color(0.82, 0.83, 0.82), 0.72)
	var sole := _material(Color(0.10, 0.11, 0.13), 0.9)
	var eyes := _material(Color(0.035, 0.025, 0.02), 0.5)

	# Shoes and legs
	_add_box(visual, Vector3(0.255, 0.14, 0.40), Vector3(-0.15, 0.12, -0.055), shoes)
	_add_box(visual, Vector3(0.255, 0.07, 0.405), Vector3(-0.15, 0.055, -0.055), sole)
	_add_box(visual, Vector3(0.255, 0.14, 0.40), Vector3(0.15, 0.12, -0.055), shoes)
	_add_box(visual, Vector3(0.255, 0.07, 0.405), Vector3(0.15, 0.055, -0.055), sole)
	_add_capsule(visual, 0.115, 0.72, Vector3(-0.15, 0.48, 0.0), pants)
	_add_capsule(visual, 0.115, 0.72, Vector3(0.15, 0.48, 0.0), pants)
	_add_box(visual, Vector3(0.49, 0.20, 0.30), Vector3(0, 0.78, 0.015), pants)
	_add_box(visual, Vector3(0.16, 0.19, 0.035), Vector3(-0.245, 0.72, -0.12), pants_detail)
	_add_box(visual, Vector3(0.16, 0.19, 0.035), Vector3(0.245, 0.72, -0.12), pants_detail)

	# Hoodie torso and hood
	_add_box(visual, Vector3(0.60, 0.63, 0.34), Vector3(0, 1.22, 0.015), hoodie)
	_add_box(visual, Vector3(0.29, 0.38, 0.055), Vector3(0, 1.20, -0.184), shirt)
	_add_sphere(visual, Vector3(0, 1.51, 0.12), Vector3(0.23, 0.25, 0.16), hoodie_light)
	_add_capsule(visual, 0.075, 0.20, Vector3(0, 1.57, -0.015), skin)

	# Sleeves, cuffs and hands
	_add_capsule(visual, 0.095, 0.43, Vector3(-0.385, 1.22, 0.015), hoodie, Vector3(0, 0, -13))
	_add_capsule(visual, 0.095, 0.43, Vector3(0.385, 1.22, 0.015), hoodie, Vector3(0, 0, 13))
	_add_capsule(visual, 0.082, 0.20, Vector3(-0.43, 0.91, -0.01), hoodie_light, Vector3(0, 0, -8))
	_add_capsule(visual, 0.082, 0.20, Vector3(0.43, 0.91, -0.01), hoodie_light, Vector3(0, 0, 8))
	_add_sphere(visual, Vector3(-0.445, 0.79, -0.015), Vector3(0.075, 0.095, 0.07), skin)
	_add_sphere(visual, Vector3(0.445, 0.79, -0.015), Vector3(0.075, 0.095, 0.07), skin)

	# Head and stylized crop / forward fringe
	_add_sphere(visual, Vector3(0, 1.76, 0), Vector3(0.19, 0.235, 0.18), skin)
	_add_sphere(visual, Vector3(0, 1.91, 0.015), Vector3(0.205, 0.12, 0.19), hair)
	_add_sphere(visual, Vector3(-0.11, 1.84, -0.145), Vector3(0.075, 0.105, 0.075), hair)
	_add_sphere(visual, Vector3(-0.035, 1.83, -0.17), Vector3(0.07, 0.12, 0.07), hair_tip)
	_add_sphere(visual, Vector3(0.045, 1.84, -0.17), Vector3(0.075, 0.115, 0.07), hair)
	_add_sphere(visual, Vector3(0.12, 1.85, -0.14), Vector3(0.07, 0.10, 0.07), hair_tip)
	_add_sphere(visual, Vector3(-0.195, 1.75, 0.0), Vector3(0.035, 0.055, 0.04), skin)
	_add_sphere(visual, Vector3(0.195, 1.75, 0.0), Vector3(0.035, 0.055, 0.04), skin)
	_add_sphere(visual, Vector3(-0.072, 1.78, -0.163), Vector3(0.018, 0.022, 0.012), eyes)
	_add_sphere(visual, Vector3(0.072, 1.78, -0.163), Vector3(0.018, 0.022, 0.012), eyes)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_piece(parent, mesh, pos, mat)

func _add_capsule(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	_add_piece(parent, mesh, pos, mat, rot)

func _add_sphere(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	_add_piece(parent, mesh, pos, mat, Vector3.ZERO, size)

func _add_piece(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.rotation_degrees = rot
	instance.scale = scl
	instance.material_override = mat
	parent.add_child(instance)

func _make_camera() -> void:
	var pivot := Node3D.new()
	pivot.name = "CameraPivot"
	pivot.position.y = 1.45
	add_child(pivot)
	_spring_arm = SpringArm3D.new()
	_spring_arm.spring_length = 4.2
	_spring_arm.margin = 0.25
	_spring_arm.collision_mask = 1
	pivot.add_child(_spring_arm)
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 70
	_spring_arm.add_child(_camera)
	pivot.rotation.x = _camera_pitch

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)
	elif event is InputEventScreenDrag:
		if event.position.x > get_viewport().get_visible_rect().size.x * 0.42:
			_rotate_camera(event.relative)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _rotate_camera(delta: Vector2) -> void:
	_camera_yaw -= delta.x * look_sensitivity
	_camera_pitch = clampf(_camera_pitch - delta.y * look_sensitivity, -0.85, 0.35)
	rotation.y = _camera_yaw
	if is_instance_valid(_spring_arm):
		_spring_arm.get_parent().rotation.x = _camera_pitch

func _physics_process(delta: float) -> void:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir := move_input if move_input.length() > 0.05 else keyboard
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target := direction * speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	for area in _interact_area.get_overlapping_areas():
		interaction_requested.emit(str(area.get_meta("interaction_label", "Interact")), str(area.get_meta("interaction_message", "")))
		return

func set_move_input(value: Vector2) -> void:
	move_input = value.limit_length(1.0)

func apply_touch_look(delta: Vector2) -> void:
	_rotate_camera(delta)

func request_interact() -> void:
	_try_interact()
