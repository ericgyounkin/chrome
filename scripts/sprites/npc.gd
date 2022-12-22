extends 'res://scripts/sprites/character.gd'

var scared = false
var rage = false
var flee_direction = Vector2()
var goto_dir = Vector2()

var npctype = ''


func _ready():
	add_to_group('npc')
	if npctype in ['undercover', 'berserk']:
		equip = ['pistol', '', '', '', '']
		load_slots()
		if npctype == 'berserk':
			rage = true

func _process(delta):
	if is_network_master():
		animationdirs = get_animation_dirs()
		handle_targeting_anim(animationdirs[0], animationdirs[1], animationdirs[2], animationdirs[3], animationdirs[4])
		if mousepos != slave_mousepos:
			rset('slave_mousepos', mousepos)
		if position != slave_position:
			rset_unreliable('slave_position', position)
		if animationdirs != slave_animationdirs:
			rset('slave_animationdirs', animationdirs)
	else:
		travel_dist = (slave_mousepos - global_position).length()
		targeting_mousepos = slave_targeting_mousepos
		position = slave_position
		targeting = slavetargeting
		settingtargeting = slave_settingtargeting
		activeslot = slave_activeslot
		shooting = slave_shooting
		running = slave_running
		velocity = (slave_mousepos - global_position).normalized() * move_speed
		if activeslot != '0':
			get_node('slot' + activeslot).visible = targeting
		handle_targeting_anim(slave_animationdirs[0], slave_animationdirs[1], slave_animationdirs[2], slave_animationdirs[3], slave_animationdirs[4])

func _physics_process(delta):
	if is_network_master():
		if $state_machine.global_state != null:
			$state_machine.global_state.call_func(delta)
		elif $state_machine.current_state != null:
			$state_machine.current_state.call_func(delta)

#func _die():
#	queue_free()
	
func set_slavetgtpos():
	rset('slave_targeting_mousepos', targeting_mousepos)
	
func set_slaverunning():
	rset('slave_running', running)
	
func set_scared(fleedir):
	flee_direction = fleedir
	scared = true