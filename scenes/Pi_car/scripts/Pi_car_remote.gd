extends Node3D

const MovementType = Enums.MovementType
const State = Enums.State
var Movement = load("res://scripts/classes/Movement.gd")
var MovementArray = load("res://scripts/classes/Movement_Array.gd")
var utils = load("res://scenes/Pi_car/scripts/utils.gd").new()

var stuff = 1
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
var V_MAX = 0.18 # m/s
""" EXPLICATION V_TURN ET V_TIGHT_TURN
Ces vitesses ont été trouvées en vérifiant si le robot pouvait faire les 
virages du parcours réel

SI ON MODIFIE CES VALEURS, ON DOIT S'ASSURER DE VÉRIFIER LES RÉSULTATS DANS LE 
PARCOURS RÉEL
""" 
var V_TURN = 0.12
var V_TIGHT_TURN = 0.066
const MAX_DISPLACEMENT = 0.2
const WALL_STOP = 10
const BRAKE_RANGE = 5
const REVERSE_RANGE = 20
const CENTRE = 90
const GAUCHE = 60
const DROITE = 120
const AVOID_TIME = 1
const WAIT_TIME = 0.5

var noteMaxime = "Salut :)"

var nfsm = 0
var speed = 0
var capteurs_SL = []
var state = State.manual_control
var tick_counter = 0
var movement_array: MovementArray = MovementArray.new()
var avoid_timer = 0

var start_time = 0
var previous_error = 0
var P = 0
var I = 0
var D = 0
var Pvalue = 0
var Ivalue = 0
var Dvalue = 0

var KP = 0.0001
var KI = 0.0001
var KD = 0.0001
var last_direction = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	start_time = Time.get_ticks_msec()
	nfsm = $"../NetworkFSM"
	capteurs_SL = [false, false, false, false, false]
	ACCELERATION = Settings.acceleration
	V_MAX = Settings.v_max
	V_TURN = Settings.v_turn * V_MAX
	V_TIGHT_TURN = Settings.v_tight_turn * V_MAX

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _physics_process(delta):
	pass
	
func calculate_actual_speed(translation, delta):
	return translation/delta
			
func suivre_ligne_comm(delta, speed, capteurs, distance, use_90deg_turns=false):
	var new_speed = speed
	var new_state = State.following_line
	var new_rotation = 0
	print("capteurs array is for suivre ligne comm is ", capteurs)
	if capteurs == [false, false, false, false, false]:
		if speed > 0.06666:
			print("decreasing speed right neow")
			new_speed -= ACCELERATION/2 * delta
		
	elif capteurs == [false, false, true, false, false]:
		if speed < V_MAX:
			new_speed += ACCELERATION/2 * delta
	elif capteurs == [false, false, true, true, false]:
		new_rotation = 3
		if speed > V_TURN:
			new_speed -= ACCELERATION/5 * delta
	elif capteurs == [false, true, true, false, false]:
		new_rotation = -3
		if speed > V_TURN:
			new_speed -= ACCELERATION/5 * delta
	elif capteurs == [false, false, false, true, false]:
		new_rotation = 10
		if speed > V_TURN:
			new_speed -= ACCELERATION/2 * delta
	elif capteurs == [false, true, false, false, false]:
		new_rotation = -10
		if speed > V_TURN:
			new_speed -= ACCELERATION/2 * delta
	elif capteurs == [false, false, false, true, true]:
		new_rotation = 30
		if speed > V_TIGHT_TURN:
			new_speed -= ACCELERATION/2 * delta
	elif capteurs == [true, true, false, false, false]:
		new_rotation = -30
		if speed > V_TIGHT_TURN:
			new_speed -= ACCELERATION/2 * delta
	elif capteurs == [false, false, false, false, true]:
		new_rotation = 45
		print(new_speed)
		if speed > V_TIGHT_TURN:
			new_speed -= ACCELERATION/2 * delta
	elif capteurs == [true, false, false, false, false]:
		new_rotation = -45
		if speed > V_TIGHT_TURN:
			new_speed -= ACCELERATION/2 * delta
	elif use_90deg_turns == true:
		if capteurs == [false, false, true, true, true] or capteurs == [false, true, true, true, true] or capteurs_SL == [false, true, false, true, true]:
			new_rotation = 5  # Left turn
			if speed > 0:
				new_speed -= ACCELERATION/2 * delta
			new_state = State.turning_left
		elif capteurs == [true, true, true, false, false] or capteurs == [true, true, true, true, false] or capteurs_SL == [true, true, false, true, false]:
			new_rotation = 5  # Right turn

			if speed > 0:
				new_speed -= ACCELERATION/2 * delta
			new_state = State.turning_right
	elif capteurs == [true, true, true, true, true]:
		if speed > 0:
			new_speed -= ACCELERATION * delta
		new_state = State.stopping

	return [new_speed, new_state, new_rotation]
	
