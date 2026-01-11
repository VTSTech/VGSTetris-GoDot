# Main.gd - VGS-Tetris: Complete Tetris Implementation
# VTSTech Game Studios - GoDot Engine 4
extends Node2D

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

# Game Version Information
const VERSION = "0.4"
const BUILD_DATE = "01.11.2026.1426\nwww.VTS-Tech.org"
const GAME_TITLE = "VGSTetris"

# Game Grid Configuration
const GRID_WIDTH = 10
const GRID_HEIGHT = 20
const CELL_SIZE = 32

# Scoring System (Classic Tetris)
const SCORE_VALUES = [0, 40, 100, 300, 1200]  # Points for 0, 1, 2, 3, 4 lines

# NEW: Particle effect configuration
const PARTICLE_COLORS = [
	Color(1.0, 0.0, 0.0, 1.0),     # Red
	Color(0.0, 1.0, 0.0, 1.0),     # Green
	Color(0.0, 0.0, 1.0, 1.0),     # Blue
	Color(1.0, 1.0, 0.0, 1.0),     # Yellow
	Color(1.0, 0.0, 1.0, 1.0),     # Magenta
	Color(0.0, 1.0, 1.0, 1.0),     # Cyan
	Color(1.0, 0.5, 0.0, 1.0)      # Orange
]

# ============================================================================
# GAME STATE VARIABLES
# ============================================================================

# Core Game State
var grid = []                    # 2D array representing the game board
var current_piece = null         # Currently active falling piece
var next_piece_data = {}         # Data for the next piece preview
var game_over = false            # Game over flag
var paused = false               # Pause state flag

# Game Statistics
var score = 0                    # Current player score
var level = 1                    # Current game level (affects speed)
var lines_cleared = 0            # Total lines cleared
var fall_speed = 1.0             # Base falling speed in seconds
var game_time = 0.0              # Game timer in seconds

# UI References
var score_label = null
var level_label = null
var lines_label = null
var game_over_label = null
var pause_menu = null
var fall_speed_label = null      # Fall speed display
var game_time_label = null       # Game timer display

# System Components
var fall_timer = null            # Timer for automatic piece falling
var splash_screen = null         # Initial splash screen
var splash_timer = null          # Splash screen timer
var game_timer = null            # Game duration timer

# NEW: Screen effect components
var screen_effect_timer = null   # Timer for screen effects
var screen_effect_active = false # Whether screen effect is active
var screen_effect_intensity = 0.0 # Current effect intensity

# Calculated Positions
var piece_spawn_position = Vector2(GRID_WIDTH / 2 * CELL_SIZE - CELL_SIZE, 0)

# Soft drop state variable
var soft_drop_active = false     # Whether down arrow is being held for soft drop

# ============================================================================
# TETROMINO SHAPE DEFINITIONS
# ============================================================================

# All 7 Tetromino shapes with their colors and rotation states
const TETROMINO_SHAPES = {
	"I": {  # Cyan I-piece (straight)
		"color": Color.CYAN,
		"shape": [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)]
	},
	"O": {  # Yellow O-piece (square)
		"color": Color.YELLOW,
		"shape": [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
	},
	"T": {  # Purple T-piece
		"color": Color.PURPLE,
		"shape": [Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]
	},
	"S": {  # Green S-piece
		"color": Color.GREEN,
		"shape": [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1)]
	},
	"Z": {  # Red Z-piece
		"color": Color.RED,
		"shape": [Vector2(0, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(1, 1)]
	},
	"J": {  # Blue J-piece
		"color": Color.BLUE,
		"shape": [Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(1, -1)]
	},
	"L": {  # Orange L-piece
		"color": Color.ORANGE,
		"shape": [Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1)]
	}
}

# ============================================================================
# CORE GAME FUNCTIONS
# ============================================================================

func _ready():
	"""Initialize the game when the scene loads."""
	print("Tetris Game Starting...")
	print("%s v%s (Build: %s)" % [GAME_TITLE, VERSION, BUILD_DATE.replace("\n", " ")])
	
	_setup_game_window()
	show_splash_screen()

func _setup_game_window():
	"""Configure the game window size and position."""
	var ui_width = 250  # Increased for better UI spacing
	var total_width = GRID_WIDTH * CELL_SIZE + ui_width
	var total_height = GRID_HEIGHT * CELL_SIZE  # Extra height for UI
	
	# Set window size and center on screen
	get_tree().root.size = Vector2i(total_width, total_height)
	get_tree().root.position = Vector2i(
		(DisplayServer.screen_get_size().x - total_width) / 2,
		(DisplayServer.screen_get_size().y - total_height) / 2
	)

