extends Control

func _ready():
	Global.update_health.connect(self._update_health)

func _update_health(new_health):
	$Health.value = new_health
