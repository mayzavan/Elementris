extends Node

var save_path = "user://save"

var FPS :bool
var highscore

func save():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(highscore)
	#file.store_var(FPS)
	print('game saved')

func load():
	if FileAccess.file_exists(save_path):
		print("game loaded")
		var file = FileAccess.open(save_path, FileAccess.READ)
		highscore = file.get_var()
		#FPS = file.get_var()
		
	else:
		print("file not found")
		highscore = 0
		#FPS = false
