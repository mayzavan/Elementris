extends CanvasLayer
@onready var nextsprite = $NextWPanel/Sprite
@onready var currsprite = $CurrentWPanel/Sprite

func swap_sprites(current_weapon, next_weapon):
	match current_weapon : 
		0:
			currsprite.frame = 2
		1:
			currsprite.frame = 3
		2:
			currsprite.frame = 0
		3:
			currsprite.frame = 1
	match next_weapon : 
		0:
			nextsprite.frame = 2
		1:
			nextsprite.frame = 3
		2:
			nextsprite.frame = 0
		3:
			nextsprite.frame = 1
func _process(delta):
	if Global.FPS == true:
		var fps = Engine.get_frames_per_second()
		$FPSLabel.text = ("FPS: " + str(fps))
	elif Global.FPS == false:
		$FPSLabel.text = " "
