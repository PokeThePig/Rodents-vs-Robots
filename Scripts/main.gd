extends Node2D

@onready var base_grass_layer = $Grass
@onready var swarm = $Swarm
@onready var berry_assets = load("res://Scenes/berry.tscn")
@onready var sunflower_assets = load("res://Scenes/sunflowerseeds.tscn")
@onready var spiderling_assets = load("res://Scenes/spiderling.tscn")
@onready var sphere_assets = load("res://Scenes/sphere.tscn")

const MAP_WIDTH = 1000
const MAP_HEIGHT = 1000
const SOURCE_ID = 0 
const TILE_SIZE = 16
const BACKGROUND_TILES = 22
var rng = RandomNumberGenerator.new()
var current_food = null

#Rates for map generation
const TILE_WEIGHTS = [
	750.0, 1.0, 1.0, 1.0, 1.0, 30.0, 30.0, 30.0, 30.0, 30.0,
	30.0, 30.0, 30.0, 30.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0,
	5.0, 5.0
]

func _ready():
	rng.seed = 54321
	generate_seeded_map()

#Generating map
func generate_seeded_map():
	var total_weight = 0.0
	for w in TILE_WEIGHTS:
		total_weight += w
		
	var half_width = MAP_WIDTH / 2.0
	var half_height = MAP_HEIGHT / 2.0
	
	#1. Paint the terrain layout
	for x in range(-half_width, half_width):
		for y in range(-half_height, half_height):
			var coords = Vector2i(x, y)
			
			var rolled_weight = rng.randf_range(0.0, total_weight)
			var chosen_tile_atlas = Vector2i(0, 0)
			var current_weight_sum = 0.0
			
			for i in range(BACKGROUND_TILES):
				current_weight_sum += TILE_WEIGHTS[i]
				if rolled_weight <= current_weight_sum:
					chosen_tile_atlas = Vector2i(i, 0)
					break
			
			base_grass_layer.set_cell(coords, SOURCE_ID, chosen_tile_atlas)
			
	#2. Spawn initial food items
	for i in range(1000):
		var random_tile_x = randi_range(-half_width, half_width - 1)
		var random_tile_y = randi_range(-half_height, half_height - 1)
		
		var random_world_position = Vector2(random_tile_x * TILE_SIZE + (TILE_SIZE / 2.0), random_tile_y * TILE_SIZE + (TILE_SIZE / 2.0))
		
		if randf() < 0.5:
			current_food = berry_assets.instantiate()
		else:
			current_food = sunflower_assets.instantiate()
			
		current_food.global_position = random_world_position
		add_child(current_food)

#Spawning food items just outside of view (Tier 1)
func _on_tier_one_food_spawner_timeout():
	if not swarm:
		return
		
	var random_angle = randf_range(0.0, 2 * PI)
	var spawn_distance = randf_range(700.0, 900.0)
	var spawn_offset = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	
	if randf() < 0.5:
		current_food = berry_assets.instantiate()
	else:
		current_food = sunflower_assets.instantiate()
		
	current_food.global_position = swarm.global_position + spawn_offset
	add_child(current_food)

func _on_enemy_spawner_timeout():
	if not swarm:
		return
	
	var random_angle = randf_range(0.0, 2 * PI)
	var spawn_distance = randf_range(700.0, 900.0)
	var spawn_offset = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	
	var new_enemy
	if randf() < 0.5:
		new_enemy = spiderling_assets.instantiate()
	else:
		new_enemy = sphere_assets.instantiate()
	new_enemy.global_position = swarm.global_position + spawn_offset
	add_child(new_enemy)
	new_enemy.set_swarm_anchor(swarm)
