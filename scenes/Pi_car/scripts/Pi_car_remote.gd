extends Node3D

const MovementType = Enums.MovementType
const State = Enums.State
var Movement = load("res://scripts/classes/Movement.gd")
var MovementArray = load("res://scripts/classes/Movement_Array.gd")
var utils = load("res://scenes/Pi_car/scripts/utils.gd").new()

signal test_completed

var ACCELERATION = ((9.8*0.0015)/0.02) # 0.0049 m/s^2
var V_MAX = 0.1 # m/s
const V_MIN = 0.08

var V_TURN = 0.55*V_MAX
var V_TIGHT_TURN = 0.35*V_MAX
var start_time_sec = 0
var timer_retrouver_ligne = 0.0
var temps_retrouver_ligne = 0.75
var temps_cramper_roues = 0.2


const WALL_STOP = 10
const REVERSE_RANGE = 15
const US_ERROR = 11

# Côté de l'évitement: 1 -> Gauche, -1 -> Droite
const AVOID_SIDE = -1
const CENTRE = 0
const GAUCHE = -30
const DROITE = 30
const AIDE_COURBURE = 10

const AVOID_TIME = 1.00
const RETURN_TIME = 0.5

const AVOID_TIME_SEC = 4
const RETURN_TIME_SEC = 1.7

var nfsm = 0
var speed = 0
var state = State.manual_control
var tick_counter = 0
var movement_array: MovementArray = MovementArray.new()
var avoid_timer = 0
var last_direction = 0

var start_time = 0
var previous_error = 0

var P = 0
var I = 0
var D = 0
var Pvalue = 0
var Ivalue = 0
var Dvalue = 0

var KP = 0.65
var KI = 0.05
var KD = KI/8
var parcours_reverse = false
var line_passed = 0
var last_distance = 0
var states_robot = {
	1: "nothing_in_front",
	2: "initial_detection",
	3: "slowing_down_before_reverse",
	4: "reverse_to_30cm",
	5: "reaching_0_before_evitement",
	6: "start_of_evitement",
	7: "middle_of_evitement",
	8: "end_of_evitement",
	9: "catching_line",
	10: "2_sec_stop"
}

const REAL_V_MIN = 0.067
var delta_counter = 0
var delta_sum = 0
var DELTA_MIN = 0.0068
var DELTA_MAX = 0.0078

# Côté de l'évitement: -1 -> Gauche, 1 -> Droite
var avoid_side_array = [1,-1,1,1]
var avoid_side_index = 0

#turns pour l evitement
const EVITEMENT_FIRST_TURN=25
const EVITEMENT_MIDDLE_TURN=-15
const EVITEMENT_RECOVERING_FIRST_TURN=-30
const EVITEMENT_CATCHING_LINE_TURN=-5


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
		print("min pid value: ", PID_value)
		PID_value = -40
	if PID_value > 40:
		print("max pid value: ", PID_value)
		PID_value = 40

	return PID_value
		

