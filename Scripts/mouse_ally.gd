extends "res://Scripts/rodent_ally.gd"

func _initialize_rodent():
	$MouseSprite.play("mouse_walk")
	wander_speed = 60.0
	sprint_speed = 300.0
	elasticity = 5.0
	smoothing_factor = 0.1
	separation_distance = randf_range(15, 40)

func _play_moving_animation():
	# Flipping sprite for direction
	if velocity.x < -5.0:
		$MouseSprite.flip_h = true
	elif velocity.x > 5.0:
		$MouseSprite.flip_h = false
		
	$MouseSprite.play("mouse_walk")

func _play_idle_animation():
	$MouseSprite.play("mouse_idle")
