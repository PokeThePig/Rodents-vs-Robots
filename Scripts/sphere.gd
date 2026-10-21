extends "res://Scripts/enemy.gd"

var facing_dir = 1
var flip_cooldown = 0.0
const FLIP_COOLDOWN_TIME = 0.2  #Minimum seconds between flips

func _initialize_enemy():
	max_health = 10.0
	speed = 100.0
	contact_damage = 6.0
	$SphereSprite.play("sphere_walk")
	

func _play_moving_animation():
	# Flipping sprite for direction
	flip_cooldown -= get_physics_process_delta_time()
	if abs(velocity.x) > 20.0 and flip_cooldown <= 0.0:
		var new_dir = sign(velocity.x)
		if new_dir != facing_dir:
			facing_dir = new_dir
			$SphereSprite.flip_h = facing_dir < 0
			flip_cooldown = FLIP_COOLDOWN_TIME
		
	$SphereSprite.play("sphere_walk")
