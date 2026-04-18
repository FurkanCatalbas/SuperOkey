class_name HandView
extends HBoxContainer

@export var tile_scene: PackedScene = preload("res://scenes/ui/TileWiev.tscn")

func render_tiles(tiles: Array) -> void:
	for child in get_children():
		child.queue_free()

	for tile in tiles:
		var tile_view = tile_scene.instantiate()
		tile_view.setup(tile)
		add_child(tile_view)
