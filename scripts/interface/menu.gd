extends Control
var _player_name = ''
var issteamrunning = false
var lobbyid = 0


func _ready():
	$VBoxContainer/HBoxContainer4/server_check.pressed = true
	#var issteamrunning = Steam.steamInit()
	#_player_name = Steam.getPersonaName()
	#Steam.connect('lobby_created', self, 'testthisout')
	#Steam.connect('overlay_toggled', self, 'overlay')
	#print('Steam running: {str}, {str2}'.format({'str': str(issteamrunning), 'str2': str(_player_name)}))
	#$VBoxContainer/HBoxContainer/TextField.text = str(_player_name)
	pass
	
func _load_game():
	get_tree().change_scene('res://scenes/game.tscn')

func _on_join_check_toggled(button_pressed):
	if button_pressed:
		$VBoxContainer/HBoxContainer4/server_check.set_pressed(false)
		$VBoxContainer/Panel/VBoxContainer/HBoxContainer3/Label.visible = false
		$VBoxContainer/Panel/VBoxContainer/HBoxContainer3/cowardnpc_count.visible = false
		$VBoxContainer/Panel/VBoxContainer/HBoxContainer4/Label2.visible = false
		$VBoxContainer/Panel/VBoxContainer/HBoxContainer4/undercovernpc_count.visible = false

func _on_server_check_toggled(button_pressed):
	if button_pressed:
		$VBoxContainer/HBoxContainer4/join_check.set_pressed(false)
		$VBoxContainer/Panel/VBoxContainer/HBoxContainer3/Label.visible = true
		$VBoxContainer/Panel/VBoxContainer/HBoxContainer3/cowardnpc_count.visible = true
		$VBoxContainer/Panel/VBoxContainer/HBoxContainer4/Label2.visible = true
		$VBoxContainer/Panel/VBoxContainer/HBoxContainer4/undercovernpc_count.visible = true

func _on_gobutton_pressed():
	if $VBoxContainer/HBoxContainer4/server_check.pressed:
		_player_name = $VBoxContainer/HBoxContainer3/name_enter.text
		if _player_name == "":
			return
		#lobbyid = Steam.createLobby(Steam.PUBLIC, 4) #2=public, max players 4
		#print(lobbyid)
		network.game_data['undercover_npc'] = int($VBoxContainer/Panel/VBoxContainer/HBoxContainer4/undercovernpc_count.value)
		network.game_data['coward_npc'] = int($VBoxContainer/Panel/VBoxContainer/HBoxContainer3/cowardnpc_count.value)
		network.game_data['berserk_npc'] = int($VBoxContainer/Panel/VBoxContainer/HBoxContainer5/berserknpc_count.value)
		network.create_server(_player_name)
		_load_game()
	elif $VBoxContainer/HBoxContainer4/join_check.pressed:
		_player_name = $VBoxContainer/HBoxContainer3/name_enter.text
		network.ip_address = $VBoxContainer/HBoxContainer3/ipaddress_enter.text
		if _player_name == "":
			return
		if network.ip_address == '':
			network.ip_address = '127.0.0.1'
		network.connect_to_server(_player_name)
		_load_game()