func treat_info(delta, capteurs, distance):
	print(distance)
	var rotation = 0

	match state:
		State.manual_control:
			if utils.line_detected(capteurs):
				state = State.following_line

		State.following_line:
			var result = suivre_ligne_comm(delta, speed, capteurs, distance)
			speed = result[0]
			state = result[1]
			rotation = result[2]
			
			if distance < WALL_STOP + BRAKE_RANGE and distance > 0:
				if speed > 0:
					speed -= ACCELERATION * delta
				if distance < WALL_STOP:	
					avoid_timer = 0
					speed = 0
					state = State.blocked
				
			
		State.turning_left:
			tick_counter += 1
			if speed > 0.06666:
				speed -= ACCELERATION/500 * delta
			if tick_counter >= 3000:
				state = State.following_line
				tick_counter = 0
			
		State.turning_right:
			tick_counter += 1
			if speed > 0.06666:
				speed -= ACCELERATION/500 * delta
			if tick_counter >= 3000:
				state = State.following_line
				tick_counter = 0
		State.stopping:
			if speed > 0:
				speed -= ACCELERATION * delta
			
		#State.reverse:
			#if speed > 0:
				#speed -= ACCELERATION * delta
			#else:
				#var old_move = movement_array.get_last_move()
				#if old_move != null:
					#speed = -old_move[0]
					#rotation = -old_move[1]
				#else:
					#if speed < 0:
						#speed += ACCELERATION * delta

		State.blocked:
			if distance < WALL_STOP + BRAKE_RANGE and distance > 0 and avoid_timer == 0:
				if speed > -V_MAX:
					noteMaxime = "Je deccelere !"
					speed -= ACCELERATION * delta
			else:
				avoid_timer += delta * 10
				noteMaxime = "J'attend devant le mur, timer = " + str(avoid_timer)
				if speed < 0:
					speed += 2*ACCELERATION * delta
					
				if avoid_timer > WAIT_TIME:
					noteMaxime = "C'est reparti"
					avoid_timer = 0
					state = State.avoiding
				
		State.avoiding:
			avoid_timer += delta * 10
			if speed < V_MAX:
				speed += 3*ACCELERATION * delta
				noteMaxime = "VROOM !"
				
			if avoid_timer < AVOID_TIME:
				rotation = GAUCHE
				noteMaxime = "Je tourne, timer = " + str(avoid_timer)
			else:
				avoid_timer = 0
				state = State.recovering
		
		State.recovering:
			avoid_timer += delta * 10
			if avoid_timer < AVOID_TIME:
				rotation = DROITE
				noteMaxime = "Je reviens, timer = " + str(avoid_timer)
			else:
				rotation = CENTRE
				noteMaxime = "Je cherche la ligne :D"
			
			if capteurs[0] or capteurs[1] or capteurs[2] or capteurs[3] or capteurs[4]:
				state = State.following_line
				
	var deg_rotation = rotation
	var message_to_robot = {
		
		"rotation": int(deg_rotation),
		"speed": speed
	}
	print("Phase de test de Maxime:\n" +
	"State: " + str(state) + "\n" +
	"Vitesse: " + str(speed) + "\n" +
	"Note de code: " + noteMaxime)
	#print("V_MAX is : ", V_MAX)
	#print("state is ", state)
	return message_to_robot

	
