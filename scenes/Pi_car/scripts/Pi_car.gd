extends Node3D

const MovementType = Enums.MovementType
const State = Enums.State
var Movement = load("res://scripts/classes/Movement.gd")
var MovementArray = load("res://scripts/classes/Movement_Array.gd")

""" EXPLICATION ACCÉLÉRATION
En théorie, l'accélération est sensée être g*h/x où h est la profondeur de la
plaquette et x est le rayon. Cela nous donnerait une accel max de 7.35 m/s^2, 
ce qui est évidemment beaucoup trop. En testant, un facteur de 1/1200 semblait
donné la meilleure valeur d'acceleration.

Il est possible que la boule tombe lors du premier essai d'un parcours, vérifier
que si on relance le test avec "r", la boule tombe toujours.

SI L'ACCÉLÉRATION EST MODIFIÉE, LA VITESSE MAX ET LES VITESSES DE TOURNAGE 
DOIVENT ÊTRE RETESTÉES
""" 
const ACCELERATION = ((9.8*0.0015)/0.002)/1500 # 0.0049 m/s^2
""" EXPLICATION V_MAX
La vitesse maximale fut trouvée en vérifiant si le robot pouvait arrêter avec 
l'incertitude de 30mm selon l'accélération trouvée

SI ON MODIFIE CETTE VALEUR, ON DOIT S'ASSURER DE REFAIRE LE TEST D'ARRÊT
""" 
const V_MAX = 0.18 # m/s
""" EXPLICATION V_TURN ET V_TIGHT_TURN
Ces vitesses ont été trouvées en vérifiant si le robot pouvait faire les 
virages du parcours réel

SI ON MODIFIE CES VALEURS, ON DOIT S'ASSURER DE VÉRIFIER LES RÉSULTATS DANS LE 
PARCOURS RÉEL
""" 
const V_TURN = 0.12
const V_TIGHT_TURN = 0.066
const MAX_DISPLACEMENT = 0.2

var nfsm = 0
var speed = 0
var capteurs_SL = []
var state = State.manual_control
var tick_counter = 0
var movement_array: MovementArray = MovementArray.new()


@onready var indicateur_capt1 = $Indicateur_Capteur1
@onready var indicateur_capt2 = $Indicateur_Capteur2
@onready var indicateur_capt3 = $Indicateur_Capteur3
@onready var indicateur_capt4 = $Indicateur_Capteur4
@onready var indicateur_capt5 = $Indicateur_Capteur5
@onready var state_label = $Label_State
@onready var speed_label = $Label_Speed



# Called when the node enters the scene tree for the first time.
func _ready():
	nfsm = $"../NetworkFSM"
	capteurs_SL = [false, false, false, false, false]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Process data received here from simulation and RPiCar
	# If websocket connection
	#if nfsm.current_state == $"../NetworkFSM/NetworkProcessState" :
		## Do something here
		#pass

	var rotation = 0

	match state:
		State.following_line:
			var result = suivre_ligne(delta, speed)
			speed = result[0]
			state = result[1]
			rotation = result[2]
			update_state_label()
		State.turning_left:
			tick_counter += 1
			if speed > 0.025:
				speed -= ACCELERATION/500
			rotate_y(-0.30 * delta)
			if tick_counter >= 3000:
				state = State.following_line
				tick_counter = 0
			update_state_label()	
		State.turning_right:
			tick_counter += 1
			if speed > 0.025:
				speed -= ACCELERATION/500
			rotate_y(0.30 * delta)
			if tick_counter >= 3000:
				state = State.following_line
				tick_counter = 0
			update_state_label()
		State.manual_control:
			if Input.is_key_pressed(KEY_W):
				if speed < V_MAX:
					speed += ACCELERATION
			if !Input.is_key_pressed(KEY_W):
				if speed > 0:
					speed -= ACCELERATION
			if Input.is_key_pressed(KEY_S):
				speed = 0
				
			# Rotate left/right
			if Input.is_key_pressed(KEY_A):
				rotate_y(0.30 * delta)
			if Input.is_key_pressed(KEY_D):
				rotate_y(-0.30 * delta) 
				
			update_state_label()
			if line_detected():
				state = State.following_line
			
		State.reverse:	
			var old_move = movement_array.get_last_move()
			if old_move != null:
				speed = -old_move[0]
				rotation = -old_move[1]
			else:
				if speed < 0:
					speed += ACCELERATION
				
		State.decelerate:
			if speed > 0:
				speed -= ACCELERATION
			else:
				state = State.reverse
				
	rotate_y(rotation * delta)
	translate(Vector3(-delta * speed, 0, 0))
	update_speed_label()
	
	if state != State.reverse:
		if rotation == 0:
			var movement = Movement.new(speed, (delta * speed), MovementType.translation, rotation)
			movement_array.add_move(movement)
		else:
			var movement = Movement.new(speed, (delta * speed), MovementType.rotation, rotation)
			movement_array.add_move(movement)
		
	# print("Vitesse courante: %f" % speed)
	

func _physics_process(delta):
	pass
	

	
func update_speed_label():
	speed_label.text = "Vitesse: %.3f m/s" % speed

	
