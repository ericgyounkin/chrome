extends KinematicBody2D

var equip = []
var activeslot = '0'
slave var slave_activeslot = '0'

const max_hp = 100
var health_points = max_hp
var move_speed = 100
var run_speed = 300
var walk_speed = 100

var skip_extra_wheel = true

var person_hit = preload('res://scenes/sprites/blood_spray.tscn')

var navinst = null
var navpath = []

var default_cursor = load('res://art/interface/default_cursor.png')
var target_cursor = load('res://art/interface/target_cursor.png')
var settingtargeting = false
var targeting = false
slave var slavetargeting = false
var mousecursordif = Vector2()

var moving = false
var running = false

var uphead = load('res://art/sprites/char1_rig_head_up.png')
var uphair = load('res://art/sprites/char1_rig_hair_up.png')
var uprighthead = load('res://art/sprites/char1_rig_head_upright.png')
var uprighthair = load('res://art/sprites/char1_rig_hair_upright.png')

var movedist = Vector2()
var mousepos = Vector2()
var targeting_mousepos = Vector2()
var targetingdir = Vector2()
var rawvelocity = Vector2()
var velocity = Vector2()
var travel_dist = 0
var animationdirs = ['', '', false, false, false]
var prior_dir = 'down'
var prior_subdir = 'left'
var prior_animation = false
var prior_running = false
var initialize_animation = true
var visiblerig = ''
var shooting = false
var down_up_threshold = 0.4   # deviation from x axis to trigger down or up animation vs down-right, up-right, etc.

slave var slave_position = Vector2()
slave var slave_mousepos = Vector2()
slave var slave_targeting_mousepos = Vector2()
slave var slave_animationdirs = ['', '', false, false, false]
slave var slave_settingtargeting
slave var slave_shooting = false
slave var slave_running = false

var spriteheight = 164
var left_offsets = [Vector2(0,0), Vector2(-8,-3), Vector2(-8,-3), Vector2(-8,-3), Vector2(0,0), Vector2(-9,-4), Vector2(-1,-4), Vector2(-9,-4)]
var right_offsets = [Vector2(0,0), Vector2(7,-2), Vector2(9,-1), Vector2(7,-2), Vector2(0,0), Vector2(8,-4), Vector2(9,-4), Vector2(8,-4)]
var straightdown_offsets = [Vector2(0,0), Vector2(7,-2), Vector2(9,-1), Vector2(7,-2), Vector2(0,0), Vector2(8,-4), Vector2(9,-4), Vector2(8,-4)]
var straightup_offsets = [Vector2(0,0), Vector2(7,-2), Vector2(9,-1), Vector2(7,-2), Vector2(0,0), Vector2(8,-4), Vector2(9,-4), Vector2(8,-4)]
var twistleft_offsets = [Vector2(0,0), Vector2(7,-2), Vector2(9,-1), Vector2(7,-2), Vector2(0,0), Vector2(8,-4), Vector2(9,-4), Vector2(8,-4)]
var twistright_offsets = [Vector2(0,0), Vector2(7,-2), Vector2(9,-1), Vector2(7,-2), Vector2(0,0), Vector2(8,-4), Vector2(9,-4), Vector2(8,-4)]
var frameoffsets = left_offsets


func cartesian_to_isometric(cartesian):
	var screen_pos = Vector2()
	screen_pos.x = cartesian.x - cartesian.y
	screen_pos.y = (cartesian.x + cartesian.y) / 2
	return screen_pos

func _ready():
	Input.set_custom_mouse_cursor(default_cursor)
	$AnimatedSprite.playing = false
	$AnimatedSprite.frame = 0
	if has_method('_update_health_bar'):
		_update_health_bar()
	navinst = get_tree().get_nodes_in_group('activenav')[0]
	

func load_slots():
	var slot = null
	var indx = 0
	for e in equip:
		indx += 1
		if e:
			slot = load('res://scenes/items/weapons/' + e + '.tscn').instance()
			slot.set_name('slot' + str(indx))
			slot.flip_h = true
			if name.substr(0,1) != 'n':
				slot.set_network_master(int(name))
			slot.visible = false
			add_child(slot)
	if slot != null:
		activeslot = slot.name.substr(4,1)
		rset('slave_activeslot', activeslot)


