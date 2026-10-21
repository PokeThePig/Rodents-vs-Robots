extends CharacterBody2D

#Combat values
var max_health = 30.0
var health = 30.0
var speed = 100.0
var contact_damage = 5.0
var attack_rate = 1.0
var attack_range = 25.0
var attack_target = null
var hit_tween = null

#Visuals
var enemy_sprite = null
var destination = null
var swarm_anchor = null

func _ready():
	add_to_group("enemy")
	_initialize_enemy()
	health = max_health
	
	for child in get_children():
		if child is AnimatedSprite2D:
			enemy_sprite = child
			break
			
	if has_node("AttackTimer"):
		$AttackTimer.wait_time = attack_rate
		$AttackTimer.timeout.connect(_on_attack_timer_timeout)
		$AttackTimer.start()

func _physics_process(_delta):
	#Check if rodent still exists, otherwise set a new target
	if not _target_is_valid():
		attack_target = _pick_closest_rodent()
	#If a target exists, continue towards it
	if attack_target:
		destination = attack_target.global_position
	#If no target exists, move towards swarm anchor
	elif is_instance_valid(swarm_anchor):
		destination = swarm_anchor.global_position
	else:
		return
	#Start moving
	velocity = (destination - global_position).normalized() * speed
	move_and_slide()
	_play_moving_animation()

#Making sure rodent being chased still exists
func _target_is_valid():
	return (is_instance_valid(attack_target) and not attack_target.is_queued_for_deletion())

func _pick_closest_rodent():
	var closest_rodent = null
	var closest_dist = INF
	for rodent in get_tree().get_nodes_in_group("rodent"):
		#Pass on rodents currently dying
		if rodent.is_queued_for_deletion():
			continue
		var dist = global_position.distance_squared_to(rodent.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_rodent = rodent
	return closest_rodent

#Receiving damage from rodents
func take_damage(amount):
	#Avoid dying twice
	if is_queued_for_deletion():
		return
	health -= amount
	if health <= 0:
		_die()
		return
	#Flashing sprite when hit
	if enemy_sprite:
		if hit_tween:
			hit_tween.kill()
		enemy_sprite.modulate = Color(10,10,10,10)
		hit_tween = create_tween()
		hit_tween.tween_property(enemy_sprite, "modulate", Color(1,1,1,1), 0.08)
		
func _on_attack_timer_timeout():
	attack_target = _pick_closest_rodent()
	#Avoid attacking dead rodent
	if not _target_is_valid():
		return
	if global_position.distance_to(attack_target.global_position) <= attack_range:
		attack_target.take_damage(contact_damage)

#Despawn enemy
func _die():
	queue_free()

#Begin moving towards rodent
func set_swarm_anchor(anchor):
	swarm_anchor = anchor
	
#Placeholders for enemy specific files override
func _initialize_enemy(): pass
func _play_moving_animation(): pass
