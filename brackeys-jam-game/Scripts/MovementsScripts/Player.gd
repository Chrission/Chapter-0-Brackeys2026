extends CharacterBody3D

# Constants for movement calculations
const SPEED = 4.0
const JUMP_VELOCITY = 3.5
const SENSITIVITY = 0.001

# Loads right before the node enters "Ready" state, path linked to head and camera in Godot
@onready var head = $Head
@onready var camera = $Head/Camera3D

# Calls when node is "Ready"
func _ready():
	# Gets our mouse input ready
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Calls when there is some input that hasn't been consumed by one of the other input items
func _unhandled_input(event):
	# If event is mouse movement, then activate our camera controls
	if event is InputEventMouseMotion:
		# Rotate the camera/head based on the event's relative input from our mouse multiplied by our const sensitivity
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		# Controls cameras vertical clamp, -40 is min 60 is max, can be adjusted
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		# Controls head horizontal clamp, -75 is min, 75 is max, can be adjusted
		# Issues where head can't turn any farther, must fix later head.rotation.y = clamp(head.rotation.y, deg_to_rad(-75), deg_to_rad(75))


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	# head.transform.basis changes direction to where the head is looking, instead of the regular 3d body
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
