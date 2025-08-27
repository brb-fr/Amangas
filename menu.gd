extends Control

@onready var ip = $Title/IP.text
const PORT = 22023
var ms:int
func _ready() -> void:
	multiplayer.connected_to_server.connect(func():
		Server.rpc_id(1,"create_game","brbfr")
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
	peer.create_client(str("ws://%s"%ip))
	multiplayer.multiplayer_peer = peer


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
	$Host/Icon/Tube/Loading.show()
	ms = Time.get_ticks_msec()
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client(str("ws://%s"%ip))
	multiplayer.multiplayer_peer = peer

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
