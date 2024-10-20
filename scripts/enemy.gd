extends CharacterBody2D

const SPEED = 100.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_facing_right = true
var is_scale_x_flipped = false
var player_marker = null
var direction_to_player = null

const enemy_choices = [-1, 0 , 1]

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var left_raycast: RayCast2D = $RayCastLeft
@onready var right_raycast: RayCast2D = $RayCastRight

func _ready():
	velocity = Vector2.ZERO

func _physics_process(delta):
	
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

	if left_raycast.is_colliding() and left_raycast.get_collider().is_in_group("player"):
		player_marker = left_raycast.get_collider().get_node("Marker2D")
		is_facing_right = false
	if right_raycast.is_colliding() and right_raycast.get_collider().is_in_group("player"):
		player_marker = right_raycast.get_collider().get_node("Marker2D")
		is_facing_right = true
	
	if player_marker != null and abs((player_marker.global_position - global_position).x) < 50:
		animator.play("attack")
	elif velocity.x != 0:
		animator.play("walk")
	else:
		animator.play("idle")
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
