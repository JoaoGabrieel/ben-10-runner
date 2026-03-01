extends Node
class_name Main

enum OmnitrixState{
	LOCKED,
	READY,
	ACTIVE
}

var omnitrix_state: OmnitrixState = OmnitrixState.LOCKED

var stump_scene= preload("res://scenes/stump.tscn")
var drone_scene= preload("res://scenes/drone.tscn")
var obstacle_type := [stump_scene]
var osbtacle : Array
var drone_heights:= [200,300]
@onready var current_player: CharacterBody2D = $Ben10
@onready var camera_2d: Camera2D = $Camera2D
@onready var ground: StaticBody2D = $Ground2
@onready var game_over_hud: CanvasLayer = $GameOver
@onready var omnitrix_hud := $Omnitrix_hud




var is_chama_active: bool = false
var chama_timer= Timer
var score_at_last_recharge: float = 0.0




const BEN_START_POS := Vector2i(150,485)
const CAM_START_POS := Vector2i(576,324)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int = 0
const SCORE_MODIFIER : int = 10  
var high_score: int
var speed : float = 10.0
const  START_SPEED : float = 10.0
const MAX_SPEED : int = 25
const SPEED_MODIFIER: int = 5000
const XLR8_DIST_MULTIPLIER = 6.0
const BEN_SCRIPT = preload("res://scenes/ben_10.gd")
const BASE_GAP = 800
const GAP_RANDOM = 500
var next_spawn_dist = 0.0

var screem_size : Vector2i
var ground_height : int
var game_running : bool = false


var score_multiplier : int = 1
var last_transform_score: int = 0
var ground_segments: Array[StaticBody2D] = [] 

var is_xlr8_mode: bool = false
var xlr8_speed_boost: float = 40.0
var transform_requested: bool = false


@onready var pause_main = $Pause
var is_paused = false



func _input(event):
	if event.is_action_pressed("ui_pause"):
		is_paused = not is_paused
		get_tree().paused = is_paused
		pause_main.visible = is_paused
		
		
func _on_resume_pressed():
	print("olha aqui")
	get_tree().paused = false
	is_paused = false
	pause_main.visible = false  
	

		


# Called when the node enters the scene tree for the fir  st time.
func _ready() -> void:	
	set_process_unhandled_input(true)  
	ground_height = ground   .get_node("Sprite2D").texture.get_height()
	screem_size = get_window().size
	game_over_hud.get_node("Button").pressed.connect(new_game)
	$Pause.get_node("Resume").pressed.connect(_on_resume_pressed)



	if current_player is Ben10:
		var ben = current_player as Ben10
		if not ben.transformed.is_connected(_on_player_transformed):
			ben.transformed.connect(_on_player_transformed)
		if not ben.request_transform.is_connected(_on_ben_requested_transform):
			ben.request_transform.connect(_on_ben_requested_transform)
		if not ben.transformation_finished.is_connected(_on_transformation_finished):
			ben.transformation_finished.connect(_on_transformation_finished)

	new_game()
	
func _on_transformation_finished():
	print("Main: Transformação acabou. Entrando em Cooldown.")
	
	omnitrix_state = OmnitrixState.LOCKED
	omnitrix_hud.show_locked()
	
	score_at_last_recharge = score
	
	#await get_tree().create_timer(1.5).timeout
	#omnitrix_state = OmnitrixState.READY
	#omnitrix_hud.show_ready()


	

	
func _on_ben_requested_transform():
	print("main recebeu o pedido de transformaçao")
	
	if omnitrix_state == OmnitrixState.READY:
		execute_transformation()
	elif omnitrix_state == OmnitrixState.LOCKED:
		print("Main: Negado. Relógio ainda está carregando.")
	elif omnitrix_state == OmnitrixState.ACTIVE:
		print("Main: Negado. Já está transformado.")

		
func execute_transformation():
	print("Main: Autorizando transformação!")
	omnitrix_state = OmnitrixState.ACTIVE
	
	omnitrix_hud.start_discharge()
	
	score_multiplier += 1
	
	var ben := current_player as Ben10
	ben.transform_player()
	
		
	
	



	
#func _on_was_hero_time():
	#omnitrix_hud.show_ready()	
	



	
func _on_player_transformed(hero: String ):
	if hero == "Xlr8":
		is_xlr8_mode = true
		next_spawn_dist = camera_2d.position.x + 1200 #
		for obs in osbtacle:
			remove_obs(obs)
	elif hero  == "ben":
		is_xlr8_mode = false
		omnitrix_hud.show_locked()
		var ben := current_player as Ben10
		if hero == "ben":
				omnitrix_hud.show_locked()

			

	
	  
