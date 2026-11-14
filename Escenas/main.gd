extends Node2D

@export var platform_scene: PackedScene
var last_platform_y = 0

func _ready():
	for i in range(10):
		spawn_platform(Vector2(randf_range(50, 670), 1000 - (i * 150)))

func spawn_platform(pos: Vector2):
	var plat = platform_scene.instantiate()
	plat.global_position = pos
	add_child(plat)
	last_platform_y = pos.y

func _on_timer_timeout():
	var new_y = last_platform_y - randf_range(120, 200) 
	var new_x = randf_range(50, 670)
	spawn_platform(Vector2(new_x, new_y))
