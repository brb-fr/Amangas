extends CharacterBody2D

@export var speed = 100
func _physics_process(delta: float) -> void:
	var inp = Input.get_vector("ui_left","ui_right","ui_up","ui_down") * speed
	velocity = inp
	move_and_slide()
	$Sprite.flip_h = inp.x < 0