# ----------------------------------------------------------------------------
# GAME INITIALIZATION
# ----------------------------------------------------------------------------

func initialize_grid():
	"""Create and initialize the game grid."""
	grid = []
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append(null)  # null = empty cell
		grid.append(row)

func generate_next_piece():
	"""Randomly select and prepare the next Tetromino piece."""
	var shape_keys = TETROMINO_SHAPES.keys()
	var random_shape = shape_keys[randi() % shape_keys.size()]
	var shape_data = TETROMINO_SHAPES[random_shape]
	
	next_piece_data = {
		"type": random_shape,
		"shape": shape_data["shape"].duplicate(),
		"color": shape_data["color"]
	}

func spawn_piece():
	"""Create and position a new Tetromino piece."""
	if game_over:
		return
	
	# Generate first piece if needed
	if current_piece == null and next_piece_data.is_empty():
		generate_next_piece()
	
	# Instantiate new piece
	current_piece = preload("res://Scenes/Tetromino.tscn").instantiate()
	current_piece.position = piece_spawn_position
	current_piece.cell_size = CELL_SIZE
	
	# Initialize with next piece data
	if not next_piece_data.is_empty():
		current_piece.initialize_shape(next_piece_data["type"])
	
	add_child(current_piece)
	generate_next_piece()  # Prepare next piece
	
	# Check for immediate game over (piece spawns in occupied space)
	if check_collision(current_piece.position, current_piece.get_shape()):
		game_over = true
		if fall_timer:
			fall_timer.stop()
		if game_timer:
			game_timer.stop()
		if game_over_label:
			game_over_label.show()
	
	queue_redraw()

func setup_fall_timer():
	"""Create and configure the automatic falling timer."""
	if fall_timer == null:
		fall_timer = Timer.new()
		fall_timer.name = "FallTimer"
		fall_timer.wait_time = fall_speed
		fall_timer.timeout.connect(_on_fall_timer_timeout)
		add_child(fall_timer)
	
	fall_timer.start()

func setup_game_timer():
	"""Create and configure the game duration timer."""
	if game_timer == null:
		game_timer = Timer.new()
		game_timer.name = "GameTimer"
		game_timer.wait_time = 1.0  # Update every second
		game_timer.timeout.connect(_on_game_timer_timeout)
		add_child(game_timer)
	
	game_timer.start()

func setup_screen_effect_timer():
	"""NEW: Create and configure the screen effect timer."""
	if screen_effect_timer == null:
		screen_effect_timer = Timer.new()
		screen_effect_timer.name = "ScreenEffectTimer"
		screen_effect_timer.wait_time = 0.05  # Update every frame (50ms)
		screen_effect_timer.timeout.connect(_on_screen_effect_timer_timeout)
		add_child(screen_effect_timer)

# ----------------------------------------------------------------------------
# GAME LOGIC FUNCTIONS
# ----------------------------------------------------------------------------

func check_collision(position: Vector2, shape: Array) -> bool:
	"""
	Check if a piece would collide at the given position.
	
	Args:
		position: World position to check
		shape: Array of Vector2 cell offsets
		
	Returns:
		bool: True if collision detected
	"""
	for cell in shape:
		var grid_x = int((position.x / CELL_SIZE) + cell.x)
		var grid_y = int((position.y / CELL_SIZE) + cell.y)
		
		# Boundary checks
		if grid_x < 0 or grid_x >= GRID_WIDTH or grid_y >= GRID_HEIGHT:
			return true
		
		# Occupied cell check
		if grid_y >= 0 and grid[grid_y][grid_x] != null:
			return true
	
	return false

func try_move(offset: Vector2) -> bool:
	"""Attempt to move current piece by offset, returns success status."""
	var new_position = current_piece.position + offset
	if not check_collision(new_position, current_piece.get_shape()):
		current_piece.position = new_position
		queue_redraw()
		return true
	return false

func rotate_piece():
	"""Rotate current piece with basic wall kick collision resolution."""
	var original_shape = current_piece.get_shape().duplicate()
	current_piece.rotate_piece()
	
	# Wall kick: try adjusting position if rotation causes collision
	if check_collision(current_piece.position, current_piece.get_shape()):
		# Try moving right
		current_piece.position.x += CELL_SIZE
		if check_collision(current_piece.position, current_piece.get_shape()):
			# Try moving left twice (for more aggressive wall kick)
			current_piece.position.x -= CELL_SIZE * 2
			if check_collision(current_piece.position, current_piece.get_shape()):
				# Revert rotation if no wall kick works
				current_piece.position.x += CELL_SIZE
				current_piece.rotate_piece(false)
				return
	
	queue_redraw()

