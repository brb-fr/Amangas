extends Control

var ms:int
@export var spaceship_scene:PackedScene
var players := []
var options := {"host": 1}
@export var player_scene: PackedScene
var peer := WebSocketMultiplayerPeer.new()
var ping_ms: int = -1   # latest RTT in ms, -1 = not connected / error
var rooms := []
const PORT = 22023
signal server_error(err:String)
signal player_request_join(id:int)
@onready var ship := spaceship_scene.instantiate()

func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		$"UI/Virtual Joystick".show()
	ship.hide()
	add_child(ship)
	_ping_loop()
	server_error.connect(show_error)
	if FileAccess.file_exists("user://ip.address"):
		var file = FileAccess.open("user://ip.address",FileAccess.READ)
		$Title/IP.text = file.get_as_text()
	if FileAccess.file_exists("user://user.name"):
		var file = FileAccess.open("user://user.name",FileAccess.READ)
		$Title/Name.text = file.get_as_text()
	if !OS.has_feature("dedicated_server"):
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
	player_request_join.connect(func(id:int):
		if not players.has(id):
			players.append(id))
	if OS.has_feature("dedicated_server"):
		peer.create_server(PORT)
		multiplayer.multiplayer_peer = peer
		print("Server hosted on port %s" % PORT)
		multiplayer.multiplayer_peer.peer_connected.connect(func(id:int):
			print("Client connected (%s)" % id)
		)
		multiplayer.multiplayer_peer.peer_disconnected.connect(func(id:int):
			print("Client disconnected (%s)" % id)
			if get_node(str(id)):
				remove_child(get_node(str(id)))
		)

func _on_host_pressed() -> void:
	if $Title/Name.text == "":
		$Title/Name/Shake.play("shake")
		return
	$Host/Icon/Tube/Loading.show()
	ms = Time.get_ticks_msec()
	peer = WebSocketMultiplayerPeer.new()
	var peer = peer
	peer.create_client(str($Title/IP.text))
	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server
	rpc_id(1,"create_game", $Title/Name.text)

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
	if $Title/Name.text == "":
		$Title/Name/Shake.play("shake")
		return
	$Private/Icon/Tube/Loading.show()
	ms = Time.get_ticks_msec()
	peer = WebSocketMultiplayerPeer.new()
	var peer = peer 
	peer.create_client(str($Title/IP.text))
	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server
	rpc_id(1,"join_game",int($Private.text),$Title/Name.text)

func _process(delta: float) -> void:
	if ping_ms != -1:
		$UI/Ping.text = "Ping: %sms"%ping_ms
	else:
		$UI/Ping.text = ""
	if $Private/Icon/Tube/Loading.visible or $Host/Icon/Tube/Loading.visible:
		$Private.editable = false
		$Title/IP.editable = false
		$Title/Name.editable = false
		$Private/Go.disabled = true
		$Host.disabled = true
	else:
		$Title/IP.editable = true
		$Title/Name.editable = true
		$Private.editable = true
		$Private/Go.disabled = false
		$Host.disabled = false


func show_error(err:String):
	if multiplayer.get_remote_sender_id() == 1:
		$Error.show()
		var tween = get_tree().create_tween()
		tween.tween_property($Error,"scale", Vector2(1.0,1.0), 0.1)
		tween.play()
		$Error/Err.text = err
		$Host/Icon/Tube/Loading.hide()
		$Private/Icon/Tube/Loading.hide()
	

func _on_ip_focus_exited() -> void:
	var file = FileAccess.open("user://ip.address",FileAccess.WRITE)
	file.store_string($Title/IP.text)


func _add_player(id:int, username:String):
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)
	player.set_username(str(username))
	player.get_node("uname").text = str(username)
	return player

@rpc("call_remote", "any_peer", "reliable")
func set_players(players_arr:Array, options_dict:Dictionary):
	options = options_dict
	players = players_arr



