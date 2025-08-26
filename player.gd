extends CharacterBody2D

@export var speed := 130
var last_horizontal = 0
var last_vertical = 0

func _physics_process(delta):
	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	var up = Input.is_action_pressed("ui_up")
	var down = Input.is_action_pressed("ui_down")

	var horizontal = 0
	var vertical = 0

	if left and right:
		horizontal = last_horizontal
	elif left:
		horizontal = -1
	elif right:
		horizontal = 1

	if up and down:
		vertical = last_vertical
	elif up:
		vertical = -1
	elif down:
		vertical = 1

	# remember last pressed direction
	if horizontal != 0:
		last_horizontal = horizontal
		$Sprite.flip_h = horizontal == -1
	if vertical != 0:
		last_vertical = vertical

	velocity = Vector2(horizontal, vertical)
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * speed

	# move character
	move_and_slide()

	# play animation based on **actual movement**
	if velocity.length() > 0:
		$Anims.play("walk")
	else:
		$Anims.play("RESET")
