extends CanvasLayer
signal cont
signal unpause
func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
func _on_main_menu_button_button_down():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
func _on_play_again_button_button_down():
	cont.emit()
