extends Node

var peer := WebSocketMultiplayerPeer.new()
var rooms := []

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		peer.create_server(22023)
		multiplayer.multiplayer_peer = peer
		print("Server hosted on port 22023")
	multiplayer.multiplayer_peer.peer_connected.connect(func(id:int):
		print("Client connected (%s)"%id)
	)
	multiplayer.multiplayer_peer.peer_disconnected.connect(func(id:int):
		print("Client disconnected (%s)"%id)
	)
@rpc("any_peer", "call_local","reliable")
func create_game(player_username:String, player_id:int = 0):
	randomize()
	var player_real = multiplayer.get_remote_sender_id() if player_id == 0 else player_id
	var room_code = str(snapped(randi(),100000)).left(6)
	for room in rooms:
		if room.code == room_code:
			create_game(player_username, player_real)
			return
	print("Room hosted with code %s by %s (%s)"%[room_code,player_username,str(player_real)])
	rooms.append({
		"code": room_code,
		"host_username": player_username,
		"host_id": player_real
	})
@rpc("any_peer", "call_local", "reliable")
func join_game(room_code:int,player_real:int,player_username:String):
	pass
