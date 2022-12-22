extends Node

var parent = null
var npctype = ''

var current_state = null
var previous_state = null
var global_state = null

var wander_path = false

var targetpc = false
var tgt_pc = null
var tgt_timerinc = 0
var seekdist = 0
var seek_endpt = Vector2()

# passive npc = hangout for a sec, wander to nearby point, flee if someone shoots nearby
# undercover cop npc = hangout for a sec, wander to nearby point, shoot if someone else shoots


func _ready():
	parent = get_parent()
	npctype = parent.npctype
	current_state = funcref(self, 'wander')
	
func _process(delta):
	if parent.rage == true:
		global_state = funcref(self, 'berserk')
	elif parent.scared == true and parent.rage == false:
		wander_path = false
		parent.scared = false
		stopstatetimer()
		if npctype == 'undercover':
			global_state = funcref(self, 'shoot_at_shooter')
		else:
			global_state = funcref(self, 'flee')
	
		
func moveto(vect, spd, delta):
	if wander_path == false:
		parent.mousepos = vect
		parent.travel_dist = (parent.mousepos - parent.global_position).length()
		parent.rawvelocity = (parent.mousepos - parent.global_position).normalized()
		parent.update_navigation_path(parent.global_position, parent.mousepos)
		parent.moving = true
		wander_path = true
	var walkdist = spd * delta
	parent.move_along_path(walkdist)
	
func stopinplace(delta):
	if parent.moving:
		wander_path = false
		parent.mousepos = parent.global_position
		parent.moving = false
		
func seek(delta):
	var newdist = parent.global_position.distance_to(tgt_pc.global_position)
	if newdist > 150:
		if seek_endpt != Vector2():
			seek_endpt = Vector2()
		moveto(tgt_pc.global_position * 1.1, parent.move_speed, delta)
		if parent.moving == false:
			wander_path = false
	else:
		if seek_endpt == Vector2():
			seek_endpt = parent.global_position + (tgt_pc.global_position - parent.global_position).normalized() * 50
			wander_path = false
		moveto(seek_endpt, parent.move_speed / 2, delta)
		if parent.moving == false:
			wander_path = false

func startstatetimer():
	if $statetimer.is_stopped():
		$statetimer.wait_time = 999
		$statetimer.start()

func stopstatetimer():
	if !($statetimer.is_stopped()):
		$statetimer.stop()
		
func checktimer(time):
	if (999.0 - $statetimer.time_left) < time:
		return false
	else:
		return true

func find_shooting_pc_and_draw(draw):
	tgt_pc = null
	for n in get_tree().get_nodes_in_group('pc'):
		if n.shooting and n.health_points > 0:
			tgt_pc = n
			if draw and !parent.targeting:
				parent.set_targeting_mode(1)  # Assume they are only using slot1 weapon
			targetpc = true
			break
			
func find_shooting_person_and_draw(draw):
	tgt_pc = null
	for n in get_tree().get_nodes_in_group('players'):
		if n.shooting and n.health_points > 0:
			tgt_pc = n
			if draw and !parent.targeting:
				parent.set_targeting_mode(1)  # Assume they are only using slot1 weapon
			targetpc = true
			break

func find_closest_person_and_draw(draw):
	tgt_pc = null
	var charnodes = get_tree().get_nodes_in_group('players')
	charnodes.erase(parent)
	if charnodes != null:
		if draw and !parent.targeting:
			parent.set_targeting_mode(1)    # Assume they are only using slot1 weapon
		targetpc = true
		tgt_pc = charnodes[0]
		for n in charnodes:  # find closest person
			if n.global_position.distance_to(parent.global_position) < tgt_pc.global_position.distance_to(parent.global_position) and n.health_points > 0:
				tgt_pc = n
		if tgt_pc.health_points < 0:
			tgt_pc = null

func shoot_at_tgt_pc():
	parent.targeting_mousepos = tgt_pc.global_position
	parent.targetingdir = (parent.targeting_mousepos - parent.global_position).normalized()
	parent.set_slavetgtpos()
	parent.get_node('slot' + parent.activeslot).shoot()

func hang_out(delta):
	startstatetimer()
	var delay = rand_range(1,4)
	if checktimer(delay):
		stopstatetimer()
		previous_state = current_state
		current_state = funcref(self, 'wander')
		
func transition_to_hang_out():
	stopstatetimer()
	if parent.running:
		parent.running = false
		parent.set_slaverunning()
		parent.move_speed = parent.walk_speed
	if parent.shooting:
		parent.set_targeting_mode(1)
		parent.shooting = false
	parent.flee_direction = Vector2()
	targetpc = false
	global_state = null
	wander_path = false
	previous_state = current_state
	current_state = funcref(self, 'hang_out')

func wander(delta):
	startstatetimer()
	var offset_x = 0
	var offset_y = 0
	if wander_path == false:
		offset_x = rand_range(-400,400)
		offset_y = rand_range(-400,400)
	moveto(parent.global_position + Vector2(offset_x, offset_y), parent.move_speed, delta)
	if parent.moving == false:
		transition_to_hang_out()

		
func flee(delta):
	startstatetimer()
	parent.running = true
	parent.set_slaverunning()
	parent.move_speed = parent.run_speed
	moveto(parent.flee_direction, parent.move_speed, delta)
	if parent.moving == false:
		transition_to_hang_out()
		
func shoot_at_shooter(delta):
	startstatetimer()
	if targetpc == false:     # Find a target, do it once so you don't spend resources re-finding the shooter each delta
		parent.moving = false
		tgt_timerinc = rand_range(.5, 1)      # shoot half a second after finding
		find_shooting_person_and_draw(true)
	if tgt_pc != null:
		if tgt_pc.health_points > 0 and checktimer(tgt_timerinc):       #  shooter is still alive so keep shooting
			if is_network_master():
				shoot_at_tgt_pc()
				tgt_timerinc += rand_range(.3, 1)             #  vary shoot time to make it more realistic feeling
		elif tgt_pc.health_points == 0:       # shooter is dead
			print('shooterdead')
			stopstatetimer()
			tgt_pc = null
	else:         #  ending animation, holster gun and walk away
		startstatetimer()
		if checktimer(1):
			transition_to_hang_out()
			
func berserk(delta):
	if targetpc == false:     # Find a target, do it once so you don't spend resources re-finding the shooter each delta
		stopstatetimer()
		startstatetimer()
		wander_path = false
		tgt_timerinc = rand_range(.5, 1)      # shoot less than half a second after finding
		find_closest_person_and_draw(true)
		if tgt_pc:
			print('foundtarget %s' % tgt_pc.name)
	if tgt_pc != null:
		seek(delta)   # Follow around tgt_pc
		if tgt_pc.health_points > 0 and checktimer(tgt_timerinc):       #  shooter is still alive so keep shooting
			if is_network_master():
				shoot_at_tgt_pc()
				tgt_timerinc += rand_range(.3, 1)             #  vary shoot time to make it more realistic feeling
		elif tgt_pc.health_points == 0:       # shooter is dead
			targetpc = false
	else:         #  ending animation, holster gun and walk away
		startstatetimer()
		if checktimer(1):
			transition_to_hang_out()
		