func set_targeting_mode(mode):
	var crsr = default_cursor
	var crsrdif = Vector2()
	settingtargeting = true
	rset('slave_settingtargeting', settingtargeting)
	if targeting:
		# turn off targeting, you holster the weapon you have out
		if $AnimatedSprite.animation in ['downpistol', 'downtwistleftpistol', 'downtwistrightpistol']:
			$AnimatedSprite.animation = 'down'
		elif $AnimatedSprite.animation in ['uppistol', 'uptwistleftpistol', 'uptwistrightpistol']:
			$AnimatedSprite.animation = 'up'
		elif $AnimatedSprite.animation == 'straightdownpistol':
			$AnimatedSprite.animation = 'straightdown'
		elif $AnimatedSprite.animation == 'straightuppistol':
			$AnimatedSprite.animation = 'straightup'
		targeting = false
	elif mode and has_node('slot' + str(mode)):
		# turn on targeting or change weapons
		crsr = target_cursor
		crsrdif = Vector2(16,16) 
		if $AnimatedSprite.animation == 'down':
			$AnimatedSprite.animation = 'downpistol'
		elif $AnimatedSprite.animation == 'up':
			$AnimatedSprite.animation = 'uppistol'
		elif $AnimatedSprite.animation == 'straightdown':
			$AnimatedSprite.animation = 'straightdownpistol'
		elif $AnimatedSprite.animation == 'straightup':
			$AnimatedSprite.animation = 'straightuppistol'
		activeslot = str(mode)
		var slt = get_node('slot' + activeslot)
		if has_method('update_guiammo'):
			update_guiammo(slt.ammo)
		targeting = true
	rset('slave_activeslot', activeslot)
	rset('slavetargeting', targeting)
	Input.set_custom_mouse_cursor(crsr)
	mousecursordif = crsrdif
	$AnimatedSprite.offset = frameoffsets[$AnimatedSprite.frame]

func update_navigation_path(startpos, endpos):
	navpath = navinst.get_simple_path(startpos, endpos, true)
	navpath.remove(0)
	moving = true
	
func move_along_path(dist):
	var last_point = global_position
	for ind in range(navpath.size()):
		var distance_between_points = last_point.distance_to(navpath[0])
		if dist <= distance_between_points:
			global_position = last_point.linear_interpolate(navpath[0], dist / distance_between_points)
			break
		elif dist < 0:
			global_position = navpath[0]
			break
		dist -= distance_between_points
		last_point = navpath[0]
		navpath.remove(0)
		if !navpath.size():
			moving = false
	if targeting and activeslot != '0':
		get_node('slot' + activeslot).visible = true

