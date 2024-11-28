extends Node3D

const MovementType = Enums.MovementType
const State = Enums.State
var Movement = load("res://scripts/classes/Movement.gd")
var MovementArray = load("res://scripts/classes/Movement_Array.gd")
var utils = load("res://scenes/Pi_car/scripts/utils.gd").new()

signal test_completed

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
var ACCELERATION = ((9.8*0.0015)/0.02) # 0.0049 m/s^2
""" EXPLICATION V_MAX
La vitesse maximale fut trouvée en vérifiant si le robot pouvait arrêter avec 
l'incertitude de 30mm selon l'accélération trouvée

SI ON MODIFIE CETTE VALEUR, ON DOIT S'ASSURER DE REFAIRE LE TEST D'ARRÊT
""" 
var V_MAX = 0.08 # m/s
""" EXPLICATION V_TURN ET V_TIGHT_TURN
Ces vitesses ont été trouvées en vérifiant si le robot pouvait faire les 
virages du parcours réel

SI ON MODIFIE CES VALEURS, ON DOIT S'ASSURER DE VÉRIFIER LES RÉSULTATS DANS LE 
PARCOURS RÉEL
""" 
var V_TURN = 0.55*V_MAX
var V_TIGHT_TURN = 0.35*V_MAX
var start_time_sec = 0


const V_MIN = 0.08
const WALL_STOP = 10
const REVERSE_RANGE = 15
const US_ERROR = 10

# Côté de l'évitement: 1 -> Gauche, -1 -> Droite
const AVOID_SIDE = -1
const CENTRE = 0
const GAUCHE = -30
const DROITE = 30
const AIDE_COURBURE = 10

const AVOID_TIME = 1.00
const RETURN_TIME = 0.5

const AVOID_TIME_SEC = 3.8
const RETURN_TIME_SEC = 1.7

var nfsm = 0
var speed = 0
var state = State.manual_control
var tick_counter = 0
var movement_array: MovementArray = MovementArray.new()
var avoid_timer = 0
var backing_up_counter = 0.0
var last_direction = 0

var start_time = 0
var previous_error = 0

var P = 0
var I = 0
var D = 0
var Pvalue = 0
var Ivalue = 0
var Dvalue = 0

var KP = 0.875
var KI = 0.1
var KD = 0.1
var parcours_reverse = true
var line_passed = 0


@onready var indicateur_capt1 = $Indicateur_Capteur1
@onready var indicateur_capt2 = $Indicateur_Capteur2
@onready var indicateur_capt3 = $Indicateur_Capteur3
@onready var indicateur_capt4 = $Indicateur_Capteur4
@onready var indicateur_capt5 = $Indicateur_Capteur5
@onready var state_label = $Label_State
@onready var speed_label = $Label_Speed



# Called when the node enters the scene tree for the first time.
func _ready():
	start_time = Time.get_ticks_msec()
	nfsm = $"../NetworkFSM"
	ACCELERATION = Settings.acceleration
	V_MAX = Settings.v_max
	V_TURN = Settings.v_turn * V_MAX
	V_TIGHT_TURN = Settings.v_tight_turn * V_MAX

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _physics_process(delta):
	pass
	
		
	
func read_line(sensors):
	var on_line: bool = false
	var avg: float = 0
	var sum: int = 0
	
	for i in range(len(sensors)):
		if sensors[i] == true:
			on_line = true
			avg += i * 25
			sum += 1
			
	var last_position = avg / sum
	
	if not on_line:
		if last_position < (len(sensors) - 1) * 25 / 2:
			return 0
		else:
			return (len(sensors) - 1) * 25
	
	return avg / sum if sum > 0 else 0

func PID_Linefollow(error):
	P = error
	I = I + error
	D = error - previous_error
	
	Pvalue = KP*P
	Ivalue = KI*I
	Ivalue = clamp(Ivalue, -5, 5)
	Dvalue = KD*D
	
	var PID_value = Pvalue + Ivalue + Dvalue

	previous_error = error

	if PID_value < -40:
		PID_value = -40
	if PID_value > 40:
		PID_value = 40

	return PID_value
		

func suivre_ligne(delta, speed, capteurs):
	print("Capteurs: ", capteurs)
	var position = read_line(capteurs)
	var error = 50 - position
	var PID_output = PID_Linefollow(error)

	var new_speed = speed
	var new_state = State.following_line
	var new_rotation = PID_output
	
	if utils.finish_line_detected(capteurs) and !parcours_reverse:
		if speed > 0:
			new_speed -= ACCELERATION * delta
		new_rotation = 0 
		new_state = State.stopping
		


	if utils.finish_line_detected(capteurs) and line_passed < 2 and parcours_reverse:
		new_state = State.waiting
		print("detected line")
		line_passed += 1
	

	if !utils.line_detected(capteurs):
		if speed > 0:
			new_speed = 0.08
		last_direction = movement_array.check_last_rotation()
		new_state = State.find_line
	else:
		if speed < V_MAX:
			new_speed += ACCELERATION * 2 * delta
		if PID_output < 0:
			new_rotation = -max(PID_output, -40)
			if PID_output > 10:
				if speed > V_TURN and speed > 0.07:
					new_speed -= ACCELERATION * delta
					if new_speed > 0.07:
						new_speed = 0.07
			if PID_output > 30:
				if speed > V_TIGHT_TURN and speed > 0.07:
					new_speed -= ACCELERATION * delta
					if new_speed > 0.07:
						new_speed = 0.07
		else:
			new_rotation = -min(PID_output, 40)
			if PID_output < -10:
				if speed > V_TURN and speed > 0.07:
					new_speed -= ACCELERATION * delta
					if new_speed > 0.07:
						new_speed = 0.07
			if PID_output < -30:
				if speed > V_TIGHT_TURN and speed > 0.07:
					new_speed -= ACCELERATION * delta
					if new_speed > 0.07:
						new_speed = 0.07


	return [new_speed, new_state, new_rotation]
	


		

	