func lock_piece():
	"""Transfer current piece to the grid and prepare next piece."""
	# Get piece color safely
	var piece_color = _get_piece_color(current_piece)
	
	# Add piece cells to grid
	for cell in current_piece.get_shape():
		var grid_x = int((current_piece.position.x / CELL_SIZE) + cell.x)
		var grid_y = int((current_piece.position.y / CELL_SIZE) + cell.y)
		
		if grid_y >= 0 and grid_x >= 0 and grid_x < GRID_WIDTH:
			grid[grid_y][grid_x] = piece_color
	
	# Clean up and continue
	current_piece.queue_free()
	current_piece = null
	
	check_lines()
	spawn_piece()
	queue_redraw()

func check_lines():
	"""Check for and clear completed lines."""
	# Find lines to clear
	var lines_to_clear = PackedInt32Array()
	for y in range(GRID_HEIGHT):
		var line_full = true
		for x in range(GRID_WIDTH):
			if grid[y][x] == null:
				line_full = false
				break
		
		if line_full:
			lines_to_clear.append(y)
	
	# If no lines, return
	if lines_to_clear.size() == 0:
		return
	
	# Sort in reverse order (bottom to top)
	lines_to_clear.sort()
	var lines_cleared_count = lines_to_clear.size()
	
	# NEW: Trigger particle effects before clearing lines
	_trigger_line_clear_effects(lines_to_clear, lines_cleared_count)
	
	# NEW: Trigger screen shake effect for Tetris (4 lines)
	if lines_cleared_count == 4:
		_trigger_tetris_effect()
	
	# Create new grid without cleared lines
	var new_grid = []
	for y in range(GRID_HEIGHT):
		if not y in lines_to_clear:
			new_grid.append(grid[y].duplicate())
	
	# Add empty lines at top
	for i in range(lines_cleared_count):
		var empty_row = []
		for x in range(GRID_WIDTH):
			empty_row.append(null)
		new_grid.insert(0, empty_row)
	
	# Replace grid
	grid = new_grid
	
	# Update score
	update_score(lines_cleared_count)

func update_score(lines_cleared_count: int):
	"""Update score, level, and game speed based on lines cleared."""
	score += SCORE_VALUES[lines_cleared_count] * level
	lines_cleared += lines_cleared_count
	level = int(lines_cleared / 10) + 1  # Level up every 10 lines
	
	# Increase speed with level (cap at 0.05 seconds per cell)
	var normal_speed = max(0.05, 1.0 - (level - 1) * 0.1)
	
	if fall_timer:
		# If soft drop is active, use soft drop speed, otherwise use normal speed
		if soft_drop_active:
			fall_timer.wait_time = 0.05  # Fast drop for soft drop
		else:
			fall_timer.wait_time = normal_speed
	
	# Update UI
	if score_label:
		score_label.text = "Score: " + str(score)
	if level_label:
		level_label.text = "Level: " + str(level)
	if lines_label:
		lines_label.text = "Lines: " + str(lines_cleared)
	
	# Update fall speed display
	if fall_speed_label:
		fall_speed_label.text = "Speed: %.2fs/cell" % normal_speed

# ----------------------------------------------------------------------------
# PARTICLE EFFECTS FUNCTIONS
# ----------------------------------------------------------------------------

func _trigger_line_clear_effects(lines_to_clear: PackedInt32Array, lines_cleared_count: int):
	"""NEW: Trigger particle effects for line clears."""
	# Create a particle system for each cleared line
	for y in lines_to_clear:
		_create_line_particles(y, lines_cleared_count)

func _create_line_particles(line_y: int, lines_cleared_count: int):
	"""Create particle effects for a cleared line."""
	# Determine effect intensity based on number of lines cleared
	var particle_count = 20 + (lines_cleared_count * 10)
	var particle_size = 4.0 + (lines_cleared_count * 2.0)
	
	# Create particle system
	var particles = GPUParticles2D.new()
	particles.position = Vector2(GRID_WIDTH * CELL_SIZE / 2, line_y * CELL_SIZE + CELL_SIZE / 2)
	particles.amount = particle_count
	particles.lifetime = 1.5
	particles.explosiveness = 0.3
	particles.emitting = true
	
	# Configure particle material
	var material = ParticleProcessMaterial.new()
	
	# Set direction and spread - these are the correct properties in Godot 4
	material.direction = Vector3(0, -1, 0)  # Downward direction (negative Y)
	material.spread = 180.0  # Half circle spread (more controlled than 360)
	
	# Set velocity - use min/max in Godot 4
	var velocity = 50 + (lines_cleared_count * 20)
	material.initial_velocity_min = velocity * 0.8
	material.initial_velocity_max = velocity * 1.2
	
	# Set gravity (simpler approach)
	material.gravity = Vector3(0, 300, 0)
	
	# Set damping
	material.damping_min = 5.0
	material.damping_max = 15.0
	
	# Set scale/size
	material.scale_min = particle_size * 0.5
	material.scale_max = particle_size * 1.5
	
	# Set emission shape
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents.x = GRID_WIDTH * CELL_SIZE / 2
	material.emission_box_extents.y = CELL_SIZE / 2
	
	# Choose color based on number of lines
	var base_color = PARTICLE_COLORS[lines_cleared_count % PARTICLE_COLORS.size()]
	material.color = base_color
	
	# Add color ramp for fading
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, base_color)
	color_ramp.set_color(1, Color(base_color.r, base_color.g, base_color.b, 0))
	material.color_ramp = color_ramp
	
	particles.process_material = material
	add_child(particles)
	
	# Auto-remove particles after they finish
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

