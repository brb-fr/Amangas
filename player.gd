extends CharacterBody2D

@export var speed = 100
func _physics_process(delta: float) -> void:
	var inp = Input.get_vector("ui_left","ui_right","ui_up","ui_down") * speed
	velocity = inp
	move_and_slide()
	if inp.x < 0:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false
