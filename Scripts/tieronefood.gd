extends Area2D

var food_value = 60
var eat_distance = 10.0
var magnet_speed = 300.0
var magnet_target = null
var start_distance = 0.0

func _ready():
	#Determining food item
	if has_node("BerrySprite"):
		$BerrySprite.play("berries")
		food_value = 60
	elif has_node("SunflowerSprite"):
		$SunflowerSprite.play("seeds")
		food_value = 75
		
	if has_node("MagnetArea"):
		$MagnetArea.body_entered.connect(magnet_zone_entered)
	
func _process(delta):
	if magnet_target and not is_instance_valid(magnet_target):
		magnet_target = null
		start_distance = 0.0
		_find_new_magnet_target()
	if not magnet_target:
		return
	
	#Handling magnetism
	var distance = global_position.distance_to(magnet_target.global_position)
	if start_distance == 0.0:
		start_distance = distance
	var direction = (magnet_target.global_position - global_position).normalized()
	global_position += direction * delta * magnet_speed
	
	#Handling changing size during magnetism
	var progress = clamp(1.0 - (distance / start_distance), 0.0, 1.0)
	var base_scale = lerp(2.0, 0.8, progress)
	var pop_amount = sin(progress * PI) * 0.6
	var final_scale = base_scale + pop_amount
	scale = Vector2(final_scale, final_scale)

#Starting magnetism towards rodent
func magnet_zone_entered(swarm_member):
	if magnet_target == null && swarm_member.is_in_group("rodent"):
		magnet_target = swarm_member
		start_distance = 0.0

#Eating food handled
func _on_area_entered(area):
	if area.is_in_group("rodent_collection"):
		if is_instance_valid(magnet_target) and magnet_target.swarm_anchor:
			if magnet_target.swarm_anchor.has_method("on_food_collected"):
				magnet_target.swarm_anchor.on_food_collected(food_value)
			queue_free()

#Location new target if the original rodent grabbing food dies
func _find_new_magnet_target():
	if not has_node("MagnetArea"):
		return
	for body in $MagnetArea.get_overlapping_bodies():
		if is_instance_valid(body) and body.is_in_group("rodent"):
			magnet_target = body
			start_distance = 0.0
			return
	