func update_state_label():
	var state_text
	match state:
		State.manual_control:
			state_text = "Manual Control"
		State.following_line:
			state_text = "Following Line"
		State.turning_left:
			state_text = "Turning Left"
		State.turning_right:
			state_text = "Turning Right"
		_:
			state_text = "Unknown State"
	
	state_label.text = "Current PiCar State: %s" % state_text  # Converts the state enum to string
	
	
func calculate_actual_speed(translation, delta):
	return translation/delta
	
	
func line_detected():
	if capteurs_SL != [false, false, false, false, false]:
		return true
	else:
		return false


func suivre_ligne(delta, speed, use_90deg_turns=false):
	
	var new_speed = speed
	var new_state = State.following_line
	var new_rotation = 0
	if capteurs_SL == [false, false, false, false, false]:
		if speed > 0:
			new_speed -= ACCELERATION
		new_state = State.manual_control
	elif capteurs_SL == [false, false, true, false, false]:
		if speed < V_MAX:
			new_speed += ACCELERATION
	elif capteurs_SL == [false, true, true, false, false]:
		new_rotation = -deg_to_rad(3)
		if speed > V_TURN:
			new_speed -= ACCELERATION
	elif capteurs_SL == [false, false, true, true, false]:
		new_rotation = deg_to_rad(3)
		if speed > V_TURN:
			new_speed -= ACCELERATION
	elif capteurs_SL == [false, true, false, false, false]:
		new_rotation = -deg_to_rad(10)
		if speed > V_TURN:
			new_speed -= ACCELERATION
	elif capteurs_SL == [false, false, false, true, false]:
		new_rotation = deg_to_rad(10)
		if speed > V_TURN:
			new_speed -= ACCELERATION
	elif capteurs_SL == [true, true, false, false, false]:
		new_rotation = -deg_to_rad(30)
		if speed > V_TIGHT_TURN:
			new_speed -= ACCELERATION
	elif capteurs_SL == [false, false, false, true, true]:
		new_rotation = deg_to_rad(30)
		if speed > V_TIGHT_TURN:
			new_speed -= ACCELERATION
	elif capteurs_SL == [true, false, false, false, false]:
		new_rotation = -deg_to_rad(45)
		if speed > V_TIGHT_TURN:
			new_speed -= ACCELERATION
	elif capteurs_SL == [false, false, false, false, true]:
		new_rotation = deg_to_rad(45)
		if speed > V_TIGHT_TURN:
			new_speed -= ACCELERATION
	elif use_90deg_turns == true:
		if capteurs_SL == [true, true, true, false, false] or capteurs_SL == [true, true, true, true, false] or capteurs_SL == [true, true, false, true, false]:
			new_rotation = -5
			if speed > 0:
				new_speed -= ACCELERATION
			new_state = State.turning_left
		elif capteurs_SL == [false, false, true, true, true] or capteurs_SL == [false, true, true, true, true] or capteurs_SL == [false, true, false, true, true]:
			new_rotation = 5
			if speed > 0:
				new_speed -= ACCELERATION
			new_state = State.turning_right
	elif capteurs_SL == [true, true, true, true, true]:
		if speed > 0:
			new_speed -= ACCELERATION
		new_state = State.decelerate

	return [new_speed, new_state, new_rotation] 
	

func change_color(index, detected, too_far=false):
	var green = Color(0, 1, 0)
	var red = Color(1, 0, 0)
	var pink = Color(1, 0.5, 0.8)
	match index:
		0:
			if detected:
				indicateur_capt1.color = green
			else:
				indicateur_capt1.color = red
			if too_far:
				indicateur_capt1.color = pink
		1:
			if detected:
				indicateur_capt2.color = green
			else:
				indicateur_capt2.color = red
			if too_far:
				indicateur_capt2.color = pink
		2:
			if detected:
				indicateur_capt3.color = green
			else:
				indicateur_capt3.color = red
			if too_far:
				indicateur_capt3.color = pink
		3:
			if detected:
				indicateur_capt4.color = green
			else:
				indicateur_capt4.color = red
			if too_far:
				indicateur_capt4.color = pink
		4:
			if detected:
				indicateur_capt5.color = green
			else:
				indicateur_capt5.color = red
			if too_far:
				indicateur_capt5.color = pink
	

func _on_capteur_1_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[0] = true
		change_color(0, true)
	if area.name == "TOO_FAR":
		change_color(0, true, true)


func _on_capteur_1_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[0] = false
		change_color(0, false)
	

func _on_capteur_2_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[1] = true
		change_color(1, true)
	if area.name == "TOO_FAR":
		change_color(1, true, true)


func _on_capteur_2_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[1] = false
		change_color(1, false)


func _on_capteur_3_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[2] = true
		change_color(2, true)
	if area.name == "TOO_FAR":
		change_color(2, true, true)


func _on_capteur_3_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[2] = false
		change_color(2, false)


func _on_capteur_4_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[3] = true
		change_color(3, true)
	if area.name == "TOO_FAR":
		change_color(3, true, true)


func _on_capteur_4_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[3] = false
		change_color(3, false)


func _on_capteur_5_area_entered(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[4] = true
		change_color(4, true)
	if area.name == "TOO_FAR":
		change_color(4, true, true)


func _on_capteur_5_area_exited(area):
	if area.name.begins_with("Line") or area.name.begins_with("Parcours"):
		capteurs_SL[4] = false
		change_color(4, false)

