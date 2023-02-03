extends Node


const PLAYER = preload("res://characters/player.tscn")


func start_network_server():
	var peer = ENetMultiplayerPeer.new()
	
	# Listen to peer connections, and create new player for them
	multiplayer.peer_connected.connect(self.create_player)
	# Listen to peer disconnections, and destroy their players
	multiplayer.peer_disconnected.connect(self.destroy_player)
	
	peer.create_server(4242)
	multiplayer.set_multiplayer_peer(peer)
	
	# Remove if you're making a dedicated server
	create_player(1)
	
	$Player_UI.show()
	$Menu_UI.hide()

func start_network_client(address: String):
	var peer = ENetMultiplayerPeer.new()
	
	# Listen to server dissconnections, and revert any changes
	multiplayer.server_disconnected.connect(self.server_disconnected)
	
	peer.create_client(address, 4242)
	multiplayer.set_multiplayer_peer(peer)
	
	$Player_UI.show()
	$Menu_UI.hide()

func create_player(id):
	var spawn_points = get_node("SpawnPoints").get_children()
	var spawn_pos = spawn_points[randi() % spawn_points.size()].global_position
	var p = PLAYER.instantiate()
	p.name = str(id)
	$Players.add_child(p)
	p.set_position_with_rpc.rpc(spawn_pos)

func destroy_player(id):
	$Players.get_node(str(id)).queue_free()

func server_disconnected():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	$Player_UI.hide()
	$Menu_UI.show()
