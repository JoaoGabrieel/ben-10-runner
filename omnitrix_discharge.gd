extends CanvasLayer


@onready var locked_icon: CanvasItem = $Control/locked
@onready var ready_icon: CanvasItem = $Control/Ready
@onready var discharge_anim: CanvasItem = $Control/discharge






# Called when the node enters the scene tree for the first time.
func _ready():
	show_locked()
	
func show_locked():
	hide_all()
	locked_icon.visible = true
	
func show_ready():
	hide_all()
	ready_icon.visible =true
	
	
func start_discharge():
	hide_all()
	discharge_anim.visible = true
	discharge_anim.stop() 
	discharge_anim.frame = 0
	discharge_anim.play("default")
	
func hide_all():
	locked_icon.visible = false
	ready_icon.visible = false
	discharge_anim.visible = false

	
	

	

	
