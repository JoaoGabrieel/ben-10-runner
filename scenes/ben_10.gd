extends CharacterBody2D
class_name Ben10

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var run_col: CollisionShape2D = $RunCol
@onready var duck_col: CollisionShape2D = $DuckCol
@onready var timer: Timer = $Timer
@onready var cursor_default =preload("res://assets/img/omnitrix_cursor_default.png")
@onready var omnitrix_hud : CanvasLayer = get_tree().get_root().get_node("main/Omnitrix_hud")


 

#@onready var warning_timer: Timer = $WarningTimert

@export var bullet_scene: PackedScene = preload("res://scenes/fogo.tscn")

@export var heroes: Array[String] 


var hero_active: String = "ben" 
  
signal transformed(hero) 
signal request_transform
signal transformation_finished

const GRAVITY: int = 4200
const JUMP_SPEED: int = -1800

const JUMP_SPEED_CHAMA = -800
const MOVE_SPEED= 300
var gravity_low: int = 800
var is_jumping: bool = false
var warning_timer: Timer
var can_transform: bool = true
var is_xlr8_active: bool = false
#var transformation_available: bool = false
var screen_width: int

  

var omnitrix_sound = AudioStreamPlayer

func _ready() -> void:
	screen_width = get_viewport_rect().size.x

	randomize()
	set_process_unhandled_input(true)
	
	Input.set_custom_mouse_cursor(cursor_default,Input.CURSOR_ARROW, Vector2(16,16))
	
	warning_timer = Timer.new()
	warning_timer.wait_time = 6.0
	warning_timer.stop() 
	
	




	
	timer.one_shot = true
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

	
	warning_timer = Timer.new()
	warning_timer.name = "WarningTimer"
	add_child(warning_timer)
	
	warning_timer.one_shot= true
	warning_timer.timeout.connect(Callable(self, "_on_warning_timer_timeout"))
	

	
	
	omnitrix_sound= AudioStreamPlayer.new()
	omnitrix_sound.stream =load("res://assets/sound/prototype omnitrix time out sound effect.mp3")
	add_child(omnitrix_sound)
	
	var main = get_parent()
	#if main.has_signal("WasHeroTime"):
		#main.WasHeroTime.connect(_on_main_was_hero_time)
	
	

func _physics_process(delta: float) -> void:
	var current_gravity = GRAVITY
	
	if hero_active == "chama" and not is_on_floor():
		if Input.is_action_pressed("ui_accept"):
			current_gravity = gravity_low

	velocity.y += current_gravity * delta
	
	var direction_x=0
	if Input.is_action_pressed("right"):
		direction_x+=1
	if Input.is_action_pressed("left"):
		direction_x-=3 
		
	velocity.x=direction_x *MOVE_SPEED
	

	if is_on_floor():
		if not get_parent().game_running:
			play_hero_animation("idle")
		else:
			run_col.disabled = false
			duck_col.disabled = true
			
			if Input.is_action_just_pressed("ui_accept"):
				velocity.y = JUMP_SPEED_CHAMA if hero_active == "chama" else JUMP_SPEED
				play_hero_animation("jump")




			#if Input.is_action_pressed("ui_accept"):
				#velocity.y = JUMP_SPEED     
				### $JumpSound.play()    x                                                                                                                                                                                                                                                                                                                                                               
				play_hero_animation("junp")
			
			elif hero_active == "ben" and Input.is_action_pressed("ui_duck"):  
				play_hero_animation("duck")
				run_col.disabled = true
				duck_col.disabled = false
			else:
				play_hero_animation("run")
	else:
		play_hero_animation("jump")
		
	#if velocity.y < MAX_JUMP_VELOCITY:
		#velocity.y = MAX_JUMP_VELOCITY
	

  
	move_and_slide()
	
	var camera_x = get_parent().camera_2d.global_position.x
	var screen_half_width = screen_width / 2
	
	var left_bound = camera_x - screen_half_width
	var right_bound = camera_x + screen_half_width
	
	var player_half_width = $RunCol.shape.size.x / 2
	var new_x = clamp(global_position.x, left_bound + player_half_width, right_bound - player_half_width)
	global_position = Vector2(new_x, global_position.y)

	
   
	
	
func normal_gravity():
	print("amigo estou aqui")
	
func _input(event):
	if event.is_action_released("shoot"):
		if get_parent().game_running:
			if hero_active == "ben":
				print("Ben: Clique detectado. Pedindo permissão")
				request_transform.emit()

			elif hero_active == "chama":
				print("disparando")
				shoot()   


		
	#if event.is_action_pressed("ui_accept") and transformation_available:
		#transform_player()
		
