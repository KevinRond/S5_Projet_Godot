extends Node

class_name MovementArray

var Movement = load("res://scripts/classes/Movement.gd")

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
				print("deleting first move")
				array[0].print_movement()
				total_distance -= array[0].displacement
				array.pop_front()
			
		array.append(movement)
		total_distance += movement.displacement
		
	print("adding movement: ")
	movement.print_movement()
	print("total distance: %.3f" % total_distance)
	
func get_last_move():
	var move = array.back()
	if move != null:
		array.pop_back()
		return [move.speed, move.rotation]
	
func print_movement_array():
	for move in array:
		move.print_movement()
