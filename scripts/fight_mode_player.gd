extends CharacterBody2D

const MAX_HEALTH = 100
const SPEED = 300.0
const SPRINT_SPEED = 600.0
const JUMP_VELOCITY = -700.0
const DOUBLE_TAP_SPRINT_TIME = 0.3
const LIGHT_PUNCH_DURATION = 0.3
const HEAVY_PUNCH_DURATION = 0.8
const LIGHT_KICK_DURATION = 0.4
const HEAVY_KICK_DURATION = 0.9
const CROUCH_PUNCH_DURATION = 0.4
const CROUCH_KICK_DURATION = 0.4
const AIRBORNE_PUNCH_DURATION = 0.4
const AIRBORNE_KICK_DURATION = 0.4
const LIGHT_KNOCKBACK_FORCE = 150.0
const HEAVY_KNOCKBACK_FORCE = 300.0
# hadouken
const HADOUKEN_DURATION = 0.5
const HADOUKEN_INPUT_TIME = 0.5
const FIREBALL_SPEED = 400.0
# tatsumaki
const TATSUMAKI_DURATION = 0.7
const TATSUMAKI_INPUT_TIME = 0.5
const TATSUMAKI_SPEED = 600.0
# shoryuken
const SHORYUKEN_DURATION = 0.6
const SHORYUKEN_INPUT_TIME = 0.5
const SHORYUKEN_JUMP_VELOCITY = -300.0
const SHORYUKEN_FORWARD_VELOCITY = 200.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_health = MAX_HEALTH
var current_animation = ""
var is_facing_right = true # starts off true
var is_combo_flipped = false
var third_last_face_value = true
var second_last_face_value = true
var first_last_face_value = true
var hadouken_string_input = "move_right"
var tatsumaki_string_input = "move_left"
var shoryuken_string_input = "move_right"
var sprint_string_input = "move_right"
var is_scale_x_flipped = false
var side_multiplier = 1 # positive
var sprinting = false
var crouching = false
var light_punching = false
var heavy_punching = false
var light_kicking = false
var heavy_kicking = false
var crouch_punching = false
var crouch_kicking = false
var airborne_punching = false
var airborne_kicking = false
var light_punch_timer = 0.0
var heavy_punch_timer = 0.0
var light_kick_timer = 0.0
var heavy_kick_timer = 0.0
var crouch_punch_timer = 0.0
var crouch_kick_timer = 0.0
var airborne_punch_timer = 0.0
var airborne_kick_timer = 0.0
var last_right_tap_time = 0.0
var jump_committed = false
var hadouken_playing = false 
var is_throwing_hadouken = false
var tatsumaki_playing = false
var shoryuken_playing = false
var hadouken_duration_timer = 0.0
var tatsumaki_duration_timer = 0.0
var shoryuken_duration_timer = 0.0
var hadouken_input_timer = 0.0
var tatsumaki_input_timer = 0.0
var shoryuken_input_timer = 0.0
var hurt_timer = 0.0
var hadouken_step = 0
var tatsumaki_step = 0
var shoryuken_step = 0
var combat_state_checker: bool = not light_punching and not heavy_punching and not light_kicking and not heavy_kicking and not crouch_punching and not crouch_kicking and not airborne_punching and not airborne_kicking and not hadouken_playing and not tatsumaki_playing and not shoryuken_playing

@export var is_disabled = false

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var fireball_spawn: Marker2D = $FireballSpawn
@onready var fireball_scene = preload("res://scenes/fireball.tscn")
@onready var right_raycast: RayCast2D = $RayCastRight
@onready var left_raycast: RayCast2D = $RayCastLeft

