extends Node

@export var enemy_scene: PackedScene
@export var weapon_scene: PackedScene
@export var wall_particle: PackedScene
@export var fire_particle: PackedScene
@export var water_particle: PackedScene
@export var air_particle: PackedScene
@export var cross_particle: PackedScene

var weapon_instance
var cell_size = Vector2(16,16)
var cell_amount = Vector2(10, 24)
var enemies: Array
var weapons: Array
var walls: Array
var game_lost = false
var game_paused = false
var grid: Array
var numbers = [2,3,4,5,6,7,8,9,10,11]
var next_weapon: int
var current_weapon: int
var all_weapons: Array = [0,1,2,3]
var score = 0
var on_cooldown: = false
var speed = 0
var repetance = 0
var oldcalc
var newcalc
###########weapon info################
# weapon numbers
# 0 - fire
# 1 - water
# 2 - earth
# 3 - air
#####################################
func _ready():
	new_game()
	spawn_weapon()

#highlights the column where the player is
func _process(_delta):
	player_highlight((weapon_instance.position.x - 0.5 * cell_size.x - 32 )/cell_size.x)

#starts new game
func new_game():
	score = 0
	Global.load()
	$HUD/ScoreLabel.text = (str(score))
	$HUD/Highscore.text = (str(Global.highscore))
	game_lost = false
	game_paused = false
	$GameOverHUD.hide()
	$PauseHUD.hide()
	enemies.clear()
	walls.clear()
	weapons.clear()
	init_grid()
	var weapon = weapon_scene.instantiate()
	weapon.position.x = cell_size.x * 6 + 0.5 * cell_size.x
	weapon.position.y = 2* cell_size.y + 0.5 * cell_size.y
	add_child(weapon)
	weapons.append(weapon)
	weapon_instance = $Weapon
	current_weapon = all_weapons[0]
	spawn_weapon()
	$MoveMobs.wait_time = 3

#creates grid full of 0 at the beginning of the game
func init_grid():
	var height = cell_amount.y
	var width = cell_amount.x
	for y in height:
		var yarray:Array
		for x in width:
			var xarray:Array
			x = 0
			xarray.append(x)
			yarray.append(xarray)
		grid.append(yarray)

#moves mobs
func _on_move_mobs_timeout():
	var blocked = [0]
	for wall in walls:
		if wall != null and wall.position.x > 0:
			blocked.append(wall.position.x)
	for enemy in enemies:
		if enemy.position.x not in blocked:
			var old_position = Vector2(enemy.position.x, enemy.position.y)
			enemy.position.y -= cell_size.y
			pos_to_grid(enemy.position.x, enemy.position.y, 'mob')
			pos_to_grid(old_position.x, old_position.y, 0)
	$Sound/MobSFX.play()
	$SpawnMobs.start()
	check_line()
	check_loss()

#moves weapon back to 0,0
func spawn_weapon():
	if all_weapons.size() == 1:
		all_weapons = [0,1,2,3]
	current_weapon = next_weapon
	all_weapons.shuffle()
	next_weapon = all_weapons[0]
	all_weapons.pop_front()
	weapon_instance.position.x = cell_size.x * 6 + 0.5 * cell_size.x
	weapon_instance.position.y = 2* cell_size.y + 0.5 * cell_size.y
	pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 'weapon')
	weapon_instance.swap_sprites(current_weapon)
	$HUD.swap_sprites(current_weapon, next_weapon)

