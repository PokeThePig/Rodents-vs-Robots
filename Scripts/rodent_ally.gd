extends CharacterBody2D

#Combat values
var health = 100.0
var max_health = 100.0
var attack_range = 40.0
var attack_damage = 5.0
var attack_rate = 1.0
var target_enemy = null
var detection_range = 100.0
var engage_target = null
var attack_bounce_dir = Vector2.ZERO
var attack_arena_radius = 25.0
var attack_wander_speed = 200.0
var engage_speed = 140.0

#Location variables to add variety
var swarm_anchor = null
var random_offset = Vector2.ZERO
#Individual personality trait for how close each stays to center
var closeness_modifier = 1.0
#Timer for natural looking movement
var noise_time = 0.0
#Movement engine constants (updated in individual scripts)
var wander_speed = 60.0    #Base maximum speed
var sprint_speed = 300.0   #Speed if mouse falls behind
var elasticity = 5.0       #Pull force towards center
var smoothing_factor = 0.1 #Friction filter (0.1 = smooth slide, 1.0 = instant stops)
var separation_distance = 20.0 #Personal space bubble
var leash_range = 300.0 #Maximum range rodents can stay away before being pulled back

#Personal values
var rodent_sprite = null
var hit_tween = null

func _ready():
	add_to_group("rodent")
	_initialize_rodent()
	#Make mice move at different timestamps
	noise_time = randf_range(0.0, 100.0)
	#Add variety to how much mice stray
	closeness_modifier = randf_range(0.7, 1.2)
	
	for child in get_children():
		if child is AnimatedSprite2D:
			rodent_sprite = child
			break
	
	if has_node("WanderTimer"):
		$WanderTimer.timeout.connect(_pick_new_wander_spot)
		_pick_new_wander_spot()
	
	if has_node("AttackZone"):
		$AttackZone.body_entered.connect(_on_attack_zone_body_entered)
		$AttackZone.body_exited.connect(_on_attack_zone_body_exited)
		var attack_zone = $AttackZone.get_node_or_null("AttackCollision")
		if attack_zone and attack_zone.shape is CircleShape2D:
			attack_zone.shape.radius = attack_range
	
	if has_node("DetectionZone"):
		$DetectionZone.body_entered.connect(_on_detection_zone_body_entered)
		var det_shape = $DetectionZone.get_node_or_null("DetectionCollision")
		if det_shape and det_shape.shape is CircleShape2D:
			det_shape.shape.radius = detection_range
			
	if has_node("AttackTimer"):
		$AttackTimer.wait_time = attack_rate
		$AttackTimer.timeout.connect(_on_attack_timer_timeout)
		
	call_deferred("_check_for_enemy")

func _physics_process(delta):
	#Attacking movement
	if target_enemy:
		if not is_instance_valid(target_enemy):
			stop_attacking()
		else:
			_process_attack_movement(delta)
			return
	
	if engage_target:
		if not is_instance_valid(engage_target):
			engage_target = null
			_check_for_enemy()
		else:
			_process_engage_movement(delta)
			return
	
	#Stand still if unassigned
	if not swarm_anchor:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	#Increment timer
	noise_time += delta

	#Updating swarm border radius
	var border_shape = swarm_anchor.get_node_or_null("SwarmBorder/SwarmBorderCollision")
	var max_radius = 30.0
	if border_shape and border_shape.shape is CircleShape2D:
		max_radius = border_shape.shape.radius

	#If the border shrinks, pull our offset target back inside
	if random_offset.length() > max_radius:
		random_offset = random_offset.normalized() * (max_radius * 0.85)

	#Finding center of the bubble on the map
	var border_node = swarm_anchor.get_node_or_null("SwarmBorder")
	var center_origin = swarm_anchor.global_position
	if border_node:
		center_origin = border_node.global_position
	var target_position = center_origin + (random_offset * closeness_modifier)
	var distance_to_target = global_position.distance_to(target_position)
	var distance_from_center = global_position.distance_to(center_origin)
	
	#Start movement if more than 5 pixels away
	if distance_to_target > 5.0: 
		var current_speed_limit = wander_speed
		var movement_vector = (target_position - global_position).normalized()
		
		#Read player speed
		var swarm_velocity = swarm_anchor.velocity
		
		#Increase movement speed if mouse falls behind
		if distance_from_center > max_radius:
			current_speed_limit = sprint_speed
		#Rotate the directional heading arrow left and right using a smooth sine wave
		if distance_from_center < max_radius * 1.0:
			var wiggle_angle = sin(noise_time * 6.0) * 0.35
			movement_vector = movement_vector.rotated(wiggle_angle)
			
		#Calculate speed based on distance
		var target_velocity = movement_vector * distance_to_target * elasticity
		target_velocity = target_velocity.limit_length(current_speed_limit)
		
		#Adapting speed relative to the swarm
		if swarm_velocity.length() > 10.0:
			var lag_factor = clamp(distance_from_center / max_radius, 0.6, 1.3)
			target_velocity += swarm_velocity * lag_factor
			target_velocity = target_velocity.limit_length(sprint_speed)

		#Keeping mice slightly separated from one another
		var separation_force = Vector2.ZERO
		var neighbors = get_tree().get_nodes_in_group("rodent")
		for neighbor in neighbors:
			if neighbor != self and neighbor is CharacterBody2D:
				var dist = global_position.distance_to(neighbor.global_position)
				if dist < separation_distance and dist > 0.0:
					#Subtle push away from neighboring mice
					separation_force += (global_position - neighbor.global_position).normalized() * (separation_distance - dist) * 2.5
		
		target_velocity += separation_force
		target_velocity = target_velocity.limit_length(sprint_speed)

		#If falling behind, smoothly catch up to swarm
		var current_smoothing = smoothing_factor
		if distance_from_center > max_radius:
			current_smoothing = 0.25 
		velocity = velocity.lerp(target_velocity, current_smoothing)
		
		_play_moving_animation()
	else:
		#Not moving
		velocity = velocity.move_toward(Vector2.ZERO, 12.0)
		_play_idle_animation()
		
	move_and_slide()