func get_animation_dirs():
	# set animation parameters list [main direction, subdirection, flip weapon boolean, play walking animation boolean, stop moving boolean]
	var playanim = true
	if !moving:
		playanim = false
		if (targetingdir.x > -down_up_threshold and targetingdir.x < down_up_threshold) and targetingdir.y < 0: # shoot up
			return ['straightup', 'straightup', true, playanim, true]
		elif targetingdir.x <= down_up_threshold and targetingdir.y < 0: # shoot up left
			return ['up', 'left', true, playanim, true]
		elif targetingdir.x >= down_up_threshold and targetingdir.y < 0: # shoot up right
			return ['up', 'right', true, playanim, true]
		elif (targetingdir.x > -down_up_threshold and targetingdir.x < down_up_threshold) and targetingdir.y > 0: # shoot down
			return ['straightdown', 'straightdown', false, playanim, true]
		elif targetingdir.x <= down_up_threshold and targetingdir.y > 0: # shoot down left
			return ['down', 'left', true, playanim, true]
		elif targetingdir.x >= down_up_threshold and targetingdir.y > 0: # shoot down right
			return ['down', 'right', false, playanim, true]
		else:
			return ['', '', null, playanim, true]
	elif (rawvelocity.x < down_up_threshold and rawvelocity.x > -down_up_threshold) and rawvelocity.y > 0: # moving down
		if (targetingdir.x > -down_up_threshold and targetingdir.x < down_up_threshold) and targetingdir.y < 0 and shooting: # if you shoot up, stop and turn up
			#print('fliptoup')
			return ['straightup', 'straightup', true, playanim, true]
		elif targetingdir.x <= down_up_threshold and targetingdir.y < 0 and shooting: # if you shoot up left, stop and turn up left
			#print('fliptoupleft')
			return ['up', 'left', true, playanim, true]
		elif targetingdir.x >= down_up_threshold and targetingdir.y < 0 and shooting: # if you shoot up right, stop and turn up right
			#print('fliptoupright')
			return ['up', 'right', true, playanim, true]
		else: # just walk down like normal
			#print('straightdown')
			return ['straightdown', 'straightdown', false, playanim, false]
	elif (rawvelocity.x < down_up_threshold and rawvelocity.x > -down_up_threshold) and rawvelocity.y < 0: # moving up 
		if (targetingdir.x > -down_up_threshold and targetingdir.x < down_up_threshold) and targetingdir.y > 0 and shooting: # if you shoot down, stop and turn down (for what)
			#print('fliptodown')
			return ['straightdown', 'straightdown', false, playanim, true]
		elif targetingdir.x <= down_up_threshold and targetingdir.y > 0 and shooting: # if you shoot down left, stop and turn down left
			#print('fliptodownleft')
			return ['down', 'left', true, playanim, true]
		elif targetingdir.x >= down_up_threshold and targetingdir.y > 0 and shooting: # if you shoot down right, stop and turn down right
			#print('fliptodownright')
			return ['down', 'right', false, playanim, true]
		else: # otherwise just move up as normal
			#print('straightup')
			return ['straightup', 'straightup', true, playanim, false]
	elif rawvelocity.x > 0 and rawvelocity.y > 0:  # moving down and right
		if (targetingdir.x > -down_up_threshold and targetingdir.x < down_up_threshold) and targetingdir.y < 0 and shooting: # if you shoot up, stop and shoot up
			#print('fliptoup')
			return ['straightup', 'straightup', true, playanim, true]
		elif targetingdir.x <= down_up_threshold and targetingdir.y < 0 and shooting: # if you shoot up left, stop and turn up left
			#print('fliptoupleft')
			return ['up', 'left', true, playanim, true]
		elif targeting and targetingdir.x < 0 and targetingdir.y > 0: # if you shoot right of down-right, twist
			#print('downtwistright')
			return ['down', 'rtwistleft', true, playanim, false]  # These twists are backwards because the animation is downleft and flipped!
		elif targeting and targetingdir.x > -down_up_threshold and targetingdir.y < 0: # if you shoot left of down-right, twist
			#print('downtwistleft')
			return ['down', 'rtwistright', false, playanim, false]  # These twists are backwards because the animation is downleft and flipped!
		else:
			#print('downright') # move down right as normal
			return ['down', 'right', false, playanim, false]
	elif rawvelocity.x < 0 and rawvelocity.y > 0: # moving down and left
		if (targetingdir.x > -down_up_threshold and targetingdir.x < down_up_threshold) and targetingdir.y < 0 and shooting:
			#print('fliptoup')
			return ['straightup', 'straightup', true, playanim, true]
		elif targetingdir.x >= down_up_threshold and targetingdir.y < 0 and shooting:
			#print('fliptoupright')
			return ['up', 'right', true, playanim, true]
		elif targeting and targetingdir.x > -down_up_threshold and targetingdir.y > 0:
			#print('downtwistleft')
			return ['down', 'ltwistleft', false, playanim, false]
		elif targeting and targetingdir.x < 0 and targetingdir.y < 0:
			#print('downtwistright')
			return ['down', 'ltwistright', true, playanim, false]
		else:
			#print('downleft')
			return ['down', 'left', true, playanim, false]
	elif rawvelocity.x > 0 and rawvelocity.y < 0:  # moving up and right
		if (targetingdir.x > -down_up_threshold and targetingdir.x < down_up_threshold) and targetingdir.y > 0 and shooting:
			#print('fliptodown')
			return ['straightdown', 'straightdown', false, playanim, true]
		elif targetingdir.x <= down_up_threshold and targetingdir.y > 0 and shooting:
			#print('fliptodownleft')
			return ['down', 'left', true, playanim, true]
		elif targeting and targetingdir.x < down_up_threshold and targetingdir.y < 0:
			#print('uptwistleft')
			return ['up', 'rtwistleft', true, playanim, false]
		elif targeting and targetingdir.x > 0 and targetingdir.y > 0:
			#print('uptwistright')
			return ['up', 'rtwistright', false, playanim, false]
		else:
			#print('upright')
			return ['up', 'right', false, playanim, false]
	else:  # moving up and left
		if (targetingdir.x > -down_up_threshold and targetingdir.x < down_up_threshold) and targetingdir.y > 0 and shooting:
			#print('fliptodown')
			return ['straightdown', 'straightdown', false, playanim, true]
		elif targetingdir.x >= down_up_threshold and targetingdir.y > 0 and shooting:
			#print('fliptodownright')
			return ['down', 'right', false, playanim, true]
		elif targeting and targetingdir.x < 0 and targetingdir.y > 0:
			#print('uptwistright')
			return ['up', 'ltwistright', true, playanim, false]  # These twists are backwards because the animation is upright and flipped!
		elif targeting and targetingdir.x > -down_up_threshold and targetingdir.y < 0:
			#print('uptwistleft')
			return ['up', 'ltwistleft', false, playanim, false]  # These twists are backwards because the animation is upright and flipped!
		else:
			#print('upleft')
			return ['up', 'left', true, playanim, false]

