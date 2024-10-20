extends CharacterBody2D

const SPEED = 100.0
const FIREBALL_SPEED = 400.0
const MAX_HEALTH = 100
const KNOCKBACK_FORCE = 300.0  # Adjust this value to control knockback strength

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_facing_right = true
var is_scale_x_flipped = false
var player_marker = null
var direction_to_player = null
var current_health = MAX_HEALTH
var hurt_timer = 0.0  # Timer to prevent animation override after taking damage

const enemy_choices = [-1, 0, 1]

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var left_raycast: RayCast2D = $RayCastLeft
@onready var right_raycast: RayCast2D = $RayCastRight
@onready var fireball_spawn: Marker2D = $FireballSpawn
@onready var fireball_scene = preload("res://scenes/fireball.tscn")

func _ready():
	velocity = Vector2.ZERO

func _physics_process(delta):
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
			player_marker = left_raycast.get_collider().get_node("Marker2D")
			is_facing_right = false
		if right_raycast.is_colliding() and right_raycast.get_collider().is_in_group("player"):
			player_marker = right_raycast.get_collider().get_node("Marker2D")
			is_facing_right = true
		
		# Player close enough to attack
		if player_marker != null and abs((player_marker.global_position - global_position).x) < 50:
			animator.play("attack")
		elif velocity.x != 0:
			animator.play("walk")
		else:
			animator.play("idle")
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func _die():
	queue_free()

# Modify the _receive_damage function to set the hurt timer and apply knockback
func _receive_damage(base_damage: int):
	if hurt_timer <= 0:  # Only apply damage if not already hurt
		animator.play("hurt")
		self.current_health -= base_damage
		print(self.current_health)
		hurt_timer = 0.5  # Prevent animation override for 0.5 seconds

		# Apply knockback
		var knockback_direction = Vector2(1, 0) if is_facing_right else Vector2(-1, 0)
		velocity.x = knockback_direction.x * KNOCKBACK_FORCE

func _on_hurt_box_area_entered(hitbox):
	print(hitbox.name)
	if hitbox is Area2D:
		_receive_damage(5)
		if hitbox.name == "HitBoxFireball":
			hitbox.get_parent().queue_free()
	else:
		print("not an area2d")
