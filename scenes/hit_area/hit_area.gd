extends Area2D
class_name HitArea

@onready var main_scene: Main = get_tree().get_first_node_in_group("main")

func _on_body_entered(body: Node2D) -> void:
	if body is Ben10:
		main_scene.game_over()
