extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSETIVITY = 0.3

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready
var head = $Head

@onready
var raycast = $Head/Camera3D/RayCast3D

@export
var synced_rotation: Vector2

@export
var health := 100.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	$Body.visible = !is_multiplayer_authority()
	$Head/Camera3D.current = is_multiplayer_authority()
	
	if is_multiplayer_authority():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if not is_multiplayer_authority():
		return
	
	# Get mouse input for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSETIVITY))
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSETIVITY))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		synced_rotation = Vector2(head.rotation.x, rotation.y)

func _process(_delta):
	if not is_multiplayer_authority():
		head.rotation.x = synced_rotation.x
		rotation.y = synced_rotation.y
		return
	
	if Input.is_action_just_pressed("fire"):
		if raycast.is_colliding():
			var target = raycast.get_collider()
			if target.has_method("take_damage"):
				target.take_damage.rpc(25)

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

# RPCs
@rpc(call_local, any_peer, reliable)
func take_damage(damage):
	health -= damage
	
	if is_multiplayer_authority():
		Global.update_health.emit(health)

@rpc(call_local, any_peer, reliable)
func set_position_with_rpc(new_position):
	position = new_position
