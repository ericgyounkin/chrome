extends 'res://scripts/sprites/character.gd'


func _ready():
	add_to_group('pc')
	equip = ['pistol', 'uzi', '', '', '']
	load_slots()
	if is_network_master():
		$customcamera.current = true

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			if skip_extra_wheel and $customcamera.target_zoom >= 1.5:
				$customcamera.target_zoom -= 0.025
			else:
				skip_extra_wheel = true
		elif event.button_index == BUTTON_WHEEL_DOWN:
			if skip_extra_wheel and $customcamera.target_zoom <= 3.5:
				$customcamera.target_zoom += 0.025
			else:
				skip_extra_wheel = true
		elif event.button_index == BUTTON_LEFT and event.pressed:
			if is_network_master():
				shooting = false
				moving = true
				mousepos = get_global_mouse_position() - Vector2(0, spriteheight / 4) + mousecursordif
				rset('slave_mousepos', mousepos)
				update_navigation_path(global_position, mousepos)
		elif event.button_index == BUTTON_RIGHT and event.pressed and targeting:
			if is_network_master():
				targeting_mousepos = get_global_mouse_position() + mousecursordif
				targetingdir = (targeting_mousepos - global_position).normalized()
				rset('slave_targeting_mousepos', targeting_mousepos)
				get_node('slot' + activeslot).shoot()


func _physics_process(delta):
	if is_network_master():
		if Input.is_action_just_pressed('num1'):
			set_targeting_mode(1)
		elif Input.is_action_just_pressed('num2'):
			set_targeting_mode(2)
		elif Input.is_action_just_pressed('num3'):
			set_targeting_mode(3)
		elif Input.is_action_just_pressed('num4'):
			set_targeting_mode(4)
		elif Input.is_action_just_pressed('num5'):
			set_targeting_mode(5)
		
		if Input.is_action_just_pressed('shiftkey'):
			running = true
			move_speed = run_speed
			rset('slave_running', running)
		elif Input.is_action_just_released('shiftkey'):
			running = false
			move_speed = walk_speed
			rset('slave_running', running)
		
		travel_dist = (mousepos - global_position).length()
		rawvelocity = (mousepos - global_position).normalized()
		if moving:
			var walkdist = move_speed * delta
			move_along_path(walkdist)
		animationdirs = get_animation_dirs()
		handle_targeting_anim(animationdirs[0], animationdirs[1], animationdirs[2], animationdirs[3], animationdirs[4])
		rset_unreliable('slave_position', position)
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
			$gui/ammo.text = str(get_node('slot' + activeslot).slave_ammo)
		handle_targeting_anim(slave_animationdirs[0], slave_animationdirs[1], slave_animationdirs[2], slave_animationdirs[3], slave_animationdirs[4])

func init_gui(nickname):
	$gui/Nickname.text = nickname

func _update_health_bar():
	$gui/HealthBar.value = health_points
	
func update_guiammo(ammo):
	if has_node('gui/ammo') and get_node('slot' + activeslot):      # wont show up till completely loaded
		$gui/ammo.text = str(get_node('slot' + activeslot).ammo)