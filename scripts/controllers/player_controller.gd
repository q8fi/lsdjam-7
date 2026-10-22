extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed : float = 14.0
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration : float = 75.0

@export var sensitivity : float = 5.0
@export var jump_height : float = 15.0

@export var viewbob_freq : float = 2.4
@export var viewbob_amp : float = 0.06
var viewbob_time : float = 0

const PITCH_MIN := deg_to_rad(-80.0)
const PITCH_MAX := deg_to_rad(80.0)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent):
	var captured := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

	# Frees the mouse on escape
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed and not captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseMotion and captured:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x - event.relative.y * sensitivity, PITCH_MIN, PITCH_MAX)

func _physics_process(delta: float):
	# Reads all four move actions at once
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)

	# Ground Velocity
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		velocity.y -= fall_acceleration * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_height

	# Moving the Character
	move_and_slide()

	_view_bob(delta)



func _view_bob(delta: float) -> void:
	if is_on_floor() and velocity.length() > 0.1:
		viewbob_time += delta * velocity.length()

		var new_pos = Vector3.ZERO
		new_pos.y = sin(viewbob_time * viewbob_freq) * viewbob_amp
		new_pos.x = cos(viewbob_time * viewbob_freq / 2.0) * (viewbob_amp * 0.5)

		camera.transform.origin = new_pos
	else:
		viewbob_time = 0.0
		camera.transform.origin = camera.transform.origin.lerp(Vector3.ZERO, delta * 10.0)
