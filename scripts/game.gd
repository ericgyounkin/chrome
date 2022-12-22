extends Node
var npccount = 1

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	var new_player = preload('res://scenes/sprites/player.tscn').instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id())
	add_child(new_player)
	var info = network.self_data
	new_player.init(info.name, info.position, false)
	if is_network_master():
		setup_game_params()
	#print('servers: ' + str(Steam.requestLobbyList()))
	#generate_npc(3, 'undercover')
	#generate_npc(1, 'passive')

func _on_player_disconnected(id):
	get_node(str(id)).queue_free()

func _on_server_disconnected():
	get_tree().change_scene('res://scenes/interface/menu.tscn')
	
func generate_npc(cnt, npctype):
	for i in range(0, cnt):
		var npc = preload("res://scenes/sprites/npc.tscn").instance()
		npc.npctype = npctype
		npc.name = 'npc' + str(npccount)
		add_child(npc)
		npc.init('npc' + str(npccount), network.get_starting_position(), false)
		npccount += 1
		
func setup_game_params():
	generate_npc(network.game_data['undercover_npc'], 'undercover')
	generate_npc(network.game_data['coward_npc'], 'passive')
	generate_npc(network.game_data['berserk_npc'], 'berserk')