# hitboxes
@onready var light_punch_hitbox: CollisionShape2D = $LightPunchHitBox/LightPunchCollider
@onready var heavy_punch_hitbox: CollisionShape2D = $HeavyPunchHitBox/HeavyPunchCollider
@onready var light_kick_hitbox: CollisionShape2D = $LightKickHitBox/LightKickCollider
@onready var heavy_kick_hitbox: CollisionShape2D = $HeavyKickHitBox/HeavyKickCollider
@onready var crouch_punch_hitbox: CollisionShape2D = $CrouchPunchHitBox/CrouchPunchCollider
@onready var crouch_kick_hitbox: CollisionShape2D = $CrouchKickHitBox/CrouchKickCollider
@onready var airborne_punch_hitbox: CollisionShape2D = $AirbornePunchHitBox/AirbornePunchCollider
@onready var airborne_kick_hitbox: CollisionShape2D = $AirborneKickHitBox/AirborneKickCollider
@onready var tatsumaki_hitbox: CollisionShape2D = $TatsumakiHitBox/TatsumakiCollider
@onready var shoryuken_hitbox: CollisionShape2D = $ShoryukenHitBox/ShoryukenCollider

func _ready():
	light_punch_hitbox.disabled = true
	heavy_punch_hitbox.disabled = true
	light_kick_hitbox.disabled = true
	heavy_kick_hitbox.disabled = true
	crouch_punch_hitbox.disabled = true
	crouch_kick_hitbox.disabled = true
	airborne_punch_hitbox.disabled = true
	airborne_kick_hitbox.disabled = true
	tatsumaki_hitbox.disabled = true
	shoryuken_hitbox.disabled = true

