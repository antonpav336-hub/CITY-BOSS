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
	var body_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.34
	capsule.height = 1.72
	body_mesh.mesh = capsule
	body_mesh.position.y = 0.88
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.34, 0.52)
	mat.roughness = 0.75
	body_mesh.material_override = mat
	add_child(body_mesh)

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
		# Right-half touch drag rotates the camera; left-half is reserved for joystick.
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