@rpc("any_peer", "call_remote", "reliable")
func create_game(player_username:String, player_id:int = 0):
	randomize()
	var player_real = multiplayer.get_remote_sender_id() if player_id == 0 else player_id
	var room_code = str(snapped(randi(),100000)).left(6)
	for room in rooms:
		if int(room.code) == int(room_code):
			create_game(player_username, player_real)
			return
	print("Room hosted with code %s by %s (%s)" % [room_code, player_username, str(player_real)])
	rooms.append({
		"code": room_code,
		"host_username": player_username,
		"host_id": player_real,
		"players": [player_real]
	})
	rpc_id(player_real, "join_game", int(room_code), player_username, player_real)
	rpc_id(player_real, "create_airship", int(room_code))
	_add_player(player_real, player_username)
	await get_tree().create_timer(0.25).timeout
	rpc_id(player_real, "set_pos", int(room_code))
@rpc("any_peer", "call_remote", "reliable")
func join_game(room_code:int, player_username:String, player_id:int=0):
	var player_real = multiplayer.get_remote_sender_id() if player_id == 0 else player_id
	print("Client trying to join: %s (%s)" % [room_code, player_real])
	for room in rooms:
		if int(room.code) == int(room_code):
			print("Player joined room %s (%s)" % [room_code, player_real])
			rpc_id(player_real, "player_joined_room", int(room_code))
			rpc_id(room.host_id, "add_player_to_lobby", player_real)
			rpc_id(player_real, "create_airship", int(room_code))
			_add_player(player_real, player_username)
			await get_tree().create_timer(0.25).timeout
			rpc_id(player_real, "set_pos",int(room_code))
			return
	rpc_id(player_real, "send_err", "Room not found.")
@rpc("any_peer", "call_remote", "reliable")
func send_err(err:String):
	server_error.emit(err)

@rpc("any_peer", "call_remote", "reliable")
func host_joined_lobby():
	var id = multiplayer.get_remote_sender_id()
	for room in rooms:
		if room.host_id == id:
			print("Host joined the game.")
			return

@rpc("any_peer", "call_local", "reliable")
func player_joined_room(room_code:Variant):
	var id = multiplayer.get_remote_sender_id()
	for room in rooms:
		if int(room.code) == int(room_code):
			print("Player joined the game.")
			room.players.append(id)
			for player in room.players:
				rpc_id(int(player), "add_player_to_lobby", int(id))
			return

@rpc("any_peer", "call_remote", "reliable")
func add_player_to_lobby(id:int):
	player_request_join.emit(id)

@rpc("any_peer","call_remote","reliable")
func create_airship(coords:int):
	ship.show()
	ship.position.x = coords
	$UI/Code.text = "Code\n%s"%coords

@rpc("any_peer","call_local")
func ping(sent_time: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if id == 0: return
	rpc_id(id, "pong", sent_time, Time.get_ticks_msec())

@rpc("any_peer","call_local")
func pong(sent_time: int, server_time: int) -> void:
	var now := Time.get_ticks_msec()
	ping_ms = now - sent_time   # update ping ms

func _ping_loop() -> void:
	if peer.get_connection_status() == peer.ConnectionStatus.CONNECTION_CONNECTED:
		rpc_id(1, "ping", Time.get_ticks_msec())
	else:
		ping_ms = -1
	await get_tree().create_timer(0.5).timeout
	_ping_loop()
@rpc("any_peer","call_remote","reliable")
func set_pos(posx:int):
	get_node(str(multiplayer.get_unique_id())).position.x = posx


func check_delay() -> void:
	if !$Title/IP.text.begins_with("wss://") and !$Title/IP.text.begins_with("ws://"):
		multiplayer.connection_failed.emit()
		$Error.show()
		var tween = get_tree().create_tween()
		tween.tween_property($Error,"scale", Vector2(1.0,1.0), 0.1)
		tween.play()
		$Error/Err.text = "Invalid server address."
		$Host/Icon/Tube/Loading.hide()
		$Private/Icon/Tube/Loading.hide()


func _on_name_focus_exited() -> void:
	var file = FileAccess.open("user://user.name",FileAccess.WRITE)
	file.store_string($Title/Name.text)