func treat_info(delta, capteurs, distance):
	print(distance)
	var rotation = 0

	match state:
		State.manual_control:
			if utils.line_detected(capteurs):
				state = State.following_line

		State.following_line:
			var result = suivre_ligne(delta, speed, capteurs)
			speed = result[0]
			state = result[1]
			rotation = result[2]
			
			if distance < WALL_STOP + REVERSE_RANGE + US_ERROR and distance > 0:
				if speed > V_MIN:
					speed -= ACCELERATION * delta
				else:
					speed = V_MIN
					
				if distance < WALL_STOP + US_ERROR and distance > 0:
					avoid_timer = 0
					speed = 0
					state = State.blocked
				
		
		State.stopping:
			if speed > 0:
				speed -= ACCELERATION * 2 * delta
			if speed < 0:
				speed += ACCELERATION * 2 * delta
			rotation = 0
			
		State.reverse:
			if speed > 0:
				speed -= ACCELERATION * 4 * delta
			else:
				var old_move = movement_array.get_last_move()
				if old_move != null:
					speed = -old_move[0]
					rotation = old_move[1]
				else:
					if speed < 0:
						speed += ACCELERATION * delta
						
						
			if utils.finish_line_detected(capteurs):
				print("detected line")
				line_passed += 1
			if utils.finish_line_detected(capteurs) and line_passed >= 3:
				print("RETOURNE DANS FOLL")
				state = State.stopping



		State.find_line:
			if utils.line_detected(capteurs):
				if speed < V_MAX:
					speed =0.00
				state = State.following_line

			if speed > -V_MAX:
				speed -= ACCELERATION *2 * delta
			backing_up_counter += delta
			if speed < 0:
				rotation = -last_direction*0.8	
			
		State.blocked:
			if (distance < WALL_STOP + REVERSE_RANGE or distance < 0) and avoid_timer == 0:
				if speed > -V_MAX:
					speed -= 0.5*ACCELERATION * delta
			else:
				avoid_timer = 1
				if speed < 0:
					speed += 2 * ACCELERATION * delta
				else:
					#avoid_timer = 0
					start_time_sec = Time.get_ticks_msec()/1000
					state = State.avoiding
				
		State.avoiding:
			#avoid_timer += delta * 10
			if speed < V_MAX:
				print("avoiding")
				speed += 2 * ACCELERATION * delta
			var elapsed_time_avoiding = Time.get_ticks_msec()/1000 - start_time_sec
			#if avoid_timer < AVOID_TIME:
				#rotation = AVOID_SIDE*GAUCHE
			if elapsed_time_avoiding < AVOID_TIME_SEC:
				rotation = AVOID_SIDE*GAUCHE
			elif elapsed_time_avoiding < 2*AVOID_TIME_SEC:
				rotation = GAUCHE + 15
			else:
				start_time_sec = Time.get_ticks_msec()/1000
				state = State.recovering
		
		State.recovering:
			#avoid_timer += delta * 10
			if speed > V_MIN:
					speed -= ACCELERATION * delta
			var elapsed_time_recov = Time.get_ticks_msec()/1000 - start_time_sec
			if elapsed_time_recov < RETURN_TIME_SEC:
				#if avoid_timer < RETURN_TIME / 2:
					#rotation = AVOID_SIDE*DROITE / 3
				#else:
					rotation = AVOID_SIDE*DROITE
			else:
				rotation = CENTRE - AVOID_SIDE*AIDE_COURBURE
			
			if capteurs[0] or capteurs[1] or capteurs[2] or capteurs[3] or capteurs[4]:
				#if speed < V_MAX: 
					#speed = 0.04
				state = State.following_line
				
		State.waiting:
			if !(utils.finish_line_detected(capteurs)) and line_passed < 2:
				state = State.following_line
			elif !(utils.finish_line_detected(capteurs)) and line_passed == 2:
				state = State.reverse
			else:
				state = State.waiting
			

	if state != State.reverse && speed > 0:
		if rotation == 0:
			var movement = Movement.new(speed, (delta * speed), MovementType.translation, rotation)
			movement_array.add_move(movement)
		else:
			var movement = Movement.new(speed, (delta * speed), MovementType.rotation, rotation)
			movement_array.add_move(movement)

	print("line counter: ", line_passed)
	var deg_rotation = rotation
	var message_to_robot = {
		
		"rotation": int(deg_rotation),
		"speed": speed
	}
	print(utils.set_state_text(state))
	return message_to_robot

