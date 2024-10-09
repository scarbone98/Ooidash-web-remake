extends Node2D

@export var items: Array[ItemData] = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_asteroid_spawner_asteroids_spawned(asteroids: Array, speed: float) -> void:
	for item in items:
		if randf() <= item.spawn_probability:
			var item_node = item.item_scene.instantiate()
			item_node.move_speed = speed
			item_node.position = asteroids[randi_range(0, asteroids.size() - 1)]
			add_child(item_node)
