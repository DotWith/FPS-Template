extends Control

@onready
var ip_address_field = $VBoxContainer/IPAddress

func _on_create_server_pressed():
	get_parent().start_network_server()

func _on_join_server_pressed():
	get_parent().start_network_client(ip_address_field.text)
