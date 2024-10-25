extends Node3D



func _on_parcours_sl_button_pressed():
	get_tree().change_scene_to_file("res://scenes/parcours/Parcours_SL/parcours_SL.tscn")


func _on_parcours_reel_button_pressed():
	get_tree().change_scene_to_file("res://scenes/parcours/Parcours_Reel/parcours_reel.tscn")


func _on_parcours_us_button_pressed():
	pass # Replace with function body.



func _on_quit_button_pressed():
	get_tree().quit()