func _physics_process(delta):
	
	if hurt_timer > 0:
		hurt_timer -= delta
	
	if current_health <= 0:
		_die()
	
	# false, false, true combo that leads to switch
	if(!third_last_face_value && !second_last_face_value && first_last_face_value):
		if is_combo_flipped:
			is_combo_flipped = false
		else:
			is_combo_flipped = true
		if is_combo_flipped:
			hadouken_string_input = "move_left"
			tatsumaki_string_input = "move_right"
			shoryuken_string_input = "move_left"
			sprint_string_input = "move_left"
			side_multiplier = -1
		else:
			hadouken_string_input = "move_right"
			tatsumaki_string_input = "move_left"
			shoryuken_string_input = "move_right"
			sprint_string_input = "move_right"
			side_multiplier = 1
	
	# activate hitboxes
	light_punch_hitbox.disabled = !light_punching
	heavy_punch_hitbox.disabled = !heavy_punching
	light_kick_hitbox.disabled = !light_kicking
	heavy_kick_hitbox.disabled = !heavy_kicking
	crouch_punch_hitbox.disabled = !crouch_punching
	crouch_kick_hitbox.disabled = !crouch_kicking
	airborne_punch_hitbox.disabled = !airborne_punching
	airborne_kick_hitbox.disabled = !airborne_kicking
	tatsumaki_hitbox.disabled = !tatsumaki_playing
	shoryuken_hitbox.disabled = !shoryuken_playing
	
	last_right_tap_time += delta
	
	# Correct flipping logic
	if is_facing_right:
		if is_scale_x_flipped:
			self.scale.x = self.scale.x
			is_scale_x_flipped = false
	else:
		if !is_scale_x_flipped:
			self.scale.x = -self.scale.x
			is_scale_x_flipped = true

	if left_raycast.is_colliding():
		if left_raycast.get_collider() != null and left_raycast.get_collider().is_in_group("enemy"):
			is_facing_right = false
			third_last_face_value = second_last_face_value
			second_last_face_value = first_last_face_value
			first_last_face_value = false
	if right_raycast.is_colliding():
		if right_raycast.get_collider() != null and right_raycast.get_collider().is_in_group("enemy"):
			is_facing_right = true
			third_last_face_value = second_last_face_value
			second_last_face_value = first_last_face_value
			first_last_face_value = true
	
	# Handle Hadouken duration logic
	if hadouken_playing:
		velocity.x = 0
		hadouken_duration_timer -= delta
		if hadouken_duration_timer <= 0:
			hadouken_playing = false
			is_throwing_hadouken = false 
			_set_animation("idle", true)
			return  # Stops other logic while playing Hadouken
	
	if tatsumaki_playing:
		tatsumaki_duration_timer -= delta
		if tatsumaki_duration_timer <= 0:
			tatsumaki_playing = false
			_set_animation("idle", true)
			velocity.x = 0
	
	if shoryuken_playing:
		velocity.x = SHORYUKEN_FORWARD_VELOCITY
		velocity.y = SHORYUKEN_JUMP_VELOCITY
		shoryuken_duration_timer -= delta
		if shoryuken_duration_timer <= 0:
			shoryuken_playing = false
			_set_animation("airborne_moving", true)
			velocity = Vector2.ZERO

	# Update Hadouken input timer
	hadouken_input_timer -= delta
	if hadouken_input_timer <= 0:
		hadouken_step = 0
		
	# Update Tatsumaki input timer
	tatsumaki_input_timer -= delta
	if tatsumaki_input_timer <= 0:
		tatsumaki_step = 0
	
	# Update Shoryuken input timer
	shoryuken_input_timer -= delta
	if shoryuken_input_timer <= 0:
		shoryuken_step = 0

	# Handle LP timer
	if light_punching:
		if is_on_floor():
			velocity.x = 0
		light_punch_timer -= delta
		if light_punch_timer <= 0:
			light_punching = false
			_set_animation("idle", true)  # Return to idle after LP
	# Handle HP timer
	if heavy_punching:
		if is_on_floor():
			velocity.x = 0
		heavy_punch_timer -= delta
		if heavy_punch_timer <= 0:
			heavy_punching = false
			_set_animation("idle", true)  # Return to idle after HP
	# Handle LK timer
	if light_kicking:
		if is_on_floor():
			velocity.x = 0
		light_kick_timer -= delta
		if light_kick_timer <= 0:
			light_kicking = false
			_set_animation("idle", true)  # Return to idle after LK
	# Handle HK timer
	if heavy_kicking:
		if is_on_floor():
			velocity.x = 0
		heavy_kick_timer -= delta
		if heavy_kick_timer <= 0:
			heavy_kicking = false
			_set_animation("idle", true)  # Return to idle after HK
	# Handle CP timer
	if crouch_punching:
		if is_on_floor():
			velocity.x = 0
		crouch_punch_timer -= delta
		if crouch_punch_timer <= 0:
			crouch_punching = false
			_set_animation("crouch", true)  # Return to crouch after CP
	# Handle CK timer
	if crouch_kicking:
		if is_on_floor():
			velocity.x = 0
		crouch_kick_timer -= delta
		if crouch_kick_timer <= 0:
			crouch_kicking = false
			_set_animation("crouch", true)  # Return to crouch after CK
	# Handle AP timer
	if airborne_punching:
		airborne_punch_timer -= delta
		if airborne_punch_timer <= 0:
			airborne_punching = false
			_set_animation("airborne", true)  # Return to falling after AP
	# Handle AK timer
	if airborne_kicking:
		airborne_kick_timer -= delta
		if airborne_kick_timer <= 0:
			airborne_kicking = false
			_set_animation("airborne", true)  # Return to falling after AK

	# Gravity handling
	if not is_on_floor():
		velocity.y += gravity * delta
		
		if not shoryuken_playing and not airborne_punching and not airborne_kicking:
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
	# Tatsumaki input sequence tracking
	_check_tatsumaki_sequence()
	# Shoryuken input sequence tracking
	_check_shoryuken_sequence()

	# Light Punch logic (LP)
	if Input.is_action_just_pressed("light_punch") and combat_state_checker:
		if hadouken_step == 3:
			_trigger_hadouken()
		elif tatsumaki_step == 3:
			_trigger_tatsumaki()
		else:
			_set_animation("light_punch", true)
			light_punching = true
			
			light_punch_timer = LIGHT_PUNCH_DURATION
			
	# Heavy Punch logic (HP)
	if Input.is_action_just_pressed("heavy_punch") and combat_state_checker:
		if hadouken_step == 3:
			_trigger_hadouken()
		elif tatsumaki_step == 3:
			_trigger_tatsumaki()
		else:
			_set_animation("heavy_punch", true)
			heavy_punching = true
			heavy_punch_timer = HEAVY_PUNCH_DURATION
			
	# Light Kick logic (LK)
	if Input.is_action_just_pressed("light_kick") and combat_state_checker:
		if shoryuken_step == 3:
			_trigger_shoryuken()
		else:
			_set_animation("light_kick", true)
			light_kicking = true
			light_kick_timer = LIGHT_KICK_DURATION
		
	# Heavy Kick logic (HK)
	if Input.is_action_just_pressed("heavy_kick") and combat_state_checker:
		if shoryuken_step == 3:
			_trigger_shoryuken()
		else:
			_set_animation("heavy_kick", true)
			heavy_kicking = true
			heavy_kick_timer = HEAVY_KICK_DURATION
	
	# Crouch Punch logic (CP)
	if (Input.is_action_just_pressed("light_punch") or Input.is_action_just_pressed("heavy_punch")) and crouching and combat_state_checker:
		_set_animation("crouch_punch", true)
		crouch_punching = true
		crouch_punch_timer = CROUCH_PUNCH_DURATION
		
	# Crouch Kick logic (CK)
	if (Input.is_action_just_pressed("light_kick") or Input.is_action_just_pressed("heavy_kick")) and crouching and combat_state_checker:
		_set_animation("crouch_kick", true)
		crouch_kicking = true
		crouch_kick_timer = CROUCH_KICK_DURATION
	
	# Airborne Punch logic (AP)
	if (Input.is_action_just_pressed("light_punch") or Input.is_action_just_pressed("heavy_punch")) and not is_on_floor() and combat_state_checker:
		if not airborne_punching:  # Only start if not already airborne punching
			_set_animation("jump_punch", true)
			airborne_punching = true
			airborne_punch_timer = AIRBORNE_PUNCH_DURATION

	# Airborne Kick logic (AK)
	if (Input.is_action_just_pressed("light_kick") or Input.is_action_just_pressed("heavy_kick")) and not is_on_floor() and combat_state_checker:
		if not airborne_kicking:  # Only start if not already airborne kicking
			_set_animation("jump_kick", true)
			airborne_kicking = true
			airborne_kick_timer = AIRBORNE_KICK_DURATION

	# Prevent sideways movement during a jump, and any movement during combat
	if not jump_committed and (not is_on_floor() or (is_on_floor() and not hadouken_playing and not tatsumaki_playing and not shoryuken_playing and not light_punching and not heavy_punching and not light_kicking and not heavy_kicking and not crouch_punching and not crouch_kicking and not airborne_punching and not airborne_kicking)):
		# Movement logic
		if not shoryuken_playing:
			if Input.is_action_pressed("move_right"):
				if sprinting or _is_double_tap_sprint():
					sprinting = true
					velocity.x = SPRINT_SPEED
					_set_animation("run", true)
					crouching = false
				else:
					velocity.x = SPEED
					_set_animation("walk", true)
					crouching = false
			elif Input.is_action_pressed("move_left"):
				if sprinting or _is_double_tap_sprint():
					sprinting = true
					velocity.x = -SPRINT_SPEED
					_set_animation("run", true)
					crouching = false
				else:
					velocity.x = -SPEED
					_set_animation("walk", false)
					sprinting = false
					crouching = false
			elif Input.is_action_pressed("move_down") and is_on_floor():
				crouching = true
				velocity = Vector2.ZERO
				_set_animation("crouch", true)
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				# Check if we should set to idle
				if is_on_floor() and not light_punching and not is_throwing_hadouken:
					_set_animation("idle", true)
				sprinting = false
				crouching = false

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
		#print(current_animation)

