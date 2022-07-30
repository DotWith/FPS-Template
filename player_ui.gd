extends Control

@onready
var ui_health = $Health

var health = 100 :
	get:
		return health
	set(value):
		ui_health.text = str(value)
		health = value