func _trigger_tetris_effect():
	"""NEW: Trigger special effects for Tetris (4 lines cleared)."""
	# Screen shake
	_start_screen_shake(0.5, 10.0)
	
	# Flash effect
	_start_screen_flash(Color(0.8, 0.8, 1.0, 0.3), 0.3)
	
	# Extra particles
	_create_tetris_particles()

func _create_tetris_particles():
	"""Create special Tetris particle effects."""
	# Create multiple particle systems for dramatic effect
	for i in range(3):
		var particles = GPUParticles2D.new()
		particles.position = Vector2(GRID_WIDTH * CELL_SIZE / 2, GRID_HEIGHT * CELL_SIZE / 2)
		particles.amount = 100
		particles.lifetime = 2.0
		particles.explosiveness = 0.1
		particles.emitting = true
		
		var material = ParticleProcessMaterial.new()
		
		# Set direction and spread
		material.direction = Vector3(0, -1, 0)  # Downward
		material.spread = 360.0  # Full circle for explosion effect
		
		# Set velocity
		var velocity_base = 100 + (i * 20)
		material.initial_velocity_min = velocity_base
		material.initial_velocity_max = velocity_base + 50
		
		# Set gravity
		material.gravity = Vector3(0, 100, 0)
		
		# Set damping
		material.damping_min = 2.0
		material.damping_max = 6.0
		
		# Set scale
		material.scale_min = 4.0
		material.scale_max = 12.0
		
		# Rainbow colors for Tetris
		var color_index = i % PARTICLE_COLORS.size()
		material.color = PARTICLE_COLORS[color_index]
		
		var color_ramp = Gradient.new()
		color_ramp.set_color(0, material.color)
		color_ramp.set_color(1, Color(material.color.r, material.color.g, material.color.b, 0))
		material.color_ramp = color_ramp
		
		particles.process_material = material
		add_child(particles)
		
		# Auto-remove particles
		await get_tree().create_timer(2.5).timeout
		particles.queue_free()

func _start_screen_shake(duration: float, intensity: float):
	"""Start screen shake effect."""
	screen_effect_active = true
	screen_effect_intensity = intensity
	
	if not screen_effect_timer:
		setup_screen_effect_timer()
	
	if not screen_effect_timer.is_stopped():
		screen_effect_timer.stop()
	
	screen_effect_timer.start()
	
	# Stop shake after duration
	await get_tree().create_timer(duration).timeout
	screen_effect_active = false
	screen_effect_intensity = 0.0
	if screen_effect_timer:
		screen_effect_timer.stop()
	
	# Reset position
	position = Vector2.ZERO

func _start_screen_flash(color: Color, duration: float):
	"""Create a screen flash effect."""
	var flash = ColorRect.new()
	flash.color = color
	flash.size = get_viewport_rect().size
	flash.z_index = 10  # Draw on top of everything
	
	var canvas = CanvasLayer.new()
	canvas.layer = 99
	canvas.add_child(flash)
	add_child(canvas)
	
	# Fade out and remove
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "color", Color(color.r, color.g, color.b, 0), duration)
	await tween.finished
	
	canvas.queue_free()

# ----------------------------------------------------------------------------
# INPUT HANDLING
# ----------------------------------------------------------------------------

