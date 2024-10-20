extends CharacterBody2D

const SPEED = 100.0
const FIREBALL_SPEED = 400.0
const MAX_HEALTH = 100
const KNOCKBACK_FORCE = 300.0  # Adjust this value to control knockback strength

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_facing_right = true
var is_scale_x_flipped = false
var player = null
var player_marker = null
var direction_to_player = null
var current_health = MAX_HEALTH
var hurt_timer = 0.0  # Timer to prevent animation override after taking damage
var is_attacking = false
var is_combo_flipped = false
var third_last_face_value = true
var second_last_face_value = true
var first_last_face_value = true
var knockback_direction = Vector2(1, 0)

const enemy_choices = [-1, 0, 1]

@export var light_punch_damage = 5
@export var heavy_punch_damage = 10
@export var light_kick_damage = 5
@export var heavy_kick_damage = 10
@export var crouch_punch_damage = 3
@export var crouch_kick_damage = 3
@export var airborne_punch_damage = 3
@export var airborne_kick_damage = 3
@export var tatsumaki_damage = 15
@export var shoryuken_damage = 15

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var left_raycast: RayCast2D = $RayCastLeft
@onready var right_raycast: RayCast2D = $RayCastRight
@onready var hit_box: CollisionShape2D = $HitBox/CollisionShape2D
@onready var fireball_spawn: Marker2D = $FireballSpawn
@onready var fireball_scene = preload("res://scenes/fireball.tscn")

func _ready():
	velocity = Vector2.ZERO

func _physics_process(delta):
	
	print(is_facing_right)
	# false, false, true combo that leads to switch
	if(!third_last_face_value && !second_last_face_value && first_last_face_value):
		if is_combo_flipped:
			is_combo_flipped = false
		else:
			is_combo_flipped = true
		if is_combo_flipped:
			knockback_direction = Vector2(1, 0)
		else:
			knockback_direction = Vector2(-1, 0)
	
	hit_box.disabled = !is_attacking
	
	if current_health <= 0:
		_die()
	
	# Reduce the hurt timer
	if hurt_timer > 0:
		hurt_timer -= delta
	
	if hurt_timer <= 0:
		# Normal movement and animation behavior if not "hurt"
		if player_marker != null:
			direction_to_player = (player_marker.global_position - global_position).normalized()
			velocity.x = direction_to_player.x * SPEED
		
		# Correct flipping logic
		if is_facing_right:
			if is_scale_x_flipped:
				self.scale.x = self.scale.x
				is_scale_x_flipped = false
		else:
			if !is_scale_x_flipped:
				self.scale.x = -self.scale.x
				is_scale_x_flipped = true

		# Raycast detection
		if left_raycast.is_colliding() and left_raycast.get_collider().is_in_group("player"):
			player = left_raycast.get_collider()
			player_marker = left_raycast.get_collider().get_node("Marker2D")
			is_facing_right = false
			third_last_face_value = second_last_face_value
			second_last_face_value = first_last_face_value
			first_last_face_value = false
		if right_raycast.is_colliding() and right_raycast.get_collider().is_in_group("player"):
			player = right_raycast.get_collider()
			player_marker = right_raycast.get_collider().get_node("Marker2D")
			is_facing_right = true
			third_last_face_value = second_last_face_value
			second_last_face_value = first_last_face_value
			first_last_face_value = true
		
		# Player close enough to attack
		if player_marker != null and abs((player_marker.global_position - global_position).x) < 50:
			is_attacking = true
			animator.play("attack")
			await get_tree().create_timer(5).timeout
			is_attacking = false
			
		elif velocity.x != 0:
			animator.play("walk")
		else:
			animator.play("idle")
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func _die():
	animator.play("dead")
	await get_tree().create_timer(0.5).timeout
	queue_free()

# Modify the _receive_damage function to set the hurt timer and apply knockback
func _receive_damage(base_damage: int):
	if hurt_timer <= 0:  # Only apply damage if not already hurt
		animator.play("hurt")
		self.current_health -= base_damage
		hurt_timer = 0.5  # Prevent animation override for 0.5 seconds

		velocity.x = knockback_direction.x * KNOCKBACK_FORCE

func _on_hurt_box_area_entered(hitbox):
	if hitbox is Area2D:
		match hitbox.name:
			"HitBoxFireball":
				_receive_damage(5)
				hitbox.get_parent().queue_free()
			"LightPunchHitBox":
				_receive_damage(light_punch_damage)
			"HeavyPunchHitBox":
				_receive_damage(heavy_punch_damage)
			"LightKickHitBox":
				_receive_damage(light_kick_damage)
			"HeavyKickHitBox":
				_receive_damage(heavy_kick_damage)
			"CrouchPunchHitBox":
				_receive_damage(crouch_punch_damage)
			"CrouchKickHitBox":
				_receive_damage(crouch_kick_damage)
			"AirbornePunchHitBox":
				_receive_damage(airborne_punch_damage)
			"AirborneKickHitBox":
				_receive_damage(airborne_kick_damage)
			"TatsumakiHitBox":
				_receive_damage(tatsumaki_damage)
			"ShoryukenHitBox":
				_receive_damage(shoryuken_damage)
			_:
				_receive_damage(5)
