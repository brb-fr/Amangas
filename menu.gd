extends Control

var peer := WebSocketMultiplayerPeer.new()
var rooms := []
const PORT = 22023
var ms:int

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
	else:
		multiplayer.connected_to_server.connect(func():
			$Host/Icon/Tube/Loading.hide()
			$Private/Icon/Tube/Loading.hide()
		)
		multiplayer.connection_failed.connect(func():
			$Error.show()
			var tween = get_tree().create_tween()
			tween.tween_property($Error,"scale", Vector2(1.0,1.0), 0.1)
			tween.play()
			$Error/Err.text = "Failed to connect to the server\nafter 1 ping (%s ms)"%str(Time.get_ticks_msec() - ms)
			$Host/Icon/Tube/Loading.hide()
			$Private/Icon/Tube/Loading.hide()
		)


func _on_host_pressed() -> void:
	$Host/Icon/Tube/Loading.show()
	ms = Time.get_ticks_msec()
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client(str($Title/IP.text))
	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server
	rpc_id(1,"create_game","brbfr")

func _on_close_mouse_entered() -> void:
	if !DisplayServer.is_touchscreen_available():
		$Error/Close.modulate = Color(0.1,1.0,0.1)


func _on_close_mouse_exited() -> void:
	$Error/Close.modulate = Color.WHITE


func _on_close_pressed() -> void:
	$Error.hide()
	$Error.scale = Vector2(0.0,0.0)


func _on_go_mouse_entered() -> void:
	if !DisplayServer.is_touchscreen_available() and !$Private/Go.disabled:
		$Private/Go.modulate = Color(0.1,1.0,0.1)


func _on_go_mouse_exited() -> void:
	$Private/Go.modulate = Color.WHITE


func _on_go_pressed() -> void:
	$Private/Icon/Tube/Loading.show()
	ms = Time.get_ticks_msec()
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client(str($Title/IP.text))
	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server
	rpc_id(1,"join_game",int($Private.text),"brbfr")
func _process(delta: float) -> void:
	if $Private/Icon/Tube/Loading.visible or $Host/Icon/Tube/Loading.visible:
		$Private.editable = false
		$Title/IP.editable = false
		$Private/Go.disabled = true
		$Host.disabled = true
	else:
		$Title/IP.editable = true
		$Private.editable = true
		$Private/Go.disabled = false
		$Host.disabled = false

@rpc("any_peer","call_local", "reliable")
func show_error(err:String):
	if multiplayer.get_remote_sender_id() == 1:
		$Error.show()
		var tween = get_tree().create_tween()
		tween.tween_property($Error,"scale", Vector2(1.0,1.0), 0.1)
		tween.play()
		$Error/Err.text = err
		$Host/Icon/Tube/Loading.hide()
		$Private/Icon/Tube/Loading.hide()
	

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
func join_game(room_code:int,player_username:String,player_id:int=0):
	var player_real = multiplayer.get_remote_sender_id() if player_id == 0 else player_id
	print("Client trying to join: %s (%s)"%[room_code,player_real])
	if rooms.size() == 0:
		rpc_id(player_real, "show_error", "Room not found.")
	for room in rooms:
		if int(room.code) == room_code:
			pass
		else:
			rpc_id(player_real, "show_error", "Room not found.")
