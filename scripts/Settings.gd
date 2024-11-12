extends Node

var acceleration
var v_max
var v_turn
var v_tight_turn
var kp
var ki
var kd

# Called when the node enters the scene tree for the first time.
func _ready():
	# Charger la scène de PiCar temporairement pour récupérer les valeurs par défaut
	var picar_script = load("res://scenes/Pi_car/scripts/Pi_car.gd").new()
	acceleration = picar_script.ACCELERATION
	v_max = picar_script.V_MAX
	v_turn = picar_script.V_TURN
	v_tight_turn = picar_script.V_TIGHT_TURN
	kp = picar_script.KP
	ki = picar_script.KI
	kd = picar_script.KD

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
