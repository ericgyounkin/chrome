extends 'res://scripts/items/weapons/gun.gd'

var offsetsdict = {'straightdownsprite': "res://art/items/Topdownbig9mil.png", 'leftrightsprite': "res://art/items/Sideviewbig9mil.png",
                   'frameoffset': Vector2(), 'pos_up_right': Vector2(30, -45), 'pos_up_left': Vector2(-30, -45), 'pos_up_rtwistright': Vector2(32, -25),
				   'pos_up_rtwistleft': Vector2(-39, -63), 'pos_up_ltwistright': Vector2(-32, -25), 'pos_up_ltwistleft': Vector2(32, -64),
				   'pos_down_right': Vector2(32, -38), 'pos_down_left': Vector2(-32, -38), 'pos_down_ltwistright': Vector2(-32, -64),
				   'pos_down_ltwistleft': Vector2(28, 5), 'pos_down_rtwistright':Vector2(32, -64), 'pos_down_rtwistleft': Vector2(-28, -5),
				   'pos_straightdown_straightdown': Vector2(0, -28), 'pos_straightup_straightup': Vector2(0, -28)}

func _ready():
	initializeoffsets(offsetsdict)
	texture = leftrightsprite
	$mflash/flashtimer.wait_time = 0.05
	$pistolshot.stream = load('res://sounds/items/pistolshot.ogg')
	gunname = 'Uzi'
	guntype = 'onehandgun'
	gunmode = 'burst'
	gunshottimer = 0.4
	gunreloadtimer = 1
	gunbursttimer = 0.05
	$firetime.wait_time = gunshottimer
	$reloadtime.wait_time = gunreloadtimer
	$bursttimer.wait_time = gunbursttimer
	maxammo = 15
	ammo = 15
	rset('slave_ammo', ammo)
