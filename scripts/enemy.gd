extends CharacterBody2D

const SPEED = 300.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	
	animator.play("idle")
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
