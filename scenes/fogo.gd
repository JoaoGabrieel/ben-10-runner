extends Area2D

@export var velocidade: float = 400.0
@export var bullet_speed := 800.0  # aumente se quiser que ele vá mais rápido
var direction := Vector2.RIGHT


func set_direction(dir: Vector2):
	direction = dir.normalized()
	

func set_bullet_speed(new_speed: float) ->void:
	bullet_speed = new_speed	



func _physics_process(delta):
	position += direction * bullet_speed * delta

	
func _on_body_entered(body:Node2D):  
	if body.is_in_group("obstacles"):
		var obstacle: StaticBody2D = body
		
		obstacle.visible = false
		obstacle.set_collision_layer_value(2, false)
		(obstacle.get_node("HitArea") as HitArea).monitoring = false
		queue_free()
