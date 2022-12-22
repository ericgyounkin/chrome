extends 'res://scripts/map/buildings/basebuilding.gd'


func _on_drugsbuilding_body_entered(body):
	handle_bodyent(body)

func _on_drugsbuilding_body_exited(body):
	handle_bodyexit(body)

func _on_drugsbuilding_area_entered(area):
	handle_areaent(area)

func _on_drugsbuilding_area_exited(area):
	handle_areaexit(area)
