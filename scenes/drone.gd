extends StaticBody2D
class_name Drone

const DRONE_SPEED = 7.0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position.x -= DRONE_SPEED 
