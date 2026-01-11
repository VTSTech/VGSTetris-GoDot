# Tetromino.gd - Tetromino Piece Implementation
# VTSTech Game Studios - GoDot Engine 4
extends Node2D

# ============================================================================
# TETROMINO DEFINITIONS
# ============================================================================

# All 7 Tetromino shapes with colors and rotation states
const SHAPES = {
	"I": {  # Cyan I-piece (straight) - 2 rotations
		"color": Color.CYAN,
		"rotations": [
			[Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],  # Horizontal
			[Vector2(0, -1), Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)]   # Vertical
		]
	},
	"O": {  # Yellow O-piece (square) - 1 rotation (doesn't rotate)
		"color": Color.YELLOW,
		"rotations": [
			[Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
		]
	},
	"T": {  # Purple T-piece - 4 rotations
		"color": Color.PURPLE,
		"rotations": [
			[Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)],  # T up
			[Vector2(0, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 0)],   # T right
			[Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1)],   # T down
			[Vector2(0, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0)]   # T left
		]
	},
	"S": {  # Green S-piece - 2 rotations
		"color": Color.GREEN,
		"rotations": [
			[Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1)],
			[Vector2(0, 0), Vector2(0, -1), Vector2(1, 0), Vector2(1, 1)]
		]
	},
	"Z": {  # Red Z-piece - 2 rotations
		"color": Color.RED,
		"rotations": [
			[Vector2(0, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(1, 1)],
			[Vector2(0, 0), Vector2(0, -1), Vector2(-1, 0), Vector2(-1, 1)]
		]
	},
	"J": {  # Blue J-piece - 4 rotations
		"color": Color.BLUE,
		"rotations": [
			[Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(1, -1)],
			[Vector2(0, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1)],
			[Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1)],
			[Vector2(0, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1)]
		]
	},
	"L": {  # Orange L-piece - 4 rotations
		"color": Color.ORANGE,
		"rotations": [
			[Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1)],
			[Vector2(0, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, -1)],
			[Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, -1)],
			[Vector2(0, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, 1)]
		]
	}
}

# ============================================================================
# PROPERTIES
# ============================================================================

var shape_type = "O"          # Current shape type (I, O, T, S, Z, J, L)
var rotation_index = 0        # Current rotation state index
var cell_size = 32            # Size of each cell in pixels

# ============================================================================
# PUBLIC METHODS
# ============================================================================

func initialize_shape(type: String):
	"""
	Initialize tetromino with specified shape type.
	
	Args:
		type: Shape type string (I, O, T, S, Z, J, L)
	"""
	if SHAPES.has(type):
		shape_type = type
	else:
		shape_type = "O"  # Default to O-piece
	rotation_index = 0

func get_shape() -> Array:
	"""
	Get the current shape cells as offsets from piece center.
	
	Returns:
		Array: Duplicate array of Vector2 cell positions
	"""
	if not SHAPES.has(shape_type):
		return []
	
	var rotations = SHAPES[shape_type]["rotations"]
	if rotation_index < rotations.size():
		return rotations[rotation_index].duplicate()
	return []

func get_color() -> Color:
	"""
	Get the color associated with current shape type.
	
	Returns:
		Color: Shape color or white as fallback
	"""
	if SHAPES.has(shape_type):
		return SHAPES[shape_type]["color"]
	return Color.WHITE

func rotate_piece(clockwise: bool = true) -> Array:
	"""
	Rotate the piece clockwise or counter-clockwise.
	
	Args:
		clockwise: Direction of rotation (true = clockwise)
		
	Returns:
		Array: New shape after rotation
	"""
	if not SHAPES.has(shape_type):
		return []
	
	var rotations = SHAPES[shape_type]["rotations"]
	var rotation_count = rotations.size()
	
	# O-piece doesn't rotate (only 1 rotation state)
	if rotation_count <= 1:
		return get_shape()
	
	# Calculate new rotation index with wrap-around
	if clockwise:
		rotation_index = (rotation_index + 1) % rotation_count
	else:
		rotation_index = (rotation_index - 1 + rotation_count) % rotation_count
	
	return get_shape()