func new_game():
	current_player.position = BEN_START_POS
	camera_2d.position = CAM_START_POS
	current_player.velocity = Vector2.ZERO
	
	next_spawn_dist = camera_2d.position.x + 700
	
	
	transform_requested = false
	omnitrix_hud.show_locked()
	score =0
	score_multiplier = 1
	score_at_last_recharge = 0.0 
	is_chama_active = false    
	show_score()
	game_running = false 
	get_tree().paused= false
	difficulty = 0
	var ben := current_player as Ben10
	omnitrix_state = OmnitrixState.LOCKED
	omnitrix_hud.show_locked()
	
	ben.reset_trasformation()

	 
	
	#delete all obstacles
	for obs in osbtacle:
		obs.queue_free()
	osbtacle.clear()
	
	
	current_player.position = BEN_START_POS
	current_player.velocity = Vector2i(0,0)
	camera_2d.position = CAM_START_POS
	
	for g in ground_segments:
		g.queue_free()
	ground_segments.clear()

	
	var first_ground = ground.duplicate()
	first_ground.position = Vector2i(0,ground.position.y)
	add_child(first_ground)
	ground_segments.append(first_ground)

	#reset screen gameover and hud
	$HUD.get_node("StartLabel").show()
	game_over_hud.hide()
	
	is_xlr8_mode = false
	speed = START_SPEED


		  
		
	omnitrix_hud.show_locked()


	

func _process(_delta):
	if game_running: 
		if is_xlr8_mode:
			speed = lerp(speed,xlr8_speed_boost,0.5 * _delta)
		else:
			speed = START_SPEED + score / SPEED_MODIFIER
			if speed > MAX_SPEED: 
				speed = MAX_SPEED
				
		

		adjust_difficulty()
		generate_obs() 

		current_player.position.x += speed
		camera_2d.position.x += speed
		score += speed
		show_score()
		
		

		#arrumar o ground criar um novo ao inves de mover d
		if camera_2d.position.x - ground_segments[-1].position.x > screem_size.x / 2:
			var new_ground = ground.duplicate()  
			new_ground.position = ground_segments[-1].position + Vector2(screem_size.x,0)
			add_child(new_ground)
			ground_segments.append(new_ground)
			
			
		if ground_segments[0].position.x < (camera_2d.position.x - screem_size.x * 1.5):
			var old_ground = ground_segments.pop_front()
			old_ground.queue_free() 

		for obs in osbtacle:
			if obs.position.x < (camera_2d.position.x - screem_size.x):
				remove_obs(obs)


	if game_running and omnitrix_state == OmnitrixState.LOCKED:
		var progress = (score - score_at_last_recharge) / SCORE_MODIFIER
		var goal = 500 * score_multiplier
		
		if progress >= goal:
			print("Meta Batida! Omnitrix pronto.")
			omnitrix_state = OmnitrixState.READY
			omnitrix_hud.show_ready()
			
		if omnitrix_state == OmnitrixState.LOCKED and game_running:
			print("Progresso: ", int(progress), " / Meta: ", goal)
			
		
			
			
	
	else:
		if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Jogo Iniciado!")
			game_running = true
			$HUD.get_node("StartLabel").hide()
			
	
			
		
	
	



		
func generate_obs():
	if camera_2d.position.x + screem_size.x > next_spawn_dist:
		var obs
		var chance = randf()
		
		var drone_chance_cutoff = 0.85 if is_xlr8_mode else 0.7
		if difficulty >= 1 and chance > 0.7:
			obs = drone_scene.instantiate()
			var drone_y = drone_heights[randi() % drone_heights.size()]
			obs.position = Vector2(camera_2d.position.x + screem_size.x + 100, drone_y)
			add_child(obs) # Adiciona o drone à cena
			osbtacle.append(obs)
		else:
			obs = stump_scene.instantiate()
			obs.position = Vector2(camera_2d.position.x + screem_size.x + 100, BEN_START_POS.y - 10) 
			add_child(obs)
			osbtacle.append(obs)
			
			var group_chance = 0.5 if is_xlr8_mode else 0.3
			if randf() < group_chance:
				var obs2 = stump_scene.instantiate()
				obs2.position = Vector2(obs.position.x + 60, obs.position.y)
				add_child(obs2)
				osbtacle.append(obs2)
				obs = obs2 # O gap agora conta a partir do segundo toco
				
			
			
		var mult_velocidade = 5 if is_xlr8_mode else 15
		var current_gap = BASE_GAP + (speed * mult_velocidade)
		
		var variacao_aleatoria = randf() * (GAP_RANDOM * (0.5 if is_xlr8_mode else 1.0))
		next_spawn_dist = obs.position.x + current_gap + variacao_aleatoria


		if is_xlr8_mode:
			current_gap *= 2.5
			
		next_spawn_dist = obs.position.x + current_gap + randf() * GAP_RANDOM
			
			

	
func add_obs(obs: StaticBody2D, x: int, y: int):
	obs.position = Vector2i(x,y)  
	add_child(obs)
	osbtacle.append(obs)
	
	
	
func remove_obs(obs):
	obs.queue_free()
	osbtacle.erase(obs)
	

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE : " + str(int(score / SCORE_MODIFIER)
)

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("Label").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	game_over_hud.show()


func _on_pause_property_list_changed() -> void:
	pass # Replace with function body.
