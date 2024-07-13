extends CanvasLayer
var i=0
func _process(delta):
	while i<1:
		print('updating options')
		if Global.FPS == true:
			$FPSVisibilityToggle.button_pressed = true
		else:
			$FPSVisibilityToggle.button_pressed = false
		i += 1
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_reset_progress_pressed():
	Global.score = 0
	Global.best_score = 0

func _on_fps_visibility_toggle_pressed():
	Global.FPS = !Global.FPS
