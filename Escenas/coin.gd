extends Area2D

signal coin_collected

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody2D:
		coin_collected.emit()
		queue_free()
		
func _process(_delta):
	scale.x = cos(Time.get_ticks_msec() * 0.005)   # efecto de giro 2D
