extends Area2D

const building_hit = preload('res://scenes/items/effects/building_hit.tscn')
var buildinghit = null
var playerhiddencount = 0


func _ready():
	$base.add_to_group('building')
	

func handle_bodyent(body):
	if body.is_in_group('players'):
		playerhiddencount += 1
		if playerhiddencount == 1:
			$Tween.interpolate_property($Sprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Tween.start()
		$Tween2.interpolate_property(body, "modulate", Color(1, 1, 1, 1), Color(0, 0, 0, 0.2), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween2.start()
	elif body.is_in_group('bullet'):
		body.z_index = 0
		
func handle_bodyexit(body):
	if body.is_in_group('players'):
		playerhiddencount -= 1
		if playerhiddencount == 0:
			$Tween.interpolate_property($Sprite, "modulate", Color(1, 1, 1, 0.5), Color(1, 1, 1, 1), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Tween.start()
		$Tween2.interpolate_property(body, "modulate", Color(0, 0, 0, 0.2), Color(1, 1, 1, 1), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween2.start()
	elif body.is_in_group('bullet'):
		body.z_index = 1
		
func handle_areaent(area):
	area.z_index = 0
		
func handle_areaexit(area):
	area.z_index = 1
		
func damage(dmg, pos):
	buildinghit = building_hit.instance()
	add_child(buildinghit)
	buildinghit.global_position = pos
	$hiteffect.start()

func _on_hiteffect_timeout():
	buildinghit.queue_free()
	$hiteffect.stop()
	