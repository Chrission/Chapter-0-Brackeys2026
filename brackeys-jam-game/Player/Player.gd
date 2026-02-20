extends CharacterBody3D

# Movement Variables
var speed
var jump_velocity
const WALK_SPEED = 4.0
const SPRINT_SPEED = 6.5
const WALK_JUMP_VELOCITY = 3.5
const SPRINT_JUMP_VELOCITY = 4.0
const SENSITIVITY = 0.001

# Bob Variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Loads right before the node enters "Ready" state, path linked to head and camera in Godot
@onready var head = $Head
@onready var camera = $Head/Camera3D

# Variables for handling the holding and throwing of objects
@export_category("Holding Objects")
@export var throwForce = 7.5
@export var followSpeed = 5.0
@export var followDistance = 2.5
@export var maxDistanceFromCamera = 5.0
@export var dropBelowPlayer = false
@export var groundRay: RayCast3D

@onready var interactRay = $Head/Camera3D/InteractRay
var heldObject: RigidBody3D


# Calls when node is "Ready"
func _ready():
	# Gets our mouse input ready
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$MeshInstance3D.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# Calls when there is some input that hasn't been consumed by one of the other input items
func _input(event):
	# If event is mouse movement, then activate our camera controls
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the camera/head based on the event's relative input from our mouse multiplied by our const sensitivity
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		# Controls cameras vertical clamp, -40 is min 60 is max, can be adjusted
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-50), deg_to_rad(60))
		# Controls head horizontal clamp, -75 is min, 75 is max, can be adjusted
		# Issues where head can't turn any farther, must fix later head.rotation.y = clamp(head.rotation.y, deg_to_rad(-75), deg_to_rad(75))

	# if event is InputEventKey and event.pressed:
	#	if event.keycode == Key.KEY_ESCAPE:
	#			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#		else:
	#			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# held object handling
	handle_holding_objects()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get whether we are sprinting or not to set speed
	if Input.is_action_pressed("move_sprint"):
		speed = SPRINT_SPEED
		jump_velocity = SPRINT_JUMP_VELOCITY
	else:
		speed = WALK_SPEED
		jump_velocity = WALK_JUMP_VELOCITY

	# Handle jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	# head.transform.basis changes direction to where the head is looking, instead of the regular 3d body
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)


	# Head Bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

 # series of functions focused on item interactivity (from the "Picking Up, Dropping and Throwing Physics Objects" tutorial
func set_held_object(body: RigidBody3D):
	heldObject = body

func drop_held_object():
	heldObject = null

func throw_held_object():
	var obj = heldObject
	drop_held_object()
	obj.apply_central_impulse(-camera.global_transform.basis.z * throwForce * 10)

# General interactivity function
func handle_holding_objects():
	# If: the player has an item, and they press the "throw" button while holding an item,
	# Then: throw
	if Input.is_action_just_pressed("throw"):
		if heldObject != null:
			throw_held_object()
	# If: the player presses the "interact" button
	# Then If: the player is holding an onject
	# Then: drop item
	# Else If: the player had an item infront of them
	# Then: hold the object
	if Input.is_action_just_pressed("interact"):
		if heldObject != null: drop_held_object()
		elif interactRay.is_colliding() and interactRay.get_collider() is RigidBody3D:
			set_held_object(interactRay.get_collider())
		else:
			set_held_object(null)

	# If: the player is holding an object
	# Then: give the item a velocity relative to the player
	if heldObject != null:
		var targetPos = camera.global_transform.origin + (camera.global_basis * Vector3(0, 0, -followDistance))
		var objectPos = heldObject.global_transform.origin
		heldObject.linear_velocity = (targetPos - objectPos) * followSpeed
		# If: the held item gets too far away
		# Then: drop item
		if heldObject.global_position.distance_to(camera.global_position) > maxDistanceFromCamera:
			drop_held_object()
		# If: dropBelowPlayer is enabled, and something is beneath the player
		# Then If: the object below the player is the held item
		# Then: drop item
		if dropBelowPlayer && groundRay.is_colliding():
			if groundRay.get_collider() == heldObject: drop_held_object()
