extends KinematicBody2D

export(float) var SPEED = 80
export(float) var DAMAGE = 15

var col = null
var velocity = Vector2()

func _ready():
	add_collision_exception_with(get_parent().get_parent())
	add_to_group('bullet')
	set_as_toplevel(true)

func _process(delta):
	col = move_and_collide(velocity)
	if col:
		if !col.collider.is_a_parent_of(self):
			if col.collider.has_method('damage') and !col.collider.is_a_parent_of(self):
				col.collider.damage(DAMAGE, global_position)
			elif col.collider.get_parent().has_method('damage'):
				col.collider.get_parent().damage(DAMAGE, global_position)
			if col.collider.has_method('set_scared'):
				var fleedir = velocity.normalized()
				if get_tree().is_network_server():
					col.collider.set_scared(col.collider.global_position + (fleedir * 2000))
				else:
					rpc_id(1, 'set_npc_scared', col.collider.name, col.collider.global_position + (fleedir * 2000))
		queue_free()

remote func set_npc_scared(nme, fleedir):
	var npcs = get_tree().get_nodes_in_group('npc')
	for n in npcs:
		if n.name == nme:
			n.set_scared(fleedir)
			break

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
