extends Sprite

var target = Vector2()
slave var slavetarget = Vector2()
const bullet = preload("res://scenes/items/weapons/bullet.tscn")

var straightdownsprite = null
var leftrightsprite = null

var frameoffset = Vector2()
var pos_up_right = Vector2()
var pos_up_left = Vector2()
var pos_up_rtwistright = Vector2()
var pos_up_rtwistleft = Vector2()
var pos_up_ltwistright = Vector2()
var pos_up_ltwistleft = Vector2()
var pos_down_right = Vector2()
var pos_down_left = Vector2()
var pos_down_ltwistright = Vector2()
var pos_down_ltwistleft = Vector2()
var pos_down_rtwistright = Vector2()
var pos_down_rtwistleft = Vector2()
var pos_straightdown_straightdown = Vector2()
var pos_straightup_straightup = Vector2()

var gunname = ''
var guntype = ''
var gunshottimer = 0
var gunreloadtimer = 0
var gunbursttimer = 0
var gunburstshots = 3
var gunmode = 'single'
var maxammo = 0
var ammo = 0 setget ammosync
slave var slave_ammo = 0


sync func initializeoffsets(offsetsdict):
	straightdownsprite = load(offsetsdict['straightdownsprite'])
	leftrightsprite = load(offsetsdict['leftrightsprite'])
	frameoffset = offsetsdict['frameoffset']
	pos_up_left = offsetsdict['pos_up_left']
	pos_up_right = offsetsdict['pos_up_right']
	pos_up_rtwistright = offsetsdict['pos_up_rtwistright']
	pos_up_rtwistleft = offsetsdict['pos_up_rtwistleft']
	pos_up_ltwistright = offsetsdict['pos_up_ltwistright']
	pos_up_ltwistleft = offsetsdict['pos_up_ltwistleft']
	pos_down_right = offsetsdict['pos_down_right']
	pos_down_left = offsetsdict['pos_down_left']
	pos_down_rtwistright = offsetsdict['pos_down_rtwistright']
	pos_down_rtwistleft = offsetsdict['pos_down_rtwistleft']
	pos_down_ltwistright = offsetsdict['pos_down_ltwistright']
	pos_down_ltwistleft = offsetsdict['pos_down_ltwistleft']
	pos_straightdown_straightdown = offsetsdict['pos_straightdown_straightdown']
	pos_straightup_straightup = offsetsdict['pos_straightup_straightup']

func ammosync(newval):
	ammo = newval
	rset('slave_ammo', newval)
	
sync func _shoot():
	var blt = bullet.instance()
	add_child(blt)
	blt.global_position = global_position

	if is_network_master():
		$mflash.show()
		$mflash/flashtimer.start()
		$gunshot_radius/CollisionShape2D.disabled = false
		$mflash.global_position = global_position
		blt.velocity = (target - global_position).normalized() * blt.SPEED
		blt.rotation = blt.velocity.angle()
	else:
		blt.velocity = (slavetarget - global_position).normalized() * blt.SPEED
		blt.rotation = blt.velocity.angle()
		
func shoot():
	if $firetime.is_stopped() and $reloadtime.is_stopped():
		get_parent().shooting = true
		get_parent().set_shooting()
		if gunmode == 'single':
			target = get_parent().targeting_mousepos
			rset('slavetarget', target)
			rpc('_shoot')
			$pistolshot.play()
			$firetime.start()
			ammo -= 1
			if ammo == 0:
				$reloadtime.start()
			if get_parent().has_method('update_guiammo'):
				get_parent().update_guiammo(ammo)
		elif gunmode == 'burst':
			gunburstshots = 3
			if ammo:
				$bursttimer.start()
			$firetime.start()

func _on_flashtimer_timeout():
	$mflash.hide()
	$mflash/flashtimer.stop()
	$gunshot_radius/CollisionShape2D.disabled = true

func _on_reloadtime_timeout():
	ammo = maxammo
	if get_parent().has_method('update_guiammo'):
		get_parent().update_guiammo(ammo)

func _on_bursttimer_timeout():
	ammo -= 1
	if get_parent().has_method('update_guiammo'):
		get_parent().update_guiammo(ammo)
	target = get_parent().get_global_mouse_position() + get_parent().mousecursordif
	rset('slavetarget', target)
	rpc('_shoot')
	$pistolshot.play()
	if ammo == 0:
		gunburstshots = 0
		$reloadtime.start()
		$bursttimer.stop()
	gunburstshots -= 1
	if gunburstshots == 0:
		$bursttimer.stop()

func _on_gunshot_radius_body_entered(body):
	if body != get_parent() and body.has_method('set_scared'):
		if get_tree().is_network_server():
			var fromgun_topc = (global_position - body.global_position).normalized()
			body.set_scared(body.global_position - (fromgun_topc * 1500))
		else:
			var fromgun_topc = (global_position - body.global_position).normalized()
			rpc_id(1, 'set_npc_scared', body.name, body.global_position - (fromgun_topc * 1500))

remote func set_npc_scared(nme, fleedir):
	var npcs = get_tree().get_nodes_in_group('npc')
	for n in npcs:
		if n.name == nme:
			n.set_scared(fleedir)
			break