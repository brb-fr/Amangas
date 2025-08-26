extends Control

@onready var ip = $Title/IP.text
const PORT = 22023

func _ready() -> void:
	multiplayer.connected_to_server.connect(func():
		Server.rpc_id(1,"create_game","brbfr")
	)


func _on_host_pressed() -> void:
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client(str("ws://%s"%ip))
	multiplayer.multiplayer_peer = peer
