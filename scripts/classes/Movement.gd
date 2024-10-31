extends Node

class_name Movement

const MovementType = Enums.MovementType

var speed: float
var type: int
var rotation: float
var displacement: float

func _init(speed, displacement, type, rotation=0):
	self.speed = speed
	self.type = type
	self.rotation = rotation
	self.displacement = displacement
	
func print_movement():
	print("Movement: { speed: %.2f, displacement: %.5f, type: %d,  rotation: %.2f,  }" % [speed, displacement, type, rotation])
