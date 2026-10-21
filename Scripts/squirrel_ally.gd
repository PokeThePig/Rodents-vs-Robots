extends "res://Scripts/rodent_ally.gd"

func _initialize_rodent():
	$SquirrelSprite.play("squirrel_walk")
	wander_speed = 90.0
	sprint_speed = 350.0
	elasticity = 6.0
	smoothing_factor = 0.08
	separation_distance = randf_range(35, 60)

func _play_moving_animation():
	# Flipping sprite for direction
	if velocity.x < -5.0:
		$SquirrelSprite.flip_h = true
	elif velocity.x > 5.0:
		$SquirrelSprite.flip_h = false
		
	$SquirrelSprite.play("squirrel_walk")

func _play_idle_animation():
	$SquirrelSprite.play("squirrel_idle")
