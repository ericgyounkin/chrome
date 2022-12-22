extends Particles2D

var bloodpoolloc = Vector2()
var bloodpool = load('res://scenes/sprites/blood_pool.tscn')
var startloc = Vector2()
var flip = false

func init(poolloc, stloc, fl):
	bloodpoolloc = poolloc
	position = stloc
	if fl:
		scale = Vector2(-1,1)
	emitting = true
	$pooltimer.start()

func _on_pooltimer_timeout():
	var poolinst = bloodpool.instance()
	poolinst.global_position = bloodpoolloc
	$poolholder.add_child(poolinst)
	var newscale = Vector2(rand_range(0.03, 0.13), rand_range(0.03, 0.13))
	$Tween.interpolate_property(poolinst, "scale", Vector2(0.01, 0.01), newscale, 0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()
	$hidepool.start()

func _on_hidepool_timeout():
	queue_free()