sync func handle_targeting_anim(dir, subdir, flip, animationplaying, stopsig):
	# downleftwalktwistleft - charrigheaddown, hairdown
	#uprightwalkpistoltwistright - charrigheaddownright (flipped), hairdownright
	var wpnclass = ''
	var animprefix = ''
	var subdircat = ''
	var activenode = ''
	if activeslot != '0':
		if is_network_master():
			activenode = get_node('slot' + activeslot)
		else:
			activenode = get_node('slot' + slave_activeslot)
	if !dir and !subdir:
		var tempsubdir = prior_subdir
		if tempsubdir in ['rtwistright', 'rtwistleft']:
			tempsubdir = 'right'
		elif tempsubdir in ['ltwistleft', 'ltwistright']:
			tempsubdir = 'left'
		dir = prior_dir
		subdir = tempsubdir
		if initialize_animation:
			prior_subdir = ''   # reset prior_subdir so that it triggers the animation stuff on first start
			initialize_animation = false
	if !(subdir in ['right', 'left', 'straightup', 'straightdown']): 
		subdircat = subdir.substr(1,len(subdir))  # decode the l or r prefix to get raw subdirection
	else:
		subdircat = subdir
	if targeting:
		if activenode.guntype in ['onehandgun']:
			wpnclass = 'pistol'
	if dir == 'straightdown':
		if dir != prior_dir or subdir != prior_subdir or prior_animation != animationplaying or prior_running != running or settingtargeting:
		#if !((($AnimationPlayer.get_current_animation() == 'down') and !animationplaying) or (($AnimationPlayer.get_current_animation() == 'downwalk') and animationplaying)) or settingtargeting:
			if activenode:
				activenode.hide()
			$downleftrig.visible = false
			$uprightrig.visible = false
			$uprig.visible = false
			$downrig.visible = true
			visiblerig = 'downrig'
			if running:
				animprefix = 'downrun'
			else:
				animprefix = 'downwalk'
			#print(dir, subdir)
			if animationplaying:
				if targeting:
					var anim = animprefix + wpnclass
					$AnimationPlayer.play(anim)
				else:
					$AnimationPlayer.play(animprefix)
			else:
				if targeting:
					$AnimationPlayer.play("downpistol")
					activenode.show()
				else:
					$AnimationPlayer.play("down")
	elif dir == 'straightup':
		if dir != prior_dir or subdir != prior_subdir or prior_animation != animationplaying or prior_running != running or settingtargeting:
		#if !((($AnimationPlayer.get_current_animation() == 'up') and !animationplaying) or (($AnimationPlayer.get_current_animation() == 'upwalk') and animationplaying)) or settingtargeting:
			if activenode:
				activenode.hide()
			$downleftrig.visible = false
			$uprightrig.visible = false
			$uprig.visible = true
			$downrig.visible = false
			visiblerig = 'uprig'
			if running:
				animprefix = 'uprun'
			else:
				animprefix = 'upwalk'
			#print(dir, subdir)
			if animationplaying:
				if targeting:
					var anim = animprefix + wpnclass
					$AnimationPlayer.play(anim)
				else:
					$AnimationPlayer.play(animprefix)
			else:
				if targeting:
					$AnimationPlayer.play("uppistol")
					activenode.show()
				else:
					$AnimationPlayer.play("up")
	elif dir == 'up':
		if dir != prior_dir or subdir != prior_subdir or prior_animation != animationplaying or prior_running != running or settingtargeting:
		#if !((($AnimationPlayer.get_current_animation() == 'upright') and !animationplaying) or (($AnimationPlayer.get_current_animation() == 'uprightwalk') and animationplaying)) or settingtargeting:
			if activenode:
				activenode.hide()
			get_node("uprightrig/body/head").texture = uprighthead
			get_node("uprightrig/body/head/hair").texture = uprighthair
			$downleftrig.visible = false
			$uprightrig.visible = true
			$uprig.visible = false
			$downrig.visible = false
			visiblerig = 'uprightrig'
			if running:
				animprefix = 'uprightrun'
			else:
				animprefix = 'uprightwalk'
			#print(dir, subdir)
			if animationplaying:
				if targeting:
					var anim = animprefix + wpnclass
					if subdircat != subdir:
						anim += '_' + subdircat
						if subdircat == 'twistleft':
							get_node("uprightrig/body/head").texture = uphead
							get_node("uprightrig/body/head/hair").texture = uphair
					$AnimationPlayer.play(anim)
				else:
					$AnimationPlayer.play(animprefix)
			else:
				if targeting:
					$AnimationPlayer.play("uprightpistol")
					activenode.show()
				else:
					$AnimationPlayer.play("upright")
			if subdir in ['right', 'rtwistright', 'rtwistleft'] and !($uprightrig.scale == Vector2(1,1)):
				$uprightrig.scale = Vector2(1,1)
			elif subdir in ['left', 'ltwistleft', 'ltwistright'] and !($uprightrig.scale == Vector2(-1,1)):
				$uprightrig.scale = Vector2(-1,1)
	elif dir == 'down':
		if dir != prior_dir or subdir != prior_subdir or prior_animation != animationplaying or prior_running != running or settingtargeting:
		#if !((($AnimationPlayer.get_current_animation() == 'downleft') and !animationplaying) or (($AnimationPlayer.get_current_animation() == 'downleftwalk') and animationplaying)) or settingtargeting:
			if activenode:
				activenode.hide()
			get_node("downleftrig/body/head").flip_h = false
			get_node("downleftrig/body/head/hair").flip_h = false
			$downleftrig.visible = true
			$uprightrig.visible = false
			$uprig.visible = false
			$downrig.visible = false
			visiblerig = 'downleftrig'
			if running:
				animprefix = 'downleftrun'
			else:
				animprefix = 'downleftwalk'
			#print(dir, subdir)
			if animationplaying:
				if targeting:
					var anim = animprefix + wpnclass
					if subdircat != subdir:
						anim += '_' + subdircat
						if subdircat == 'twistleft':
							get_node("downleftrig/body/head").flip_h = true
							get_node("downleftrig/body/head/hair").flip_h = true
					$AnimationPlayer.play(anim)
				else:
					$AnimationPlayer.play(animprefix)
			else:
				if targeting:
					$AnimationPlayer.play("downleftpistol")
					activenode.show()
				else:
					$AnimationPlayer.play("downleft")
			if subdir in ['right', 'rtwistright', 'rtwistleft'] and !($downleftrig.scale == Vector2(-1,1)):
				$downleftrig.scale = Vector2(-1,1)
			elif subdir in ['left', 'ltwistleft', 'ltwistright'] and !($downleftrig.scale == Vector2(1,1)):
				$downleftrig.scale = Vector2(1,1)
	if targeting:
		if dir == 'straightdown':
			activenode.texture = activenode.straightdownsprite
			if flip != null:
				activenode.flip_v = flip
			activenode.z_index = 0
		elif dir == 'straightup':
			activenode.z_index = -1
		else:
			activenode.texture = activenode.leftrightsprite
			if flip != null:
				activenode.flip_h = flip
			activenode.z_index = -1
		if (dir == 'up' and subdir in ['ltwistright', 'rtwistright']) or (dir == 'down' and subdir in ['ltwistleft', 'rtwistleft']):
			activenode.global_position = get_node(visiblerig + '/body/arm_left/forearm_left/hand_left/Position2D').global_position
		else:
			activenode.global_position = get_node(visiblerig + '/body/arm_right/forearm_right/hand_right/Position2D').global_position
		#activenode.show()
	if settingtargeting:
		settingtargeting = false
		if targeting == false:
			if activeslot != '0':
				get_node('slot' + activeslot).visible = false
		else:
			if activeslot != '0':
				get_node('slot' + activeslot).visible = true
		if is_network_master():
			rset('slave_settingtargeting', settingtargeting)
	prior_running = running
	prior_dir = dir
	prior_subdir = subdir
	prior_animation = animationplaying