func _input(event):
	"""Process player input."""
	# Pause handling (always processed)
	if event.is_action_pressed("pause"):
		toggle_pause()
		return
	
	if paused:
		return
	
	# Game over handling
	if game_over:
		if event.is_action_pressed("restart"):
			restart_game()
		return
	
	if game_over or !current_piece:
		return
	
	# Movement controls
	if event.is_action_pressed("ui_left"):
		try_move(Vector2(-CELL_SIZE, 0))
	elif event.is_action_pressed("ui_right"):
		try_move(Vector2(CELL_SIZE, 0))
	elif event.is_action_pressed("ui_down"):
		# Start soft drop
		if not soft_drop_active:
			soft_drop_active = true
			_update_fall_speed()
	elif event.is_action_released("ui_down"):
		# End soft drop
		if soft_drop_active:
			soft_drop_active = false
			_update_fall_speed()
	
	# Rotation
	if event.is_action_pressed("ui_up"):
		rotate_piece()
	
	# Hard drop
	if event.is_action_pressed("ui_accept"):  # Space bar
		hard_drop()

func _update_fall_speed():
	"""Update fall speed based on soft drop state."""
	if not fall_timer or game_over or paused:
		return
	
	if soft_drop_active:
		fall_timer.wait_time = 0.05  # Fast drop (20x faster)
	else:
		var normal_speed = max(0.05, 1.0 - (level - 1) * 0.1)
		fall_timer.wait_time = normal_speed
	
	# Update fall speed display
	if fall_speed_label:
		if soft_drop_active:
			fall_speed_label.text = "Speed: 0.05s/cell (SOFT DROP)"
		else:
			fall_speed_label.text = "Speed: %.2fs/cell" % fall_timer.wait_time

func move_down():
	"""Move piece down one cell, locking if collision occurs."""
	if not try_move(Vector2(0, CELL_SIZE)):
		lock_piece()

func hard_drop():
	"""Instantly drop piece to lowest possible position."""
	while try_move(Vector2(0, CELL_SIZE)):
		pass
	lock_piece()

# ----------------------------------------------------------------------------
# GAME STATE MANAGEMENT
# ----------------------------------------------------------------------------

func restart_game():
	"""Reset game to initial state."""
	# Reset game state
	initialize_grid()
	score = 0
	level = 1
	lines_cleared = 0
	game_over = false
	game_time = 0.0  # Reset game timer
	soft_drop_active = false  # Reset soft drop state
	screen_effect_active = false  # NEW: Reset screen effects
	screen_effect_intensity = 0.0  # NEW: Reset screen effect intensity
	
	# Reset position (in case screen shake was active)
	position = Vector2.ZERO
	
	# Clean up current piece
	if current_piece:
		current_piece.queue_free()
		current_piece = null
	
	# Reset next piece
	next_piece_data = {}
	
	# Clear pause state
	if paused:
		hide_pause_menu()
		paused = false
		get_tree().paused = false
	
	# Update UI
	if score_label:
		score_label.text = "Score: 0"
	if level_label:
		level_label.text = "Level: 1"
	if lines_label:
		lines_label.text = "Lines: 0"
	if game_over_label:
		game_over_label.hide()
	
	# Update timer display
	if game_time_label:
		game_time_label.text = "Time: 00:00"
	
	# Update fall speed display
	if fall_speed_label:
		fall_speed_label.text = "Speed: 1.00s/cell"
	
	# Restart timer
	if fall_timer:
		fall_timer.wait_time = 1.0
		fall_timer.start()
	else:
		setup_fall_timer()
	
	# Restart game timer
	if game_timer:
		game_timer.stop()
		game_timer.start()
	else:
		setup_game_timer()
	
	# Stop screen effect timer
	if screen_effect_timer:
		screen_effect_timer.stop()
	
	# Start new game
	generate_next_piece()
	spawn_piece()

func toggle_pause():
	"""Toggle game pause state."""
	paused = !paused
	
	if paused:
		show_pause_menu()
		get_tree().paused = true
		if game_timer:
			game_timer.paused = true
		if fall_timer:
			fall_timer.paused = true
		if screen_effect_timer:
			screen_effect_timer.paused = true
	else:
		hide_pause_menu()
		get_tree().paused = false
		if game_timer:
			game_timer.paused = false
		if fall_timer:
			fall_timer.paused = false
		if screen_effect_timer:
			screen_effect_timer.paused = false

# ============================================================================
# UI MANAGEMENT
# ============================================================================

