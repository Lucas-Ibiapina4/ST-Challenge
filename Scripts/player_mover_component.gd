extends Node

const SPEED = 300.0
const JUMP_VELOCITY = -600.0
var facing := 1

@onready var player: CharacterBody2D = $".."
@onready var animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = JUMP_VELOCITY
		

	# Get the input direction (0 ; -1 ; 1)
	var direction := Input.get_axis("left_move", "right_move")


	# Flip Sprite
	if direction > 0:
		facing = 1
		animated_sprite.flip_h = false
	elif direction < 0:
		facing = -1
		animated_sprite.flip_h = true


	# Play Animation
	if player.is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	# Apply Direction
	if direction:
		player.velocity.x = direction * SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, SPEED)
		
	player.move_and_slide()