func transform_player() -> void:
	can_transform = false
	print("transform player chamando")

	if heroes.is_empty():
		push_error("ERRO: A lista 'heroes' está vazia no Inspetor!")
		return
		
	var hero_name: String = heroes[randi() % heroes.size()]
	print("Herói Sorteado: " + hero_name)
	
	var transformou_com_sucesso = false
		
	match hero_name:
			"Chama":
				#transform_to_chama()
				print("Chama ainda não implementado, transformando em XLR8 por segurança.")
				transform_to_xlr8()
				transformou_com_sucesso = true
				
				
			"Xlr8":
				transform_to_xlr8()
				transformou_com_sucesso = true
				
			"Quatro Braços":
				#transform_to_quatro_braços()
				transform_to_xlr8()  
				
	if transformou_com_sucesso:
		if timer.is_stopped():
			timer.start()
			warning_timer.start()
		else:
			print("ERRO: Herói sorteado não tem função de transformação configurada.")
		
				
			





	   
	


		
		
	 #
		
	
func shoot():
	#print("Chamando shoot")
	var bullet = bullet_scene.instantiate()
	#print("Bala criada")

	bullet.position = position
	
	var global_mouse_pos = get_global_mouse_position()
	var direction = (global_mouse_pos - global_position).normalized()
	
	bullet.set_direction(direction)
	
	
	if bullet.has_method("set_bullet_speed"):
		bullet.set_bullet_speed(get_parent().speed +bullet.bullet_speed)



	get_parent().add_child(bullet)
	


func _on_warning_timer_timeout():
	if hero_active != "ben":
		omnitrix_sound.play()

	
	
	

# Função auxiliar para tocar animações com base no herói atual
func play_hero_animation(base_name: String) -> void:
	var anim_name := ""
	if hero_active == "ben":
		anim_name = base_name
	else:
		anim_name = hero_active + "_" + base_name

	if animated_sprite_2d.sprite_frames.has_animation(anim_name):
		animated_sprite_2d.play(anim_name)
	else:
		push_warning("Animação não encontrada: " + anim_name)

# Transformação para herói específico
func transform_to_chama() -> void:
	hero_active = "chama"
	emit_signal("transformed", "Chama")
	
	#if timer.is_stopped():
		#can_transform = false
		#timer.start()
		#warning_timer.wait_time = timer.wait_time - 6.0
		#warning_timer.start()
	#
	
	
func transform_to_xlr8() ->void:
	hero_active = "xlr8"
	is_xlr8_active = true
	emit_signal("transformed","Xlr8")
	print("virando xlr8")
	
	get_tree().paused = true
	#await get_tree().create_timer(0.3).timeout
	get_tree().paused = false
	
	#
	#if timer.is_stopped():  
		#can_transform = false
		#timer.start()
		#warning_timer.wait_time = timer.wait_time - 6.0
		#warning_timer.start()
	#
	  
	
func transform_to_quatro_braços() ->void:
	hero_active = "four arms"
	emit_signal("transformed","Quatro Braços")
	
	
	#if timer.is_stopped():
		#can_transform = false
		#timer.start()
		#warning_timer.wait_time = timer.wait_time - 6.0
		#warning_timer.start()
	
	
	
func recharge_omnitrix():
	print("omnitrix recarregado")
	can_transform = true
	

# Escolhe herói aleatório e transforma
#func _on_main_was_hero_time() -> void:
	#if not can_transform:
		#print("omnitrix recarregando")
		#return
	#
	#print("Sinal 'WasHeroTime' recebido! Variável 'transformation_available' será ativada.")	
	#transformation_available = true

		
	#if heroes.is_empty():
		#push_warning("Nenhum herói definido no array 'heroes")
		#return  w  
	#
	#print("Hora do heroi")
	#var hero: String = heroes[randi() % heroes.size()]
	##hero_active = hero
#
	#match hero:
		#"Chama":
			#transform_to_xlr8()   
	#
		#"Xlr8":
			## pode adicionar outros heróis aqui
			#transform_to_xlr8()
		#"Quatro Braços":
				#transform_to_xlr8()
	#
		
			
			
func _on_timer_timeout() -> void:
	
	print("Tempo de transformação acabou!")
	warning_timer.stop()
	#
	hero_active = "ben"
	is_xlr8_active = false
	play_hero_animation("run")
	emit_signal("transformed", "ben")
	omnitrix_hud.show_locked()
	var main := get_parent() as Main
	emit_signal("transformation_finished")
	main.omnitrix_state = Main.OmnitrixState.LOCKED
	
	
	print("⏱ TIMER ACABOU APÓS ", timer.wait_time, " SEGUNDOS")

func reset_trasformation():
	hero_active = "ben" 
	timer.stop()
	warning_timer.stop()
	omnitrix_sound.stop()
	play_hero_animation("idle")
	can_transform = true
