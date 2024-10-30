extends Node

var acceleration
var v_max
var v_turn
var v_tight_turn

# Called when the node enters the scene tree for the first time.
func _ready():
	# Charger la scène de PiCar temporairement pour récupérer les valeurs par défaut
	var picar_script = load("res://scenes/Pi_car/scripts/Pi_car.gd").new()
	acceleration = picar_script.ACCELERATION
	v_max = picar_script.V_MAX
	v_turn = picar_script.V_TURN
	v_tight_turn = picar_script.V_TIGHT_TURN

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