func create_ui_labels():
	"""Create and position all UI elements."""
	var ui_start_x = GRID_WIDTH * CELL_SIZE + 20
	
	# Title Label (only used locally, so use var)
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = GAME_TITLE + " v" + VERSION + "\nGoDot Edition"
	title_label.position = Vector2(ui_start_x, 10)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(title_label)
	
	# Score Label (needed globally for updates, so assign to class variable)
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.position = Vector2(ui_start_x, 80)
	score_label.add_theme_font_size_override("font_size", 18)
	add_child(score_label)
	
	# Level Label (needed globally for updates)
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Level: 1"
	level_label.position = Vector2(ui_start_x, 110)
	level_label.add_theme_font_size_override("font_size", 18)
	add_child(level_label)
	
	# Lines Label (needed globally for updates)
	lines_label = Label.new()
	lines_label.name = "LinesLabel"
	lines_label.text = "Lines: 0"
	lines_label.position = Vector2(ui_start_x, 140)
	lines_label.add_theme_font_size_override("font_size", 18)
	add_child(lines_label)
	
	# Fall Speed Label
	fall_speed_label = Label.new()
	fall_speed_label.name = "FallSpeedLabel"
	fall_speed_label.text = "Speed: 1.00s/cell"
	fall_speed_label.position = Vector2(ui_start_x, 170)
	fall_speed_label.add_theme_font_size_override("font_size", 18)
	fall_speed_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	add_child(fall_speed_label)
	
	# Game Time Label
	game_time_label = Label.new()
	game_time_label.name = "GameTimeLabel"
	game_time_label.text = "Time: 00:00"
	game_time_label.position = Vector2(ui_start_x, 200)
	game_time_label.add_theme_font_size_override("font_size", 18)
	game_time_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	add_child(game_time_label)
	
	# Game Over Label (needed globally)
	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.text = "GAME OVER\nPress R to restart"
	game_over_label.position = Vector2(GRID_WIDTH * CELL_SIZE / 2 - 100, GRID_HEIGHT * CELL_SIZE / 2 - 50)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.size = Vector2(200, 100)
	game_over_label.add_theme_font_size_override("font_size", 24)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.hide()
	add_child(game_over_label)
	
	# Studio Label (local only)
	var studio_label = Label.new()
	studio_label.name = "StudioLabel"
	studio_label.text = "VTSTech Game Studios"
	studio_label.position = Vector2(ui_start_x, GRID_HEIGHT * CELL_SIZE - 60)
	studio_label.add_theme_font_size_override("font_size", 14)
	studio_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 0.9))
	add_child(studio_label)
	
	# Build Label (local only)
	var build_label = Label.new()
	build_label.name = "BuildLabel"
	build_label.text = "Build: " + BUILD_DATE
	build_label.position = Vector2(ui_start_x, GRID_HEIGHT * CELL_SIZE - 40)
	build_label.add_theme_font_size_override("font_size", 12)
	build_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))
	add_child(build_label)

# ----------------------------------------------------------------------------
# PAUSE MENU
# ----------------------------------------------------------------------------

func show_pause_menu():
	"""Display the pause menu overlay."""
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.name = "PauseCanvas"
	
	pause_menu = ColorRect.new()
	pause_menu.color = Color(0, 0, 0, 0.7)
	pause_menu.size = get_viewport_rect().size
	
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.size = Vector2(400, 300)
	pause_menu.add_child(container)
	
	# Create pause menu labels
	var pause_label = Label.new()
	pause_label.name = "PauseLabel"
	pause_label.text = "GAME PAUSED"
	pause_label.add_theme_font_size_override("font_size", 36)
	pause_label.add_theme_color_override("font_color", Color.YELLOW)
	container.add_child(pause_label)
	
	# Display current game time in pause menu
	var time_label = Label.new()
	time_label.name = "PauseTime"
	time_label.text = "Current Time: " + _format_time(game_time)
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(time_label)
	
	var version_label = Label.new()
	version_label.name = "PauseVersion"
	version_label.text = "%s v%s" % [GAME_TITLE, VERSION]
	version_label.add_theme_font_size_override("font_size", 18)
	version_label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(version_label)
	
	var build_label = Label.new()
	build_label.name = "PauseBuild"
	build_label.text = "Build: " + BUILD_DATE.replace("\n", " ")
	build_label.add_theme_font_size_override("font_size", 14)
	build_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	container.add_child(build_label)
	
	var resume_label = Label.new()
	resume_label.name = "PauseResume"
	resume_label.text = "Press P to Resume"
	resume_label.add_theme_font_size_override("font_size", 20)
	resume_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	container.add_child(resume_label)
	
	# Center container
	container.position = Vector2(
		(pause_menu.size.x - container.size.x) / 2,
		(pause_menu.size.y - container.size.y) / 2
	)
	
	canvas.add_child(pause_menu)
	add_child(canvas)

func hide_pause_menu():
	"""Remove the pause menu."""
	var canvas = get_node_or_null("PauseCanvas")
	if canvas:
		canvas.queue_free()
	pause_menu = null

# ----------------------------------------------------------------------------
# SPLASH SCREEN
# ----------------------------------------------------------------------------