func suivre_ligne(delta, speed, capteurs):
	delta = clamp(delta, DELTA_MIN, DELTA_MAX)
	
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
		timer_retrouver_ligne += delta * 10
		last_direction = movement_array.check_last_rotation()
		new_rotation = last_direction
		if speed > V_MIN:
			print("ok ralentit la")
			speed -= ACCELERATION * 2 * delta
		if last_direction > 0 and timer_retrouver_ligne > temps_cramper_roues:
			new_rotation = 40
		if last_direction < 0 and timer_retrouver_ligne > temps_cramper_roues:
			new_rotation = -40
		if timer_retrouver_ligne >= temps_retrouver_ligne:
			if !utils.line_detected(capteurs):
				new_state = State.find_line
				timer_retrouver_ligne = 0
	else:
		timer_retrouver_ligne = 0
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
	


		

	
func treat_info(delta, capteurs, robot_state):
	delta = clamp(delta, DELTA_MIN, DELTA_MAX)
	#delta_counter += 1
	#delta_sum += delta
	#
	#print("avg delta: ", delta_sum / delta_counter)
	print("delta: ", delta)
	
	print(robot_state)
	var robot_state_string = states_robot[int(robot_state)]
	print(robot_state_string)
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
			
			if robot_state_string == "initial_detection":
				if speed > V_MIN:
					speed -= 2*ACCELERATION * delta
				else:
					speed = V_MIN
			if robot_state_string == "slowing_down_before_reverse":
				if speed > REAL_V_MIN:
					speed = REAL_V_MIN
				else:
					speed = REAL_V_MIN
			if robot_state_string == "2_sec_stop":
				speed = 0
			if robot_state_string == "reverse_to_30cm":
				avoid_timer = 0
				#speed a -0.06 pcq de 0 a 0.06 robot bouge pas faque il va juste commencer a reculer plus vite
				speed = -0.06
				state = State.blocked
				
		
		State.stopping:
			if speed > 0:
				speed -= ACCELERATION * 2 * delta
			#pour les test
			if capteurs == [false,false,true,false,false]:
				state = State.following_line
			rotation = 0
			
		State.reverse_stopping:
			if speed < 0 and parcours_reverse:
				speed += ACCELERATION * 10 * delta
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
			if utils.finish_line_detected(capteurs) and line_passed > 3:
				print("RETOURNE DANS FOLL")
				state = State.reverse_stopping



		State.find_line:
			if utils.check_center_sensors(capteurs):
				if speed < V_MAX:
					# speed += 2*ACCELERATION*delta
					speed = 0 
				state = State.following_line
				
			if speed > -0.075:
				speed -= ACCELERATION * 2 * delta
			
			if speed > 0:
				rotation = last_direction
			
			if speed < 0:
				rotation = -last_direction * 0.8
			
		State.blocked:
			if robot_state_string == "reverse_to_30cm":
				if speed > -V_MIN:
					speed -= 2 * ACCELERATION * delta
				else:
					speed = -V_MIN
			#rajouter state d accel ici
			elif robot_state_string == "reaching_0_before_evitement":
				if speed > -REAL_V_MIN:
					speed -= 2 * ACCELERATION * delta
				else:
					speed = -REAL_V_MIN
			elif robot_state_string == "start_of_evitement":
				speed=0
				state = State.avoiding
				
		State.avoiding:
			#avoid_timer += delta * 10
			if speed < V_MAX:
				print("avoiding")
				speed += 2 * ACCELERATION * delta
			else:
				speed = V_MAX
			#if avoid_timer < AVOID_TIME:
				#rotation = AVOID_SIDE*GAUCHE
			if robot_state_string=="start_of_evitement":
				rotation = avoid_side_array[avoid_side_index] * EVITEMENT_FIRST_TURN
				if avoid_side_array[avoid_side_index] == -1:
					rotation = avoid_side_array[avoid_side_index] * EVITEMENT_FIRST_TURN * 0.8
			elif robot_state_string =="middle_of_evitement":
				rotation = avoid_side_array[avoid_side_index] * EVITEMENT_MIDDLE_TURN
				if avoid_side_array[avoid_side_index] == -1:
					rotation = avoid_side_array[avoid_side_index] * EVITEMENT_FIRST_TURN * 0.8
			elif robot_state_string=="end_of_evitement":
				rotation = avoid_side_array[avoid_side_index] * EVITEMENT_RECOVERING_FIRST_TURN
				if avoid_side_array[avoid_side_index] == -1:
					rotation = avoid_side_array[avoid_side_index] * EVITEMENT_FIRST_TURN * 0.8
				state = State.recovering
		
		State.recovering:
			if speed < V_MAX:
				print("avoiding")
				speed += 2 * ACCELERATION * delta
			else:
				speed = V_MAX
			if robot_state_string=="end_of_evitement":
				#if avoid_timer < RETURN_TIME / 2:
					#rotation = AVOID_SIDE*DROITE / 3
				#else:
					rotation = avoid_side_array[avoid_side_index] * EVITEMENT_RECOVERING_FIRST_TURN
			elif robot_state_string=="catching_line":
				print("AIDE ROTATIONNENENNEN AJKBNJAFBJABCJKBCA CAK CAN AC")
				rotation = avoid_side_array[avoid_side_index] * EVITEMENT_CATCHING_LINE_TURN
			
			if robot_state_string=="nothing_in_front":
				#if speed < V_MAX: 
					#speed = 0.04
				state = State.following_line
				avoid_side_index += 1
			elif utils.line_detected(capteurs):
				state = State.following_line
				avoid_side_index += 1
				
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
	print("timer retrouver ligne: ", timer_retrouver_ligne)
	var deg_rotation = rotation
	var message_to_robot = {
		
		"rotation": int(deg_rotation),
		"speed": speed
	}
	print(utils.set_state_text(state))
	return message_to_robot

