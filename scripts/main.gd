extends Node3D



func _on_parcours_sl_button_pressed():
	get_tree().change_scene_to_file("res://scenes/parcours/Parcours_SL/parcours_SL.tscn")


func _on_parcours_reel_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Choix_Valeurs/chooseParcoursValues.tscn")


func _on_parcours_us_button_pressed():
	get_tree().change_scene_to_file("res://scenes/parcours/Parcours_US/Ultrason.tscn")



func _on_quit_button_pressed():
	get_tree().quit()

