extends Node2D

var players := []
var options := {"host": 1}
@export var player_scene: PackedScene


func _ready() -> void:
	Server.rpc_id(1, "host_joined_lobby")
	Server.player_request_join.connect(func(id:int):
		var player = player_scene.instantiate()
		player.name = str(id)
		player.position = $Spawn.position
		players.append(id)
		$Players.call_deferred("add_child",player)
		for player_id in players:
			rpc_id(player_id,"set_players", players, options)
	)

@rpc("authority","call_remote","reliable")
func set_players(players_arr:Array,options_dict:Dictionary):
	options = options_dict
	players = players_arr
