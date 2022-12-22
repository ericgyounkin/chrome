extends Node

const DEFAULT_PORT = 31400
const MAX_PLAYERS = 5

var peer = null
var ip_address = ''
var players = { }

#bounds for starting area (0, 180) to (600, 580)
var self_data = {name = '', position = Vector2(600, 580)}

# game parameters
var game_data = {'undercover_npc': 0, 'coward_npc': 0, 'berserk_npc': 0}

signal player_disconnected
signal server_disconnected

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')

func get_starting_position():
	return Vector2(rand_range(0, 600), rand_range(180, 580))

func create_server(player_nickname):
	print('createserver')
	self_data.name = player_nickname
	self_data.position = get_starting_position()
	players[1] = self_data
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)

func connect_to_server(player_nickname):
	print('connectserver')
	self_data.name = player_nickname
	self_data.position = get_starting_position()
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func _connected_to_server():
	print('connectedtoserver')
	var local_player_id = get_tree().get_network_unique_id()
	players[local_player_id] = self_data
	rpc('_send_player_info', local_player_id, self_data, game_data)

func _on_player_disconnected(id):
	print('onplayerdiscon')
	players.erase(id)

func _on_player_connected(connected_player_id):
	print('onplayerconnected')
	var local_player_id = get_tree().get_network_unique_id()
	if not(get_tree().is_network_server()):
		rpc_id(1, '_request_player_info', local_player_id, connected_player_id)

remote func _request_player_info(request_from_id, player_id):
	print('requestplayerinfo %s %s' % [request_from_id, player_id])
	if get_tree().is_network_server():
		rpc_id(request_from_id, '_send_player_info', player_id, players[player_id], game_data)

# A function to be used if needed. The purpose is to request all players in the current session.
remote func _request_players(request_from_id):
	print('requestplayers %s' % request_from_id)
	if get_tree().is_network_server():
		for peer_id in players:
			if( peer_id != request_from_id):
				rpc_id(request_from_id, '_send_player_info', peer_id, players[peer_id], game_data)

remote func _send_player_info(id, info, gamedata):
	print('sendplayerinfo %s %s %s' % [id, info, gamedata])
	if not get_tree().is_network_server():
		game_data = gamedata
		$'/root/game/'.setup_game_params()
	players[id] = info
	var new_player = load('res://scenes/sprites/player.tscn').instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	$'/root/game/'.add_child(new_player)
	new_player.init(info.name, info.position, true)

func update_position(id, position):
	print('updateposition')
	players[id].position = position