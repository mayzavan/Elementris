extends CanvasLayer

var version = 0
func _ready():
	$CanvasGroup.hide()
	version = 0
func _on_new_game_button_button_down():
	#get_tree().change_scene_to_file("res://scenes/main.tscn")
	get_tree().root.add_child(preload("res://scenes/main.tscn").instantiate())
	#get_node("/root/MainMenu").free()
	
func _on_options_button_button_down():
	get_tree().change_scene_to_file("res://scenes/options.tscn")
	
func _on_quit_button_button_down():
	get_tree().quit()

func _on_credits_button_button_down():
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
	
func _on_version_button_button_down():
	if version == 0:
		$CanvasGroup.show()
		version = 1
	elif version == 1:
		$CanvasGroup.hide()
		version = 0

func _on_controls_button_button_down():
	get_tree().change_scene_to_file("res://scenes/controls.tscn")

func _on_h2p_button_button_down():
	get_tree().change_scene_to_file("res://scenes/how_to_play.tscn")