func show_splash_screen():
	"""Display the initial splash screen."""
	splash_screen = ColorRect.new()
	splash_screen.color = Color(0.1, 0.1, 0.2, 1.0)
	splash_screen.size = get_viewport_rect().size
	
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.size = Vector2(400, 300)  # Give it a size
	splash_screen.add_child(container)
	
	# Create labels with proper positioning
	var title = Label.new()
	title.name = "SplashTitle"
	title.text = GAME_TITLE
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.YELLOW)
	container.add_child(title)
	
	var version = Label.new()
	version.name = "SplashVersion"
	version.text = "Version " + VERSION
	version.add_theme_font_size_override("font_size", 24)
	version.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(version)
	
	var build = Label.new()
	build.name = "SplashBuild"
	build.text = "Build: " + BUILD_DATE
	build.add_theme_font_size_override("font_size", 18)
	build.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	container.add_child(build)
	
	var loading = Label.new()
	loading.name = "SplashLoading"
	loading.text = "Loading..."
	loading.add_theme_font_size_override("font_size", 20)
	loading.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	container.add_child(loading)
	
	# Center the container in the splash screen
	container.position = Vector2(
		(splash_screen.size.x - container.size.x) / 2,
		(splash_screen.size.y - container.size.y) / 2
	)
	
	add_child(splash_screen)
	
	# Setup splash timer
	splash_timer = Timer.new()
	splash_timer.wait_time = 2.0
	splash_timer.one_shot = true
	splash_timer.timeout.connect(_on_splash_timeout)
	add_child(splash_timer)
	splash_timer.start()

func _on_splash_timeout():
	"""Handle splash screen completion."""
	if splash_screen:
		splash_screen.queue_free()
		splash_screen = null
	if splash_timer:
		splash_timer.queue_free()
		splash_timer = null
	
	start_game()

func start_game():
	"""Initialize and start the main game after splash screen."""
	initialize_grid()
	create_ui_labels()
	setup_fall_timer()
	setup_game_timer()  # Start game timer
	generate_next_piece()
	spawn_piece()

# ============================================================================
# RENDERING FUNCTIONS
# ============================================================================

func _draw():
	"""Render the game grid, pieces, and UI elements."""
	_draw_grid()
	_draw_grid_cells()
	_draw_current_piece()
	draw_next_piece_preview()
	_draw_ghost_piece()

func _draw_grid():
	"""Draw the game grid lines."""
	for x in range(GRID_WIDTH + 1):
		draw_line(
			Vector2(x * CELL_SIZE, 0),
			Vector2(x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE),
			Color(0.0, 0.0, 0.0, 0.5)
		)
	
	for y in range(GRID_HEIGHT + 1):
		draw_line(
			Vector2(0, y * CELL_SIZE),
			Vector2(GRID_WIDTH * CELL_SIZE, y * CELL_SIZE),
			Color(0.0, 0.0, 0.0, 0.5)
		)

func _draw_grid_cells():
	"""Draw all locked pieces in the grid."""
	# Ensure grid has correct structure
	_validate_grid_structure()
	
	# Draw each cell
	for y in range(min(GRID_HEIGHT, grid.size())):
		_ensure_row_width(y)
		
		for x in range(min(GRID_WIDTH, grid[y].size())):
			if grid[y][x]:
				draw_rect(
					Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE),
					grid[y][x]
				)
				draw_rect(
					Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE),
					Color(1.0, 1.0, 1.0, 0.4),
					false,
					1.0
				)

func _draw_current_piece():
	"""Draw the currently active falling piece."""
	if not current_piece:
		return
	
	var shape_array = current_piece.get_shape() if current_piece.has_method("get_shape") else []
	if shape_array.is_empty():
		return
	
	var piece_color = _get_piece_color(current_piece)
	
	for cell in shape_array:
		var pos = current_piece.position + cell * CELL_SIZE
		draw_rect(
			Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)),
			piece_color
		)
		draw_rect(
			Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(1.0, 1.0, 1.0, 0.6),
			false,
			2.0
		)

func _draw_ghost_piece():
	"""Draw a semi-transparent ghost piece showing where current piece will land."""
	if not current_piece or game_over or paused:
		return
	
	var shape_array = current_piece.get_shape() if current_piece.has_method("get_shape") else []
	if shape_array.is_empty():
		return
	
	var piece_color = _get_piece_color(current_piece)
	var ghost_position = current_piece.position
	
	# Find landing position
	for i in range(GRID_HEIGHT * 2):  # Changed _ to i (limit iterations)
		var test_position = ghost_position + Vector2(0, CELL_SIZE)
		if check_collision(test_position, shape_array):
			break
		ghost_position = test_position
	
	# Draw ghost cells
	for cell in shape_array:
		var pos = ghost_position + cell * CELL_SIZE
		draw_rect(
			Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)),
			Color(piece_color.r, piece_color.g, piece_color.b, 0.3)
		)

