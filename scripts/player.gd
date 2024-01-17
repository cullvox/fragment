extends CharacterBody3D

@export_group("physics")
@export var PLAYER_PUSH = 5 # kg
@export var SPEED = 5.0
@export var SPRINT_SPEED = 8.0
@export var JUMP_VELOCITY = 4.5

@export_group("input")
@export var CAMERA_MAX_X = 85
@export var CAMERA_MIN_X = -85

@export_group("interact")
@export var INTERACT_DISTANCE = 3
@export var SELECTED_NODE : Interact = null

var sprinting = false
var current_speed = SPEED

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var sensitivty = 0.01

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D

func player_has_item():
	pass

func _process(delta):
	process_interact()
	
func process_interact():
	
	# Send out a raycast for any interactable objects.
	var space_state = get_world_3d().direct_space_state
	var camera_global = camera.get_global_transform()
	var origin = camera.global_position
	var end = origin + -camera_global.basis.z * INTERACT_DISTANCE
	var query = PhysicsRayQueryParameters3D.create(origin, end, 0xFFFFFFFF, [self])
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	var hovered = result.get("collider")
	
	# If nothing is there then nothing is interactable.
	if !hovered:
		SELECTED_NODE = null
		return
	
	# Make sure that the casted object is in any interact groups.
	if hovered.is_in_group("interact"):
		SELECTED_NODE = hovered as Interact
	
	# This object is not interactable.
	else:
		SELECTED_NODE = null

func pickup(node):
	node.is_in_group("pickupable")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * sensitivty)
			camera.rotate_x(-event.relative.y * sensitivty)
			camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(CAMERA_MIN_X), deg_to_rad(CAMERA_MAX_X))

	sprinting = Input.is_action_pressed("sprint")
	
	if Input.is_action_pressed("interact"):
		
		print("Interacting with: ", SELECTED_NODE)
		
		if SELECTED_NODE:
			SELECTED_NODE.interact.emit()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back");
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if sprinting:
		current_speed = SPRINT_SPEED
	else:
		current_speed = SPEED

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Compute inertia on other objects the player interacts with
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * (velocity.length() + PLAYER_PUSH));