# Sprint checker
func _is_double_tap_sprint() -> bool:
	if Input.is_action_just_pressed(sprint_string_input):
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
		1:
			if Input.is_action_just_pressed(hadouken_string_input):
				hadouken_step = 2
		2:
			if Input.is_action_pressed(hadouken_string_input) and not Input.is_action_pressed("move_down"):
				hadouken_step = 3  # Hadouken sequence complete!

# Tatsumaki input sequence checker
func _check_tatsumaki_sequence():
	match tatsumaki_step:
		0:
			if Input.is_action_just_pressed("move_down"):
				tatsumaki_step = 1
				tatsumaki_input_timer = TATSUMAKI_INPUT_TIME
		1:
			if Input.is_action_just_pressed(tatsumaki_string_input):
				tatsumaki_step = 2
		2:
			if Input.is_action_pressed(tatsumaki_string_input) and not Input.is_action_pressed("move_down"):
				tatsumaki_step = 3  # Tatsumaki sequence complete!

# Shoryuken input sequence checker
func _check_shoryuken_sequence():
	match shoryuken_step:
		0:
			if Input.is_action_just_pressed(shoryuken_string_input):
				shoryuken_step = 1
				shoryuken_input_timer = SHORYUKEN_INPUT_TIME
		1:
			if Input.is_action_just_pressed("move_down"):
				shoryuken_step = 2
		2:
			if Input.is_action_just_pressed(shoryuken_string_input):
				shoryuken_step = 3  # Shoryuken sequence complete!

