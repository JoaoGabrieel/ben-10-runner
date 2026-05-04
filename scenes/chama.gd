extends CharacterBody2D

const GRAVITY: int = 4200
const JUNP_SPEED: int= -1800

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		else:
			if Input.is_action_pressed("ui_accept"):
				velocity.y=JUNP_SPEED
				$AnimatedSprite2D.play("junp")
			else:
				$AnimatedSprite2D.play("running")  # ou outra animação

			
		
				

	move_and_slide()

		
			