#inputs
func _input(event):
	if !game_lost and !game_paused:
		if Input.is_action_just_pressed("input_right") and weapon_instance.position.x < 11*cell_size.x \
				and check_grid(weapon_instance.position.x+cell_size.x,weapon_instance.position.y) != 'wall':
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 0)
			weapon_instance.position.x += cell_size.x
			$Sound/PlayerSFX.play()
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 'weapon')
			$MoveRight.start()
		if Input.is_action_just_pressed("input_left") and weapon_instance.position.x > 3*cell_size.x \
				and check_grid(weapon_instance.position.x-cell_size.x,weapon_instance.position.y) != 'wall':
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 0)
			weapon_instance.position.x -= cell_size.x
			$Sound/PlayerSFX.play()
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 'weapon')
			$MoveLeft.start()
		if Input.is_action_just_pressed("input_down") and weapon_instance.position.y < 25*cell_size.y \
				and check_grid(weapon_instance.position.x,weapon_instance.position.y+cell_size.y) != 'wall':
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 0)
			weapon_instance.position.y += cell_size.y
			$Sound/PlayerSFX.play()
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 'weapon')
			$MoveDown.start()
			
		if Input.is_action_just_released("input_left"):
			$MoveLeft.stop()
		if Input.is_action_just_released("input_right"):
			$MoveRight.stop()
		if Input.is_action_just_released("input_down"):
			$MoveDown.stop()
		if Input.is_action_just_pressed("input_replace"):
			var n = current_weapon
			current_weapon = next_weapon
			next_weapon = n
			weapon_instance.swap_sprites(current_weapon)
			$Sound/PlayerSFX.play()
			$HUD.swap_sprites(current_weapon, next_weapon)
		if Input.is_action_just_pressed("input_action"):
			if on_cooldown==false:
				var spell_position = Vector2(weapon_instance.position.x, weapon_instance.position.y)
				var spell_weapon = current_weapon
				pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 0)
				spawn_weapon()
				spell(spell_position.x,spell_position.y, spell_weapon)
				check_line()
				on_cooldown = true
				$SpellCooldown.start()
		if Input.is_action_just_pressed("input_pause"):
			Global.save()
			game_paused = true
			get_tree().paused = true
			$MoveMobs.stop()
			$PauseHUD.show()
	elif game_paused and Input.is_action_just_pressed("input_pause"):
		game_paused = false
		get_tree().paused = false
		$PauseHUD.hide()
		$MoveMobs.start()

#spawns new wave of enemies
func new_wave():
	for n in randi_range(4,6):
		var enemy = enemy_scene.instantiate()
		enemy.position.x = cell_size.x * random_number_for_x() + 0.5 * cell_size.x
		enemy.position.y = 25* cell_size.y + 0.5 * cell_size.y
		add_child(enemy)
		enemies.append(enemy)
		pos_to_grid(enemy.position.x, enemy.position.y, 'mob')
	numbers = [2,3,4,5,6,7,8,9,10,11]
	check_line()

#check whether enemy reached end of the board
func check_loss():
	for enemy in enemies:
		if enemy.position.y <= 3*cell_size.y:
			game_lost = true
			$GameOverHUD.show()
			$MoveMobs.stop()
			$MoveLeft.stop()
			$MoveDown.stop()
			$MoveRight.stop()
			Global.save()

#checks whether any row is full
func check_line():
	for y in grid.size():
		var n = 0
		for x in grid[y].size():
			var a = str(grid[y][x])
			if a == 'mob':
				n += 1
				if n >= 5:
					clear_line(y)
			elif a != 'mob':
				n=0

#check value of a cell in grid
func check_grid(xcheck, ycheck):
	var xgrid =(xcheck - 0.5 * cell_size.x - 32 )/cell_size.x
	var ygrid =(ycheck - 0.5 * cell_size.y - 32 )/cell_size.y
	var value = str(grid[ygrid][xgrid])
	return value

#assign a value to a grid and check what happens
func pos_to_grid(x, y, value):
	var xgrid =(x - 0.5 * cell_size.x - 32 )/cell_size.x
	var ygrid =(y - 0.5 * cell_size.y - 32 )/cell_size.y
	var old_value = grid[ygrid][xgrid]
	old_value = str(old_value)
	grid[ygrid][xgrid] = value
	value = str(value)
	if (old_value=='mob' and value=='weapon') or (old_value=='weapon' and value =='mob'):
		spawn_weapon()
		$Sound/DirectHitSFX.play()
		for enemy in enemies:
			if enemy.position == Vector2(x,y):
				var to_delete = enemies.find(enemy)
				enemies.pop_at(to_delete)
				enemy.queue_free()
				pos_to_grid(x, y, 0)
				if !game_lost:
					score+= 10
					update_score()
	elif (old_value=='wall' and value =='mob'):
		grid[ygrid][xgrid] = old_value
		for enemy in enemies:
			if enemy.position == Vector2(x,y):
				enemy.position.y = enemy.position.y + cell_size.y
				pos_to_grid(x, y, 'wall')

