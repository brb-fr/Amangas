extends CharacterBody2D

@export var speed := 130
var last_horizontal = 0
var last_vertical = 0
@onready var anim = $Anims
@onready var sprite = $Sprite

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	if is_multiplayer_authority():
		$Camera2D.enabled = true
		$Camera2D.make_current()
func _physics_process(delta):
	if is_multiplayer_authority():
		if OS.get_name() == "Windows":
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
			if horizontal != 0:
				last_horizontal = horizontal
				sprite.flip_h = horizontal == -1
			if vertical != 0:
				last_vertical = vertical
			velocity = Vector2(horizontal, vertical)
			if velocity != Vector2.ZERO:
				velocity = velocity.normalized() * speed
		else:
			var inp = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * speed
			velocity = inp
		move_and_slide()
		if velocity.length() > 0:
			anim.play("walk")
		else:
			anim.play("RESET")

func set_username(u:String):
	$uname.text = u
