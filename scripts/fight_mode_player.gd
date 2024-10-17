extends CharacterBody2D

const SPEED = 300.0
const SPRINT_SPEED = 600.0
const JUMP_VELOCITY = -600.0
const DOUBLE_TAP_SPRINT_TIME = 0.3
const LIGHT_PUNCH_DURATION = 0.3
const HEAVY_PUNCH_DURATION = 0.8
const LIGHT_KICK_DURATION = 0.4
const HEAVY_KICK_DURATION = 0.9
const HADOUKEN_DURATION = 0.5
const HADOUKEN_INPUT_TIME = 0.5
const FIREBALL_SPEED = 400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_animation = ""
var sprinting = false
var light_punching = false
var heavy_punching = false
var light_kicking = false
var heavy_kicking = false
var light_punch_timer = 0.0
var heavy_punch_timer = 0.0
var light_kick_timer = 0.0
var heavy_kick_timer = 0.0
var last_right_tap_time = 0.0
var jump_committed = false
var hadouken_playing = false 
var is_throwing_hadouken = false
var hadouken_duration_timer = 0.0
var hadouken_input_timer = 0.0
var hadouken_step = 0

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var fireball_spawn: Marker2D = $FireballSpawn
@onready var fireball_scene = preload("res://scenes/fireball.tscn")

func _physics_process(delta):
	last_right_tap_time += delta
	
	# Handle Hadouken duration logic
	if hadouken_playing:
		velocity.x = 0
		hadouken_duration_timer -= delta
		if hadouken_duration_timer <= 0:
			hadouken_playing = false
			is_throwing_hadouken = false 
			_set_animation("idle", true)
			return  # Stops other logic while playing Hadouken

	# Update Hadouken input timer
	hadouken_input_timer -= delta
	if hadouken_input_timer <= 0:
		hadouken_step = 0

	# Handle LP timer
	if light_punching:
		velocity.x = 0
		light_punch_timer -= delta
		if light_punch_timer <= 0:
			light_punching = false
			_set_animation("idle", true)  # Return to idle after LP
	# Handle HP timer
	if heavy_punching:
		velocity.x = 0
		heavy_punch_timer -= delta
		if heavy_punch_timer <= 0:
			heavy_punching = false
			_set_animation("idle", true)  # Return to idle after HP
	# Handle LK timer
	if light_kicking:
		velocity.x = 0
		light_kick_timer -= delta
		if light_kick_timer <= 0:
			light_kicking = false
			_set_animation("idle", true)  # Return to idle after LK
	# Handle HK timer
	if heavy_kicking:
		velocity.x = 0
		heavy_kick_timer -= delta
		if heavy_kick_timer <= 0:
			heavy_kicking = false
			_set_animation("idle", true)  # Return to idle after HK

	# Gravity handling
	if not is_on_floor():
		velocity.y += gravity * delta
		
		if velocity.x != 0:
			if velocity.x > 0:
				_set_animation("airborne_moving", true)
			else:
				_set_animation("airborne_moving", false)
		else:
			_set_animation("airborne", true)
	else:
		jump_committed = false

	# Jump logic
	if Input.is_action_just_pressed("move_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_set_animation("jump_start", true)
		jump_committed = true

	# Hadouken input sequence tracking
	_check_hadouken_sequence()

	# Light Punch logic (LP)
	if Input.is_action_just_pressed("light_punch") and not light_punching and not heavy_punching and not light_kicking and not heavy_kicking:
		if hadouken_step == 3:
			_trigger_hadouken()
		else:
			_set_animation("light_punch", true)
			light_punching = true
			light_punch_timer = LIGHT_PUNCH_DURATION
			
	# Heavy Punch logic (HP)
	if Input.is_action_just_pressed("heavy_punch") and not heavy_punching and not light_punching and not light_kicking and not heavy_kicking:
		if hadouken_step == 3:
			_trigger_hadouken()
		else:
			_set_animation("heavy_punch", true)
			heavy_punching = true
			heavy_punch_timer = HEAVY_PUNCH_DURATION
			
	# Light Kick logic (LK)
	if Input.is_action_just_pressed("light_kick") and not light_kicking and not heavy_kicking and not light_punching and not heavy_punching:
		_set_animation("light_kick", true)
		light_kicking = true
		light_kick_timer = LIGHT_KICK_DURATION
		
	# Heavy Kick logic (HK)
	if Input.is_action_just_pressed("heavy_kick") and not heavy_kicking and not light_kicking and not light_punching and not heavy_punching:
		_set_animation("heavy_kick", true)
		heavy_kicking = true
		heavy_kick_timer = HEAVY_KICK_DURATION

	# Prevent sideways movement during a jump, and any movement during combat
	if not jump_committed and not hadouken_playing and not light_punching and not heavy_punching and not light_kicking and not heavy_kicking:
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
			# Check if we should set to idle
			if is_on_floor() and not light_punching and not is_throwing_hadouken:
				_set_animation("idle", true)
			sprinting = false

	# Apply movement
	move_and_slide()


# Animation handler
func _set_animation(animation_name: String, is_forward: bool):
	if current_animation != animation_name:
		if is_forward:
			animator.play(animation_name)
		else:
			animator.play_backwards(animation_name)
		current_animation = animation_name

# Sprint checker
func _is_double_tap_sprint() -> bool:
	if Input.is_action_just_pressed("move_right"):
		if last_right_tap_time < DOUBLE_TAP_SPRINT_TIME:
			last_right_tap_time = 0.0
			return true
		last_right_tap_time = 0.0
	return false

# Hadouken input sequence checker
func _check_hadouken_sequence():
	match hadouken_step:
		0:
			if Input.is_action_just_pressed("move_down"):
				hadouken_step = 1
				hadouken_input_timer = HADOUKEN_INPUT_TIME
				print("step 1")
		1:
			if Input.is_action_just_pressed("move_right"):
				hadouken_step = 2
				print("step 2")
		2:
			if Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_down"):
				print("step 3")
				hadouken_step = 3  # Hadouken sequence complete!

# Trigger Hadouken animation
func _trigger_hadouken():
	# Animation logic
	light_punching = false
	hadouken_playing = true
	is_throwing_hadouken = true
	hadouken_duration_timer = HADOUKEN_DURATION
	_set_animation("hadouken", true)

	# Delay before fireball spawn
	await get_tree().create_timer(0.3).timeout

	# Fireball logic
	var fireball_instance = fireball_scene.instantiate()
	var spawn_point = fireball_spawn.position
	fireball_instance.position = spawn_point
	add_child(fireball_instance)
	fireball_instance.velocity = Vector2(FIREBALL_SPEED, 0)

	hadouken_step = 0
