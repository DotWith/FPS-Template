extends Control

# The player scene (which we want to configure for replication).
const Player = preload("res://player.tscn")

# The game scene
const Level = preload("res://game.tscn")

var level_instance

@onready
var ip_address_field = $VBoxContainer/IPAddress

func _on_create_server_pressed():
	start_network(true)
	hide()

func _on_join_server_pressed():
	start_network(false)
	hide()

func start_network(server: bool):
	var peer = ENetMultiplayerPeer.new()
	
	# Listen to peer connections, and create new player for them
	multiplayer.peer_connected.connect(self.create_player)
	# Listen to peer disconnections, and destroy their players
	multiplayer.peer_disconnected.connect(self.destroy_player)
	# Listen to server dissconnections, and revert any changes
	multiplayer.server_disconnected.connect(self.server_disconnected)
	
	if server:
		peer.create_server(4242)
	else:
		peer.create_client(ip_address_field.text, 4242)

	multiplayer.set_multiplayer_peer(peer)
	
	# We want to spawn our player
	create_player(multiplayer.get_unique_id())
	create_level()

func create_player(id):
	# Instantiate a new player for this client.
	var p = Player.instantiate()
	# Set the authority
	p.set_multiplayer_authority(id)
	# Set a random position (sent on every replicator update).
	p.position = Vector3(0, 10, 0)
	# Add it to the "Players" node.
	# We give the new Node a name for easy retrieval, but that's not necessary.
	p.name = str(id)
	Players.add_child(p)

func destroy_player(id):
	# Delete this peer's node.
	Players.get_node(str(id)).queue_free()

func create_level():
	level_instance = Level.instantiate()
	get_tree().get_root().add_child(level_instance)

func destroy_level():
	level_instance.queue_free()

func server_disconnected():
	for player in Players.get_children():
		player.queue_free()
	destroy_level()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()