# Trigger Hadouken animation
func _trigger_hadouken():
	# Animation logic
	light_punching = false
	heavy_punching = false
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

# Trigger Tatsumaki animation
func _trigger_tatsumaki():
	light_punching = false
	heavy_punching = false
	tatsumaki_playing = true
	tatsumaki_duration_timer = TATSUMAKI_DURATION
	_set_animation("tatsumaki", true)
	await get_tree().create_timer(0.1).timeout
	velocity.x = TATSUMAKI_SPEED * side_multiplier
		
# Trigger Shoryuken animation
func _trigger_shoryuken():
	light_kicking = false
	heavy_kicking = false
	shoryuken_playing = true
	shoryuken_duration_timer = SHORYUKEN_DURATION
	velocity.y = SHORYUKEN_JUMP_VELOCITY
	velocity.x = SHORYUKEN_FORWARD_VELOCITY * side_multiplier
	_set_animation("shoryuken", true)
	shoryuken_step = 0

func _die():
	queue_free()
	
func _block_damage(base_damage: int):
	print("is blocking")
	if hurt_timer <= 0:
		animator.play("block_hit")
		self.current_health -= base_damage/10
		print(self.current_health)
		hurt_timer = 0.6

		# Apply knockback
		var knockback_direction = Vector2(1, 0) if is_combo_flipped else Vector2(-1, 0)
		velocity.x = knockback_direction.x * LIGHT_KNOCKBACK_FORCE
	
	
func _light_damage_player(base_damage: int):
	if hurt_timer <= 0:
		animator.play("light_hurt")
		self.current_health -= base_damage
		print(self.current_health)
		hurt_timer = 0.6

		# Apply knockback
		var knockback_direction = Vector2(1, 0) if is_combo_flipped else Vector2(-1, 0)
		velocity.x = knockback_direction.x * LIGHT_KNOCKBACK_FORCE

func _heavy_damage_player(base_damage: int):
	if hurt_timer <= 0:
		animator.play("heavy_hurt")
		self.current_health -= base_damage
		print(self.current_health)
		hurt_timer = 0.6

		# Apply knockback
		var knockback_direction = Vector2(1, 0) if is_combo_flipped else Vector2(-1, 0)
		velocity.x = knockback_direction.x * HEAVY_KNOCKBACK_FORCE

func _on_hurt_box_area_entered(hitbox):
	var random_bool = randf() < 0.5
	if random_bool:
		# block
		if Input.is_action_pressed(tatsumaki_string_input):
			_block_damage(10)
		else:
			_light_damage_player(10)
	else:
		# block
		if Input.is_action_pressed(tatsumaki_string_input):
			_block_damage(20)
		else:
			_heavy_damage_player(20)