func damage(value, pos):
	var localpos = to_local(pos)
	var personhit = person_hit.instance()
	var yoffset = rand_range(0,25)
	var xoffset = rand_range(-20, 20)
	if localpos.x > 0:
		personhit.init(Vector2(global_position.x + xoffset, global_position.y + yoffset), Vector2(-localpos.x, localpos.y), true)
	else:
		personhit.init(Vector2(global_position.x + xoffset, global_position.y + yoffset), Vector2(localpos.x, localpos.y), false)
	add_child(personhit)
	
	health_points -= value
	if health_points <= 0:
		health_points = 0
		rpc('_die')
	if has_method('_update_health_bar'):
		_update_health_bar()

sync func _die():
	var activenode = null
	if activeslot != '0':
		get_node('slot' + activeslot).hide()
		targeting = false
		activeslot = '0'
	$CollisionShape2D.disabled = true
	if $downleftrig.visible == true:
		$AnimationPlayer.play('downleft_die')
	elif $uprightrig.visible == true:
		$AnimationPlayer.play('upright_die')
	elif $uprig.visible == true:
		$AnimationPlayer.play('up_die')
	elif $downrig.visible == true:
		$AnimationPlayer.play('down_die')
	else:
		$downleftrig.visible = true
		$uprightrig.visible = false
		$uprig.visible = false
		$downrig.visible = false
		$AnimationPlayer.play('downleft_die')  # Catch those strange errors where no visible rig is found.
	set_physics_process(false)

func _on_RespawnTimer_timeout():
	set_physics_process(true)
	if activeslot != '0':
		get_node('slot' + activeslot).set_process(true)
	for child in get_children():
		if child.has_method('show'):
			child.show()
	$CollisionShape2D.disabled = false
	health_points = max_hp
	_update_health_bar()

func init(nickname, start_position, is_slave):
	if has_method('init_gui'):
		init_gui(nickname)
	global_position = start_position
	mousepos = global_position
	rset('slave_mousepos', global_position)
	if is_slave:
		pass

func _on_AnimatedSprite_frame_changed():
	$AnimatedSprite.offset = frameoffsets[$AnimatedSprite.frame]
	if activeslot != '0':
		get_node('slot' + activeslot).set('frameoffset', frameoffsets[$AnimatedSprite.frame])
	
func set_shooting():
	if is_network_master():
		rset('slave_shooting', shooting)
