extends Node2D

var track_scene_path = Globals.scene_path

@onready var acceleration_spinbox = $AccelerationSpinBox
@onready var vmax_spinbox = $VmaxSpinBox
@onready var vturn_spinbox = $VturnSpinBox
@onready var vtight_turn_spinbox = $VtightTurnSpinBox
# Called when the node enters the scene tree for the first time.
func _ready():
	print(track_scene_path)
	#Set spin boxes
	acceleration_spinbox.min_value = 0.0000001
	acceleration_spinbox.max_value = 1000
	acceleration_spinbox.step = 0.0001
	acceleration_spinbox.value = Settings.acceleration  # Valeur par défaut
	
	vmax_spinbox.min_value = 0.15
	vmax_spinbox.max_value = 0.3
	vmax_spinbox.step = 0.01
	vmax_spinbox.value = Settings.v_max
	
	vturn_spinbox.min_value = 0.1
	vturn_spinbox.max_value = 0.5
	vturn_spinbox.step = 0.01
	vturn_spinbox.value = Settings.v_turn
	
	vtight_turn_spinbox.min_value = 0.06
	vtight_turn_spinbox.max_value = 0.3
	vtight_turn_spinbox.step = 0.005
	vtight_turn_spinbox.value = Settings.v_tight_turn
	
	
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().change_scene_to_file("res://main.tscn")


func _on_start_button_pressed():
	Settings.acceleration = acceleration_spinbox.value
	Settings.v_max = vmax_spinbox.value
	Settings.v_turn = vturn_spinbox.value
	Settings.v_tight_turn = vtight_turn_spinbox.value
	get_tree().change_scene_to_file(track_scene_path)


func _on_run_tests_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Test_Runner/test_runner.tscn")
