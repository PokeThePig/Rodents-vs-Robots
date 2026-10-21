extends Resource
class_name LevelTable

@export var max_level = 3
@export var base_food = 100
@export var growth_factor = 1.12
@export var quadratic_multiplier = 1.0

func food_to_next(level):
	if level < 1:
		level = 1
		
	var food = base_food * pow(level, 2) * pow(growth_factor, level - 1) * quadratic_multiplier
	return int(round(food))
	
func total_food_for_level(target_level):
	var total = 0 
