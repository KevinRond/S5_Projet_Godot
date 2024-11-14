extends Node2D


func _on_parcours_arret_pressed():
	Globals.change_scene_path("res://scenes/parcours/Parcours_ce_arret/Parcours_conduite_epreuve.tscn")
	get_tree().change_scene_to_file("res://scenes/Choix_Valeurs/ChooseParcoursValues.tscn")
	pass # Replace with function body.


func _on_parcours_virage_pressed():
	Globals.change_scene_path("res://scenes/parcours/Parcours_ce_virage/Parcours_conduite_epreuve.tscn")
	get_tree().change_scene_to_file("res://scenes/Choix_Valeurs/ChooseParcoursValues.tscn")
	pass # Replace with function body.


func _on_parcours_reculons_pressed():
	Globals.change_scene_path("res://scenes/parcours/Parcours_ce_reculons/Parcours_conduite_epreuve.tscn")
	get_tree().change_scene_to_file("res://scenes/Choix_Valeurs/ChooseParcoursValues.tscn")
	pass # Replace with function body.


func _on_parcours_obstacle_pressed():
	Globals.change_scene_path("res://scenes/parcours/Parcours_ce_obstacle/Parcours_conduite_epreuve.tscn")
	get_tree().change_scene_to_file("res://scenes/Choix_Valeurs/ChooseParcoursValues.tscn")
	pass # Replace with function body.


func _on_retourner_acceuil_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
	pass # Replace with function body.
