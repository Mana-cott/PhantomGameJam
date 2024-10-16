extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_animation = ""

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
		
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# jump logic
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# movement logic
	if Input.is_action_pressed("move_right"):
		velocity.x = SPEED
		_set_animation("walk", true)
	elif Input.is_action_pressed("move_left"):
		velocity.x = -SPEED
		_set_animation("walk", false)
	elif Input.is_action_pressed("move_down") and is_on_floor():
		velocity = Vector2.ZERO
		_set_animation("crouch", true)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			_set_animation("idle", true)
			
	move_and_slide()
	
func _set_animation(animation_name: String, is_forward: bool):
	if current_animation != animation_name:
		if(is_forward):
			animator.play(animation_name)
		else:
			animator.play_backwards(animation_name)
		current_animation = animation_name