#calculate position from the cell in grid
func grid_to_pos(x,y):
	var xgrid = cell_size.x * x + 32 + cell_size.x * 0.5
	var ygrid = cell_size.y * y + 32 + cell_size.y * 0.5
	var position = Vector2(xgrid,ygrid)
	return position

#clears the row if check_line was true
func clear_line(y):
	var line_to_clear
	for x in 10:
		var row_positioned = grid_to_pos(x, y)
		var cross = cross_particle.instantiate()
		cross.position = Vector2(row_positioned.x, row_positioned.y)
		add_child(cross)
		particle(cross,0.2)
		var position = grid_to_pos(x,y)
		line_to_clear = position.y
		for enemy in enemies:
			if enemy.position == position:
				var to_delete = enemies.find(enemy)
				enemies.pop_at(to_delete)
				enemy.queue_free()
				pos_to_grid(position.x, position.y, 0)
				if !game_lost:
					score += 15
	update_score()
	await get_tree().create_timer(0.3, false).timeout
	for enemy in enemies:
		if enemy.position.y < line_to_clear:
			pos_to_grid(enemy.position.x, enemy.position.y, 0)
			enemy.position.y += cell_size.y
			pos_to_grid(enemy.position.x, enemy.position.y, 'mob')

#calculates random column for mob to spawn
func random_number_for_x():
	numbers.shuffle()
	var x:int = numbers[0]
	numbers.pop_front()
	return x

#kills enemy in given position
func kill(x,y):
	for enemy in enemies:
			if enemy.position == Vector2(x,y):
				var to_delete = enemies.find(enemy)
				enemies.pop_at(to_delete)
				enemy.queue_free()
				pos_to_grid(x, y, 0)
				if !game_lost:
					score+= 10
					update_score()

#updates score and adjusts difficulty
func update_score():
	if Global.highscore <= score:
		Global.highscore = score
	$HUD/ScoreLabel.text = (str(score))
	$HUD/Highscore.text = (str(Global.highscore))

#after esc in pause menu is pressed
func continue_game():
	game_paused = false
	get_tree().paused = false
	$PauseHUD.hide()
	$MoveMobs.start()