func draw_next_piece_preview():
	"""Draw the next piece preview in the UI area."""
	if next_piece_data.is_empty() or not next_piece_data.has("shape"):
		return
	
	var shape = next_piece_data["shape"]
	var color = next_piece_data.get("color", Color.WHITE)
	var preview_x = GRID_WIDTH * CELL_SIZE + 30
	var preview_y = 240
	var preview_cell_size = CELL_SIZE * 0.7
	
	# Preview background
	draw_rect(
		Rect2(preview_x - 10, preview_y - 10, 140, 140),
		Color(0.15, 0.15, 0.15, 0.8),
		true
	)
	draw_rect(
		Rect2(preview_x - 10, preview_y - 10, 140, 140),
		Color(0.8, 0.8, 0.8, 1.0),
		false,
		2.0
	)
	
	# Calculate bounds for centering
	var bounds = _calculate_shape_bounds(shape)
	if not bounds:
		return
	
	var shape_width = (bounds.max_x - bounds.min_x + 1) * preview_cell_size
	var shape_height = (bounds.max_y - bounds.min_y + 1) * preview_cell_size
	
	# Center and draw shape
	var center_x = preview_x + (140 - shape_width) / 2
	var center_y = preview_y + (140 - shape_height) / 2
	
	for cell in shape:
		var pos_x = center_x + (cell.x - bounds.min_x) * preview_cell_size
		var pos_y = center_y + (cell.y - bounds.min_y) * preview_cell_size
		
		draw_rect(
			Rect2(pos_x, pos_y, preview_cell_size, preview_cell_size),
			color
		)
		draw_rect(
			Rect2(pos_x, pos_y, preview_cell_size, preview_cell_size),
			Color(1.0, 1.0, 1.0, 0.4),
			false,
			1.0
		)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func _get_piece_color(piece) -> Color:
	"""Safely get color from a Tetromino piece."""
	if piece.has_method("get_color"):
		return piece.get_color()
	elif "color" in piece:
		return piece.color
	return Color.WHITE

func _calculate_shape_bounds(shape: Array) -> Dictionary:
	"""Calculate min/max bounds of a shape array."""
	if shape.is_empty():
		return {}
	
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for cell in shape:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	
	return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}

func _validate_grid_structure():
	"""Ensure grid has correct dimensions."""
	if grid.size() != GRID_HEIGHT:
		while grid.size() < GRID_HEIGHT:
			var new_row = []
			for col in range(GRID_WIDTH):  # FIXED: Changed _ to col
				new_row.append(null)
			grid.append(new_row)
		while grid.size() > GRID_HEIGHT:
			grid.pop_back()

func _ensure_row_width(row_index: int):
	"""Ensure a grid row has correct width."""
	if row_index >= grid.size():
		return
	
	if grid[row_index].size() != GRID_WIDTH:
		while grid[row_index].size() < GRID_WIDTH:
			grid[row_index].append(null)
		while grid[row_index].size() > GRID_WIDTH:
			grid[row_index].pop_back()

func _format_time(seconds: float) -> String:
	"""Format seconds into MM:SS format."""
	var minutes = int(seconds) / 60
	var remaining_seconds = int(seconds) % 60
	return "%02d:%02d" % [minutes, remaining_seconds]

# ============================================================================
# TIMER CALLBACKS
# ============================================================================

func _on_fall_timer_timeout():
	"""Handle automatic piece falling."""
	if game_over or !current_piece:
		return
	move_down()

func _on_game_timer_timeout():
	"""Handle game timer update."""
	if not game_over and not paused:
		game_time += 1.0
		if game_time_label:
			game_time_label.text = "Time: " + _format_time(game_time)

func _on_screen_effect_timer_timeout():
	"""NEW: Handle screen shake effect updates."""
	if screen_effect_active and screen_effect_intensity > 0:
		# Apply random offset for screen shake
		var shake_offset = Vector2(
			randf_range(-screen_effect_intensity, screen_effect_intensity),
			randf_range(-screen_effect_intensity, screen_effect_intensity)
		)
		position = shake_offset
		
		# Gradually reduce intensity
		screen_effect_intensity *= 0.9

func _process(delta):
	"""Handle soft drop (holding down arrow)."""
	if not fall_timer:
		return
	
	if Input.is_action_pressed("ui_down") and not game_over and not paused:
		# Soft drop already handled by input system
		pass
