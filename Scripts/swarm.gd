extends CharacterBody2D

var speed = 150.0
var bubble_radius = 30.0
var current_swarm_size = 1
#Current highest tier of rodent possible, 1: Mouse, 2: Rat, 3: Squirrel, 4:Guinea Pig
var swarm_level = 1
var food_meter_amount = 0
var max_food_needed = 100.0

#Movement variables
var input_direction: Vector2 = Vector2.ZERO
var click_position: Vector2 = Vector2.ZERO
var distance_to_target: float = 0.0
var direction: Vector2 = Vector2.ZERO

@export var mouse_assets = load("res://Scenes/mouse_ally.tscn")
@export var rat_assets = load("res://Scenes/rat_ally.tscn")
@export var squirrel_assets = load("res://Scenes/squirrel_ally.tscn")
@export var guinea_assets = load("res://Scenes/guinea_ally.tscn")
@onready var food_meter = get_parent().get_node("UI").get_node("FoodMeter")

func _ready():
	update_swarm_border()
	
	if has_node("PlayerSprite"):
		$PlayerSprite.play("player_indicator")
		
	call_deferred("spawn_starting_rodent")
	
func spawn_starting_rodent():
	var starting_rodent = mouse_assets.instantiate()
	get_parent().add_child(starting_rodent)
	starting_rodent.global_position = global_position
	starting_rodent.start_magnet(self)

func _physics_process(_delta):
	#if has_node("PlayerSprite"):
		#$PlayerSprite.play("player_indicator")
	get_parent().get_node("UI").get_node("Label").text = str(int(food_meter_amount))
	
	#Handling keyboard and click movement input
	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		click_position = get_global_mouse_position()
		$PlayerSprite.global_position = click_position
	
	#Keyboard movement
	if input_direction != Vector2.ZERO:
		click_position = global_position
		velocity = input_direction * speed
		$PlayerSprite.global_position = global_position
		$PlayerSprite.play("player_indicator")
	#Click/no movement
	else:
		distance_to_target = global_position.distance_to(click_position)
		#Click
		if distance_to_target > 5.0:
			direction = (click_position - global_position).normalized()
			velocity = direction * speed
			$PlayerSprite.play("player_indicator_blink")
		#No movement
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed)
			$PlayerSprite.play("player_indicator")
	
	move_and_slide()

func on_food_collected(food_value):
	max_food_needed = 100.0 * pow(1.05, current_swarm_size)
	food_meter_amount += food_value
	while food_meter_amount >= max_food_needed:
		food_meter_amount -= max_food_needed
		current_swarm_size += 1
		bubble_radius += 5.0
		update_swarm_border()
		max_food_needed = 100.0 * pow(1.05, current_swarm_size)
		
		if current_swarm_size >= 18 and swarm_level < 4:
			swarm_level = 4
			speed = 195.0
			spawn_new_rodent(guinea_assets)
			if has_node("MainCamera"):
				$MainCamera.zoom_out_for_new_rodent()
		elif current_swarm_size >= 12 and swarm_level < 3:
			swarm_level = 3
			speed = 185.0
			spawn_new_rodent(squirrel_assets)
			if has_node("MainCamera"):
				$MainCamera.zoom_out_for_new_rodent()
		elif current_swarm_size >= 6 and swarm_level < 2:
			swarm_level = 2
			speed = 175.0
			spawn_new_rodent(rat_assets)
			if has_node("MainCamera"):
				$MainCamera.zoom_out_for_new_rodent()
		else:
			#Spawning new ally
			match swarm_level:
				1: spawn_new_rodent(mouse_assets)
				2: spawn_new_rodent(rat_assets)
				3: spawn_new_rodent(squirrel_assets)
				4: spawn_new_rodent(guinea_assets)
			
	#Setting meter to leftover and new max
	food_meter.max_value = max_food_needed
	food_meter.value = food_meter_amount

func spawn_new_rodent(rodent_assets):
	var new_rodent = rodent_assets.instantiate()
	new_rodent.global_position = get_random_offscreen_position()
	get_parent().call_deferred("add_child", new_rodent)
	new_rodent.start_magnet(self)

func on_rodent_died():
	current_swarm_size =- 1
	bubble_radius = max(bubble_radius - 5.0, 30.0)
	update_swarm_border()

func update_swarm_border():
	var border_shape = get_node_or_null("SwarmBorder/SwarmBorderCollision")
	if border_shape and border_shape.shape is CircleShape2D:
		border_shape.shape.set_deferred("radius", bubble_radius)
	
#Finding offscreen spot for new follower
func get_random_offscreen_position() -> Vector2:
	var camera = get_node_or_null("MainCamera")
	if not camera:
		return global_position + Vector2(randf_range(-400, 400), randf_range(-400, 400))
		
	var screen_center = camera.get_screen_center_position()
	var viewport_size = get_viewport().get_visible_rect().size / camera.zoom
	var half = viewport_size / 2.0
	
	var random_angle = randf_range(0, 2 * PI)
	var dir = Vector2(cos(random_angle), sin(random_angle))
	
	#Find exact edge intersection for this angle, then add buffer
	var scale_x = abs(half.x / dir.x) if dir.x != 0 else INF
	var scale_y = abs(half.y / dir.y) if dir.y != 0 else INF
	var edge_scale = min(scale_x, scale_y)
	
	var offscreen_pos = screen_center + dir * (edge_scale + 40.0)
	
	return offscreen_pos
			
