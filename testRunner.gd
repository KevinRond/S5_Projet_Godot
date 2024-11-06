extends Node

# Your existing parameter ranges and settings
var acceleration_values = [0.075, 0.08, 0.09, 0.095, 0.1]
var v_max_values = [0.205, 0.21, 0.215, 0.22, 0.225, 23]
var v_turn_ratios = [0.7, 0.8, 0.9, 0.95]
var v_tight_turn_ratios = [0.35]

var test_scene_path = "res://scenes/parcours/Parcours_Reel/parcours_reel.tscn"

func _ready():
	run_tests()

func run_tests() -> void:
	Engine.time_scale = 3.5
	for acceleration in acceleration_values:
		for v_max in v_max_values:
			for v_turn in v_turn_ratios:
				for v_tight_turn in v_tight_turn_ratios:
					# Set the parameters in Settings.gd
					Settings.acceleration = acceleration
					Settings.v_max = v_max
					Settings.v_turn = v_turn
					Settings.v_tight_turn = v_tight_turn
					
					print("Testing with: Acceleration =", acceleration, 
						  "Vmax =", v_max, "V_turn =", v_turn, 
						  "V_tight_turn =", v_tight_turn)
					
					var test_scene = load(test_scene_path).instantiate()
					get_tree().root.call_deferred("add_child", test_scene)
					
					var picar_node = test_scene.get_node("PiCar")
					picar_node.connect("test_completed", Callable(self, "_on_test_completed"))
					await picar_node.test_completed

					# Clean up the scene for the next test
					test_scene.queue_free()
	Engine.time_scale = 1.0
	get_tree().quit()
	print("All tests completed.")

func _on_test_completed() -> void:
	emit_signal("test_completed")  # This resumes the `await` in `run_tests()`