#throwing spell
func spell(x,y,weapon):
	match weapon : 
		0:
			#fire
			for xr in range(3):
				for yr in range(3):
					await get_tree().create_timer(0.01, false).timeout
					kill(x + xr*cell_size.x, y + yr*cell_size.y)
					kill(x - xr*cell_size.x, y - yr*cell_size.y)
					kill(x + xr*cell_size.x, y - yr*cell_size.y)
					kill(x - xr*cell_size.x, y + yr*cell_size.y)
					var fire = fire_particle.instantiate()
					var fire1 = fire_particle.instantiate()
					var fire2 = fire_particle.instantiate()
					var fire3 = fire_particle.instantiate()
					fire.position = Vector2(x + xr*cell_size.x, y + yr*cell_size.y)
					fire1.position = Vector2(x - xr*cell_size.x, y - yr*cell_size.y)
					fire2.position = Vector2(x + xr*cell_size.x, y - yr*cell_size.y)
					fire3.position = Vector2(x - xr*cell_size.x, y + yr*cell_size.y)
					add_child(fire)
					add_child(fire1)
					add_child(fire2)
					add_child(fire3)
					particle(fire,0.1)
					particle(fire1,0.1)
					particle(fire2,0.1)
					particle(fire3,0.1)
		1:
			#water:
			for row in cell_amount.y:
				var row_positioned = grid_to_pos(x, row)
				var water = water_particle.instantiate()
				water.position = Vector2(x, row_positioned.y)
				add_child(water)
				particle(water,0.1)
			await get_tree().create_timer(0.05, false).timeout
			for row in cell_amount.y:
				var row_positioned = grid_to_pos(x+cell_size.x, row)
				var water = water_particle.instantiate()
				water.position = Vector2(x+cell_size.x, row_positioned.y)
				add_child(water)
				particle(water,0.1)
			for enemy in enemies:
				if enemy.position.x == x:
					var old_position = Vector2(enemy.position.x, enemy.position.y)
					enemy.position.x += cell_size.x
					if enemy.position.x >= 2*cell_size.x + cell_amount.x * cell_size.x:
						var to_delete = enemies.find(enemy)
						enemies.pop_at(to_delete)
						enemy.queue_free()
						pos_to_grid(old_position.x, old_position.y, 0)
						if !game_lost:
							score+= 10
							update_score()
					elif check_grid(enemy.position.x, enemy.position.y) == 'mob' or check_grid(enemy.position.x, enemy.position.y) == 'wall':
						var to_delete = enemies.find(enemy)
						enemies.pop_at(to_delete)
						enemy.queue_free()
						pos_to_grid(old_position.x, old_position.y, 0)
						if !game_lost:
							score+= 10
							update_score()
					else:
						pos_to_grid(old_position.x, old_position.y, 0)
						pos_to_grid(enemy.position.x, enemy.position.y, 'mob')
			check_line()
		2:
			#earth
			wall_sound(randi_range(1,4))
			var wall = wall_particle.instantiate()
			wall.position.x = x
			wall.position.y = y
			add_child(wall)
			walls.append(wall)
			pos_to_grid(x,y,'wall')
			wall_created(x,y,wall)
			await get_tree().create_timer(0.05, false).timeout
			wall_sound(randi_range(1,4))
			if x+cell_size.y <= (cell_amount.x+2)*cell_size.x:
				var wall2 = wall_particle.instantiate()
				wall2.position.x = x+cell_size.x
				wall2.position.y = y
				add_child(wall2)
				walls.append(wall2)
				pos_to_grid(x+cell_size.x,y,'wall')
				wall_created(x+cell_size.x,y,wall2)
			await get_tree().create_timer(0.05, false).timeout
			wall_sound(randi_range(1,4))
			if x-cell_size.y >= 2*cell_size.x:
				var wall3 = wall_particle.instantiate()
				wall3.position.x = x-cell_size.x
				wall3.position.y = y
				add_child(wall3)
				walls.append(wall3)
				pos_to_grid(x-cell_size.x,y,'wall')
				wall_created(x-cell_size.x,y,wall3)
			check_line()
		3:
			#air
			for row in cell_amount.y:
				await get_tree().create_timer(0.005, false).timeout
				var row_positioned = grid_to_pos(x, row)
				var air = air_particle.instantiate()
				air.position = Vector2(x, row_positioned.y)
				add_child(air)
				particle(air,0.1)
				pos_to_grid(x,row,0)
			for enemy in enemies:
				if enemy.position.x == x:
						pos_to_grid(enemy.position.x, enemy.position.y, 0)
			for enemy in enemies:
				if enemy.position.x == x:
					var old_position = Vector2(enemy.position.x, enemy.position.y)
					enemy.position.y += cell_size.y
					if enemy.position.y >= 2*cell_size.y + cell_amount.y * cell_size.y:
						var to_delete = enemies.find(enemy)
						enemies.pop_at(to_delete)
						enemy.queue_free()
						pos_to_grid(old_position.x, old_position.y, 0)
						if !game_lost:
							score+= 10
							update_score()
					else:
						pos_to_grid(enemy.position.x, enemy.position.y, 'mob')
						pos_to_grid(old_position.x, old_position.y, 0)
			check_line()

#creates the wall timer to delete it
func wall_created(x,y,object):
	var this = object
	var to_delete = walls.find(this)
	if game_lost == false:
		await get_tree().create_timer(5.0, false).timeout
		this.position = Vector2(-8,0)
		pos_to_grid(x,y,0)
		walls[to_delete] = null
		this.queue_free()

#creates a cooldown for particle to delete it
func particle(object, time):
	var this = object
	await get_tree().create_timer(time, false).timeout
	this.queue_free()

