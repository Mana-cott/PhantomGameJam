extends CharacterBody2D

const SPEED = 300.0
const SPRINT_SPEED = 600.0
const JUMP_VELOCITY = -400.0
const DOUBLE_TAP_SPRINT_TIME = 0.3  # Time between taps which triggers sprint
const LIGHT_PUNCH_DURATION = 0.3  # How long the LP animation lasts

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_animation = ""
var sprinting = false
var light_punching = false  # Tracks if LP is happening
var light_punch_timer = 0.0  # Time left for LP animation
var last_right_tap_time = 0.0 # Tracks sprint logic

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	# Update sprint trackers
	last_right_tap_time += delta
	
	# Handle LP timer
	if light_punching:
		light_punch_timer -= delta
		if light_punch_timer <= 0:
			light_punching = false
			_set_animation("idle", true)  # Return to idle after LP
		return  # Skips if LP

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump logic
	if Input.is_action_just_pressed("move_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# LightPunch logic (LP)
	if Input.is_action_just_pressed("light_punch") and not light_punching:
		_set_animation("light_punch", true)
		light_punching = true
		light_punch_timer = LIGHT_PUNCH_DURATION
		return  # skips if LP

	# Movement logic
	if Input.is_action_pressed("move_right"):
		if sprinting or _is_double_tap_sprint():
			sprinting = true
			velocity.x = SPRINT_SPEED
			_set_animation("run", true)
		else:
			velocity.x = SPEED
			_set_animation("walk", true)
	elif Input.is_action_pressed("move_left"):
		velocity.x = -SPEED
		_set_animation("walk", false)
		sprinting = false
	elif Input.is_action_pressed("move_down") and is_on_floor():
		velocity = Vector2.ZERO
		_set_animation("crouch", true)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			_set_animation("idle", true)
		sprinting = false

	move_and_slide()

# animation handler
func _set_animation(animation_name: String, is_forward: bool):
	if current_animation != animation_name:
		if is_forward:
			animator.play(animation_name)
		else:
			animator.play_backwards(animation_name)
		current_animation = animation_name

# sprint checker
func _is_double_tap_sprint() -> bool:
	if Input.is_action_just_pressed("move_right"):
		if last_right_tap_time < DOUBLE_TAP_SPRINT_TIME:
			last_right_tap_time = 0.0
			return true
		last_right_tap_time = 0.0
	return false
