extends RigidBody2D
@onready var sprite = $Sprite


#####################################
# weapon numbers
# 0 - fire
# 1 - water
# 2 - earth
# 3 - air
#
#
#####################################
func swap_sprites(current_weapon):
	match current_weapon : 
		0:
			sprite.frame = 2
		1:
			sprite.frame = 3
		2:
			sprite.frame = 0
		3:
			sprite.frame = 1
