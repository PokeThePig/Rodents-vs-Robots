extends "res://Scripts/rodent_ally.gd"

func _initialize_rodent():
	$RatSprite.play("rat_walk")
	wander_speed = 75.0
	sprint_speed = 325.0
	elasticity = 4.5
	smoothing_factor = 0.08
	separation_distance = randf_range(25, 50)

func _play_moving_animation():
	# Flipping sprite for direction
	if velocity.x < -5.0:
		$RatSprite.flip_h = true
	elif velocity.x > 5.0:
		$RatSprite.flip_h = false
		
	$RatSprite.play("rat_walk")

func _play_idle_animation():
	$RatSprite.play("rat_idle")
