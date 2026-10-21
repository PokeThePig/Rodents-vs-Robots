extends "res://Scripts/rodent_ally.gd"

func _initialize_rodent():
	$GuineaSprite.play("guinea_walk")
	wander_speed = 80.0
	sprint_speed = 340.0
	elasticity = 5
	smoothing_factor = 0.08
	separation_distance = randf_range(25, 60)

func _play_moving_animation():
	# Flipping sprite for direction
	if velocity.x < -5.0:
		$GuineaSprite.flip_h = true
	elif velocity.x > 5.0:
		$GuineaSprite.flip_h = false
		
	$GuineaSprite.play("guinea_walk")

func _play_idle_animation():
	$GuineaSprite.play("guinea_idle")
