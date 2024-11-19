extends Node

class_name MovementArray

var Movement = load("res://scripts/classes/Movement.gd")

# Changer cette const pour sauvegarder plus de mouvements et reculer plus loin
const MAX_DISPLACEMENT: float = 1

var array: Array[Movement] = []
var total_distance: float = 0

func add_move(movement: Movement):
	if movement.displacement + total_distance < MAX_DISPLACEMENT:
		array.append(movement)
		total_distance += movement.displacement
	else:
		while (total_distance + movement.displacement) > MAX_DISPLACEMENT:
			if array.size() > 0: # this condition shouldnt be possible but wtv
				# array[0].print_movement()
				total_distance -= array[0].displacement
				array.pop_front()
			
		array.append(movement)
		total_distance += movement.displacement
		
	# movement.print_movement()
	
func get_last_move():
	var move = array.back()
	if move != null:
		array.pop_back()
		return [move.speed, move.rotation]
		
func check_last_rotation():
	return array.back().rotation
	
func print_movement_array():
	for move in array:
		move.print_movement()
