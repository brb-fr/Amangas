extends Node2D

var players := []
var options := {"host": 1}
@export var player_scene: PackedScene

func _ready() -> void:
	var my_id = multiplayer.get_unique_id()
	if not players.has(my_id):
		players.append(my_id)
		_add_player(my_id, true)
	Server.player_request_join.connect(func(id:int):
		if not players.has(id):
			players.append(id)
			_add_player(id, false)
		_sync_players_to_all())

	_sync_players_to_all()

func _add_player(id:int, is_local_authority:bool) -> void:
	if $Players.has_node(str(id)):
		return
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = $Spawn.position
	$Players.call_deferred("add_child", player)
	if is_local_authority:
		player.set_multiplayer_authority(id)
		
func _sync_players_to_all() -> void:
	for player_id in players:
		rpc_id(player_id, "set_players", players, options)
@rpc("call_remote", "any_peer", "reliable")
func set_players(players_arr:Array, options_dict:Dictionary):
	options = options_dict
	players = players_arr
	for id in players_arr:
		if not $Players.has_node(str(id)):
			_add_player(id, multiplayer.get_unique_id() == id)
			
