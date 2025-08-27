extends Node

var peer := WebSocketMultiplayerPeer.new()
var rooms := []
const PORT = 22023
signal server_error(err:String)
signal player_request_join(id:int)
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

@rpc("any_peer", "call_remote","reliable")
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

@rpc("any_peer", "call_remote", "reliable")
func join_game(room_code:int,player_username:String,player_id:int=0):
	var player_real = multiplayer.get_remote_sender_id() if player_id == 0 else player_id
	print("Client trying to join: %s (%s)"%[room_code,player_real])
	for room in rooms:
		if int(room.code) == room_code:
			print("Player joined room %s (%s)"%[room_code,player_real])
			return
	rpc_id(player_real, "send_err", "Room not found.")


@rpc("any_peer","call_remote", "reliable")
func send_err(err:String):
	server_error.emit(err)

@rpc("authority","call_remote","reliable")
func host_joined_lobby():
	var id = multiplayer.get_remote_sender_id()
	for room in rooms:
		if room.host_id == id:
			print("Host joined the game.")
			return

@rpc("any_peer","call_remote", "reliable")
func player_joined_room(room_code:int):
	var id = multiplayer.get_remote_sender_id()
	for room in rooms:
		if int(room.code) == room_code:
			print("Player joined the game.")
			rpc_id(room.host_id, "add_player_to_lobby",id)
			return

@rpc("authority","call_remote","reliable")
func add_player_to_lobby(id:int):
	player_request_join.emit(id)