func _on_move_down_timeout():
	if weapon_instance.position.y < 25*cell_size.y and check_grid(weapon_instance.position.x,weapon_instance.position.y+cell_size.y) != 'wall':
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 0)
			$Sound/PlayerSFX.play()
			weapon_instance.position.y += cell_size.y
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 'weapon')

func _on_move_left_timeout():
	if weapon_instance.position.x > 3*cell_size.x and check_grid(weapon_instance.position.x-cell_size.x,weapon_instance.position.y) != 'wall':
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 0)
			$Sound/PlayerSFX.play()
			weapon_instance.position.x -= cell_size.x
			pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 'weapon')

func _on_move_right_timeout():
	if weapon_instance.position.x < 11*cell_size.x and check_grid(weapon_instance.position.x+cell_size.x,weapon_instance.position.y) != 'wall':
		pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 0)
		$Sound/PlayerSFX.play()
		weapon_instance.position.x += cell_size.x
		pos_to_grid(weapon_instance.position.x, weapon_instance.position.y, 'weapon')

func _on_spell_cooldown_timeout():
	on_cooldown = false

func player_highlight(column):
	$GameBackground/White0.hide()
	$GameBackground/White1.hide()
	$GameBackground/White2.hide()
	$GameBackground/White3.hide()
	$GameBackground/White4.hide()
	$GameBackground/White5.hide()
	$GameBackground/White6.hide()
	$GameBackground/White7.hide()
	$GameBackground/White8.hide()
	$GameBackground/White9.hide()
	match column:
		0.0:
			$GameBackground/White0.show()
		1.0:
			$GameBackground/White1.show()
		2.0:
			$GameBackground/White2.show()
		3.0:
			$GameBackground/White3.show()
		4.0:
			$GameBackground/White4.show()
		5.0:
			$GameBackground/White5.show()
		6.0:
			$GameBackground/White6.show()
		7.0:
			$GameBackground/White7.show()
		8.0:
			$GameBackground/White8.show()
		9.0:
			$GameBackground/White9.show()

func wall_sound(num):
	match num:
		1:
			$Sound/WallSFX.play()
		2:
			$Sound/WallSFX2.play()
		3:
			$Sound/WallSFX3.play()

#dynamic difficulty adjustement
func calc_difficulty_rows():
	var empty
	var empty_row
	empty_row = 0
	for y in grid.size():
		empty = 0
		for x in grid[y].size():
			var a = str(grid[y][x])
			if a != 'mob':
				empty += 1
		if empty == 10:
			empty_row +=1
	if empty_row <= 2:
		return -3
	elif empty_row >2 and empty_row<=4:
		return -2
	elif empty_row >4 and empty_row<=6:
		return -1
	elif empty_row >6 and empty_row<=17:
		return 0
	elif empty_row >17 and empty_row<=19:
		return 1
	elif empty_row >19 and empty_row<=22:
		return 2
	elif empty_row > 22 :
		return 3

func _on_check_diff_timeout():
	newcalc = calc_difficulty_rows()
	if newcalc == oldcalc:
		repetance += 1
	oldcalc = newcalc
	if repetance >= 5 and newcalc == 0:
		$MoveMobs.wait_time -= 0.15
		repetance = 0
	elif repetance >=3 and newcalc != 0:
		speed = 0
		repetance = 0
	if newcalc != oldcalc:
		repetance = 0
	speed += newcalc
	if newcalc == 0:
		speed = 0
	if speed >= 10:
		$MoveMobs.wait_time -= 0.25
	elif speed <10 and speed >= 5:
		$MoveMobs.wait_time -= 0.1
	elif speed <5 and speed >= 2:
		$MoveMobs.wait_time -= 0.05
	elif speed <2 and speed >= -2:
		$MoveMobs.wait_time -= 0
	elif speed <-2 and speed >= -5:
		$MoveMobs.wait_time += 0.05
	elif speed <-5 and speed >= -10:
		$MoveMobs.wait_time += 0.15
	elif speed <-10 :
		$MoveMobs.wait_time += 0.4
