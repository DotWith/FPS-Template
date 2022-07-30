extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSETIVITY = 0.3

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var health = 100
var damage = 25

@onready
var ui = $UI

@onready
var head = $Head

@onready
var raycast = $Head/Camera3D/RayCast3D

func _ready():
	if is_multiplayer_authority():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	$Body.visible = !is_multiplayer_authority()
	$Head/Camera3D.current = is_multiplayer_authority()
	
	ui.visible = is_multiplayer_authority()
	ui.health = health

func _input(event):
	if is_multiplayer_authority():
		# Get mouse input for camera rotation
		if event is InputEventMouseMotion:
			rotate_y(deg2rad(-event.relative.x * MOUSE_SENSETIVITY))
			head.rotate_x(deg2rad(-event.relative.y * MOUSE_SENSETIVITY))
			head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _process(_delta):
	if not is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("fire"):
		if raycast.is_colliding():
			var target = raycast.get_collider()
			if target.has_method("take_damage"):
				target.rpc(&"take_damage", damage)
	
	if Input.is_action_just_pressed("take_damage"):
		rpc(&"take_damage", damage)

@rpc(any_peer, call_local)
func take_damage(_damage):
	if health > 0:
		health -= _damage
		ui.health = health
	else:
		health = 0
		ui.health = health

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Local movement
	move_and_slide()
