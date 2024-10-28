extends Node

class_name Movement

const MovementType = preload("res://scripts/enums.gd").MovementType

var displacement: float
var type: int

func _init(displacement, type):
	self.displacement = displacement
	self.type = type
	
func print_movement():
	print("Movement saved: { displacement: %.2f, type: %d }" % [displacement, type])