func _get_swarm_center():
	if not swarm_anchor:
		return global_position
	var border_node = swarm_anchor.get_node_or_null("SwarmBorder")
	if border_node:
		return border_node.global_position
	return swarm_anchor.global_position

#Picking random spot to move to
func _pick_new_wander_spot():
	var max_radius = 50.0
	if swarm_anchor:
		var border_shape = swarm_anchor.get_node_or_null("SwarmBorder/SwarmBorderCollision")
		if border_shape and border_shape.shape is CircleShape2D:
			max_radius = border_shape.shape.radius
	
	#Generate a random angle and distance vector inside the circle radius
	var random_angle = randf_range(0.0, 2.0 * PI)
	var random_radius = randf_range(0.0, max_radius * 0.85)
	random_offset = Vector2(cos(random_angle), sin(random_angle)) * random_radius
	
	$WanderTimer.start(randf_range(.2, .8))

#Detection enemy nearby
func _on_detection_zone_body_entered(body):
	if not engage_target and not target_enemy and body.is_in_group("enemy"):
		engage_target = body

#Start moving towards enemy
func _process_engage_movement(delta):
	if not is_instance_valid(engage_target):
		engage_target = null
		_check_for_enemy()
		return
	if global_position.distance_to(_get_swarm_center()) > leash_range:
		engage_target = null
		_check_for_enemy()
		return
	var direction = (engage_target.global_position - global_position).normalized()
	var target_velocity = direction * engage_speed
	velocity = velocity.lerp(target_velocity, 0.25)
	move_and_slide()
	_play_moving_animation()

#Assigning new enemy target
func _on_attack_zone_body_entered(body):
	if not target_enemy and body.is_in_group("enemy"):
		start_attacking(body)
		
#Removing assigned enemy target
func _on_attack_zone_body_exited(body):
	if body == target_enemy:
		stop_attacking()
		
#Attacking enemy
func start_attacking(enemy):
	target_enemy = enemy
	engage_target = null
	attack_bounce_dir = Vector2(cos(randf_range(0, TAU)), sin(randf_range(0, TAU)))
	if has_node("AttackTimer"):
		$AttackTimer.start()

#Stopping attack
func stop_attacking():
	target_enemy = null
	if has_node("AttackTimer"):
		$AttackTimer.stop()
	_check_for_enemy()

#Checking to see if any enemies are in range
func _check_for_enemy():
	if target_enemy or engage_target:
		return
	if has_node("AttackZone"):
		for body in $AttackZone.get_overlapping_bodies():
			if is_instance_valid(body) and body.is_in_group("enemy"):
				if global_position.distance_to(_get_swarm_center()) <= leash_range:
					start_attacking(body)
				return
	if has_node("DetectionZone"):
		for body in $DetectionZone.get_overlapping_bodies():
			if is_instance_valid(body) and body.is_in_group("enemy"):
				if global_position.distance_to(_get_swarm_center()) <= leash_range:
					engage_target = body
				return

#Attack rate timer
func _on_attack_timer_timeout():
	if not is_instance_valid(target_enemy):
		stop_attacking()
		return
	if target_enemy.has_method("take_damage"):
		target_enemy.take_damage(attack_damage)

#Attacking movement
func _process_attack_movement(delta):
	#If there is no longer a target enemy, stop attacking
	if not is_instance_valid(target_enemy):
		stop_attacking()
		return
	#If the player moves far enough away, rodents stop attacking and rejoin the swarm
	if global_position.distance_to(_get_swarm_center()) > leash_range:
		stop_attacking()
		return
	#Swarming mechanics around an enemy
	var relative_pos = global_position - target_enemy.global_position
	var dist = relative_pos.length()
	
	if dist > attack_arena_radius:
		var normal = relative_pos.normalized()
		#Only reflect if still heading outward — prevents re-bouncing every frame
		if attack_bounce_dir.dot(normal) > 0:
			attack_bounce_dir = attack_bounce_dir.bounce(normal)
			if attack_bounce_dir.length() < 0.01:
				attack_bounce_dir = -normal
			else:
				attack_bounce_dir = attack_bounce_dir.rotated(randf_range(-0.3, 0.3)).normalized()
	
	velocity = attack_bounce_dir * attack_wander_speed
	move_and_slide()
	_play_moving_animation()

#Removing
func take_damage(amount):
	#Avoid two kills for one ally
	if is_queued_for_deletion():
		return
	health -= amount
	if health <= 0:
		_die()
		return
	if rodent_sprite:
		if hit_tween:
			hit_tween.kill()
		rodent_sprite.modulate = Color(3.212, 3.345, 3.207, 1.0)
		hit_tween = create_tween()
		hit_tween.tween_property(rodent_sprite, "modulate", Color(1, 1, 1, 1), .08)

func _die():
	if target_enemy:
		stop_attacking()
	if swarm_anchor and swarm_anchor.has_method("on_rodent_died"):
		swarm_anchor.on_rodent_died()
	queue_free()
	
	
	

#Placeholders rodent specific files execute
func _initialize_rodent(): pass
func _play_moving_animation(): pass
func _play_idle_animation(): pass
func start_magnet(swarm_member): swarm_anchor = swarm_member
