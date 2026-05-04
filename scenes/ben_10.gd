extends CharacterBody2D
class_name Ben10

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var run_col: CollisionShape2D = $RunCol
@onready var duck_col: CollisionShape2D = $DuckCol
@onready var timer: Timer = $Timer

# Cursores originais via Hardware (Simples e estável)
@onready var cursor_default = preload("res://assets/img/omnitrix_cursor_default.png")

@onready var omnitrix_hud : CanvasLayer = get_tree().get_root().get_node("main/Omnitrix_hud")

@export var bullet_scene: PackedScene = preload("res://scenes/fogo.tscn")
@export var heroes: Array[String] 

var hero_active: String = "ben"  
var warning_timer: Timer
var can_transform: bool = true
var screen_width: int
var omnitrix_sound: AudioStreamPlayer

signal transformed(hero) 
signal request_transform
signal transformation_finished

const GRAVITY: int = 4200
const JUMP_SPEED: int = -1800
const JUMP_SPEED_CHAMA = -800
const MOVE_SPEED = 300
var gravity_low: int = 800
var slow_mo_limit: float = 3.2
var slow_mo_used_time: float = 0.0
var slow_mo_blocked: bool = false

func _ready() -> void:
	screen_width = get_viewport_rect().size.x
	randomize()
	
	# Implementação original do cursor que você fez
	Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, Vector2(16,16))
	
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	
	warning_timer = Timer.new()
	add_child(warning_timer)
	warning_timer.one_shot = true
	warning_timer.timeout.connect(_on_warning_timer_timeout)
	
	omnitrix_sound = AudioStreamPlayer.new()
	omnitrix_sound.stream = load("res://assets/sound/prototype omnitrix time out sound effect.mp3")
	add_child(omnitrix_sound)

func _physics_process(delta: float) -> void:
	var current_gravity = GRAVITY
	
	if hero_active == "chama" and not is_on_floor():
		if Input.is_action_pressed("ui_accept"):
			current_gravity = gravity_low

	velocity.y += current_gravity * delta
	
	var direction_x = 0
	if Input.is_action_pressed("right"): direction_x += 1
	if Input.is_action_pressed("left"): direction_x -= 2.5 
	velocity.x = direction_x * MOVE_SPEED

	if is_on_floor():
		if not get_parent().game_running:
			play_hero_animation("idle")
		else:
			run_col.disabled = false
			duck_col.disabled = true
			
			if Input.is_action_just_pressed("ui_accept"):
				velocity.y = JUMP_SPEED_CHAMA if hero_active == "chama" else JUMP_SPEED
				play_hero_animation("jump")
			elif hero_active == "ben" and Input.is_action_pressed("ui_duck"):  
				play_hero_animation("duck")
				run_col.disabled = true
				duck_col.disabled = false
			else:
				play_hero_animation("run")
	else:
		play_hero_animation("jump")
	
	move_and_slide()
	
	# Limitar player na câmera
	var camera_x = get_parent().camera_2d.global_position.x
	var screen_half = screen_width / 2
	global_position.x = clamp(global_position.x, camera_x - screen_half + 25, camera_x + screen_half - 25)

func _process(_delta: float) -> void:
	var main = get_parent()
	if not main.game_running: return

	# Lógica original de mudança de cor do ambiente (Slow-mo)
	if hero_active == "xlr8":
		# Se estiver apertando E não estiver bloqueado
		if Input.is_action_pressed("shoot") and not slow_mo_blocked:
			main.is_slow_mo = true
			slow_mo_used_time += _delta
			
			# Se estourar o limite, bloqueia
			if slow_mo_used_time >= slow_mo_limit:
				slow_mo_blocked = true
				main.is_slow_mo = false
				print("Tempo de XLR8 esgotado")
		else:
			# Se soltar o botão OU estiver bloqueado, desliga o slow-mo
			main.is_slow_mo = false
	else:
		# Se não for XLR8, garante que o slow-mo está desligado
		main.is_slow_mo = false
func _input(event):
	if event.is_action_released("shoot") and get_parent().game_running:
		if hero_active == "ben":
			request_transform.emit()
		elif hero_active == "chama":
			shoot()

func transform_player():
	if heroes.is_empty(): return
	var hero_name = heroes[randi() % heroes.size()]
	
	match hero_name:
		"Chama", "Quatro Braços", "Xlr8":
			transform_to_xlr8() 
	
	timer.start()
	warning_timer.start()

func transform_to_xlr8():
	hero_active = "xlr8"
	slow_mo_used_time = 0.0
	slow_mo_blocked = false
	emit_signal("transformed", "Xlr8")

func _on_timer_timeout():
	hero_active = "ben"
	if omnitrix_sound and omnitrix_sound.playing:
		omnitrix_sound.stop() 
	play_hero_animation("run")
	emit_signal("transformed", "ben")
	get_parent().is_slow_mo = false
	emit_signal("transformation_finished")

func play_hero_animation(base_name: String):
	var anim = base_name if hero_active == "ben" else hero_active + "_" + base_name
	if animated_sprite_2d.sprite_frames.has_animation(anim):
		animated_sprite_2d.play(anim)

func shoot():
	var bullet = bullet_scene.instantiate()
	bullet.position = position
	bullet.set_direction((get_global_mouse_position() - global_position).normalized())
	get_parent().add_child(bullet)

func reset_trasformation():
	hero_active = "ben"
	timer.stop()
	if warning_timer:
		warning_timer.stop()
		
	if omnitrix_sound and omnitrix_sound.playing:
		omnitrix_sound.stop()
		
	play_hero_animation("idle")
	slow_mo_used_time = 0.0
	slow_mo_blocked = false

func _on_warning_timer_timeout():
	if hero_active != "ben": omnitrix_sound.play()
