class_name TableGridView
extends GridContainer

@export var cell_scene: PackedScene = preload("res://scenes/ui/TableCell.tscn")

signal tile_selected(tile: GameTileData, row: int, column: int)
signal tile_dropped(data: Dictionary, row: int, column: int)

var _cells: Array = []

func _ready() -> void:
	columns = GameConstants.TABLE_COLUMNS
	_create_cells()

func render_table(table_data: Array, selected_tile_id: String, highlight_map: Dictionary) -> void:
	for row in range(GameConstants.TABLE_ROWS):
		for column in range(GameConstants.TABLE_COLUMNS):
			var cell: TableCell = _cells[row][column]
			var tile: GameTileData = table_data[row][column]
			var key = _cell_key(row, column)
			var state = highlight_map.get(key, "normal")
			cell.render_tile(tile, selected_tile_id, state)

func _create_cells() -> void:
	for child in get_children():
		child.queue_free()
	_cells.clear()
	for row in range(GameConstants.TABLE_ROWS):
		var row_cells: Array = []
		for column in range(GameConstants.TABLE_COLUMNS):
			var cell: TableCell = cell_scene.instantiate()
			cell.setup(row, column)
			cell.tile_selected.connect(_on_tile_selected)
			cell.tile_dropped.connect(_on_tile_dropped)
			add_child(cell)
			row_cells.append(cell)
		_cells.append(row_cells)

func _on_tile_selected(tile: GameTileData, row: int, column: int) -> void:
	tile_selected.emit(tile, row, column)

func _on_tile_dropped(data: Dictionary, row: int, column: int) -> void:
	tile_dropped.emit(data, row, column)

func _cell_key(row: int, column: int) -> String:
	return "%d:%d" % [row, column]
