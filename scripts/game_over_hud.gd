extends CanvasLayer
signal new_game
func _on_main_menu_button_button_down():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
func _on_play_again_button_button_down():
	get_tree().reload_current_scene()
	new_game.emit()
