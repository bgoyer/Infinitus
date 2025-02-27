extends Node
class_name PhysicsOptimizer

# Distance from camera/player beyond which physics processing is simplified
@export var physics_culling_distance: float = 5000.0
# Distance from camera/player beyond which physics processing is paused
@export var physics_pause_distance: float = 10000.0
# How often to update distant objects (frames)
@export var distant_update_interval: int = 10
# Current player or camera reference
var tracked_node: Node2D
# Frame counter for update intervals
var frame_counter: int = 0
# Dictionary tracking nodes and their original physics states
var tracked_physics_nodes: Dictionary = {}
# Dictionary for spatial partitioning optimization
var spatial_grid: Dictionary = {}
# Grid cell size for spatial partitioning
var grid_cell_size: float = 1000.0

# Signals
signal physics_object_culled(node)
signal physics_object_unculled(node)

func _ready() -> void:
	# Register physics bodies for tracking
	call_deferred("_register_physics_nodes")
	# Set up processing
	set_physics_process(true)

func set_tracked_node(node: Node2D) -> void:
	tracked_node = node

func _physics_process(_delta: float) -> void:
	if tracked_node == null:
		# Try to find the player or camera if not set
		tracked_node = _find_tracked_node()
		if tracked_node == null:
			return
	
	frame_counter += 1
	
	# Process physics optimization
	for node_ref in tracked_physics_nodes.keys():
		var node = node_ref
		
		if not is_instance_valid(node):
			# Remove invalid nodes
			tracked_physics_nodes.erase(node_ref)
			continue
		
		var distance = tracked_node.global_position.distance_to(node.global_position)
		var node_data = tracked_physics_nodes[node_ref]
		
		if distance > physics_pause_distance:
			# Beyond pause distance - pause physics processing completely
			if node_data.active:
				_pause_physics(node)
				node_data.active = false
				emit_signal("physics_object_culled", node)
		elif distance > physics_culling_distance:
			# In simplified distance range - process at intervals
			if frame_counter % distant_update_interval == 0:
				if not node_data.active:
					_resume_physics(node)
					node_data.active = true
					emit_signal("physics_object_unculled", node)
				
				# Use simplified physics for distant objects
				if node is RigidBody2D:
					node.linear_damp = node_data.original_linear_damp * 5.0
				elif node is CharacterBody2D:
					# Still process but with potential simplifications
					pass
			else:
				if node_data.active:
					_pause_physics(node)
					node_data.active = false
		else:
			# Within active distance - normal physics processing
			if not node_data.active:
				_resume_physics(node)
				node_data.active = true
				emit_signal("physics_object_unculled", node)
			
			# Restore original physics properties
			if node is RigidBody2D:
				node.linear_damp = node_data.original_linear_damp
	
	# Wrap frame counter
	if frame_counter >= 60:
		frame_counter = 0
	
	# Update spatial grid every 10 frames for efficiency
	if frame_counter % 10 == 0:
		_update_spatial_grid()

# Register all physics nodes in the scene for optimization
func _register_physics_nodes() -> void:
	var nodes = _get_all_physics_nodes(get_tree().root)
	
	for node in nodes:
		_add_physics_node(node)
	
	# Connect to tree signals to track new nodes
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)

# Add a physics node to the tracking system
func _add_physics_node(node: Node) -> void:
	if node is RigidBody2D or node is CharacterBody2D or node is Ship:
		var node_data = {
			"active": true,
			"original_mode": null,
			"original_linear_damp": 0.0,
			"original_angular_damp": 0.0,
			"type": "unknown"
		}
		
		if node is RigidBody2D:
			node_data.type = "rigid_body"
			node_data.original_mode = node.freeze_mode
			node_data.original_linear_damp = node.linear_damp
			node_data.original_angular_damp = node.angular_damp
		elif node is CharacterBody2D or node is Ship:
			node_data.type = "character_body"
		
		tracked_physics_nodes[node] = node_data

# Pause physics processing for a node
func _pause_physics(node: Node) -> void:
	var node_data = tracked_physics_nodes[node]
	
	if node is RigidBody2D:
		# Save current values if needed
		node_data.original_linear_damp = node.linear_damp
		node_data.original_angular_damp = node.angular_damp
		
		# Pause the rigid body
		node.freeze = true
	elif node is CharacterBody2D or node is Ship:
		# For character bodies, we can disable physics processing
		node.set_physics_process(false)

# Resume physics processing for a node
func _resume_physics(node: Node) -> void:
	var node_data = tracked_physics_nodes[node]
	
	if node is RigidBody2D:
		# Resume the rigid body
		node.freeze = false
		
		# Restore original values
		node.linear_damp = node_data.original_linear_damp
		node.angular_damp = node_data.original_angular_damp
	elif node is CharacterBody2D or node is Ship:
		# Re-enable physics processing
		node.set_physics_process(true)

# Update the spatial grid for faster spatial queries
func _update_spatial_grid() -> void:
	spatial_grid.clear()
	
	for node_ref in tracked_physics_nodes.keys():
		var node = node_ref
		
		if is_instance_valid(node):
			# Calculate grid cell coordinates
			var cell_x = floor(node.global_position.x / grid_cell_size)
			var cell_y = floor(node.global_position.y / grid_cell_size)
			var cell_key = Vector2(cell_x, cell_y)
			
			# Add to spatial grid
			if not spatial_grid.has(cell_key):
				spatial_grid[cell_key] = []
			
			spatial_grid[cell_key].append(node)

# Find nodes within a radius using spatial grid for efficiency
func get_nodes_in_radius(position: Vector2, radius: float) -> Array:
	var result = []
	
	# Calculate grid cells that overlap with the radius
	var min_cell_x = floor((position.x - radius) / grid_cell_size)
	var max_cell_x = floor((position.x + radius) / grid_cell_size)
	var min_cell_y = floor((position.y - radius) / grid_cell_size)
	var max_cell_y = floor((position.y + radius) / grid_cell_size)
	
	for cell_x in range(min_cell_x, max_cell_x + 1):
		for cell_y in range(min_cell_y, max_cell_y + 1):
			var cell_key = Vector2(cell_x, cell_y)
			
			if spatial_grid.has(cell_key):
				for node in spatial_grid[cell_key]:
					if position.distance_to(node.global_position) <= radius:
						result.append(node)
	
	return result

# Find all physics nodes in the scene
func _get_all_physics_nodes(node: Node) -> Array:
	var nodes = []
	
	if node is RigidBody2D or node is CharacterBody2D or node is Ship:
		nodes.append(node)
	
	for child in node.get_children():
		nodes.append_array(_get_all_physics_nodes(child))
	
	return nodes

# Find a node to track (player or camera)
func _find_tracked_node() -> Node2D:
	# Try to find player first
	var player = get_tree().get_nodes_in_group("player")
	if player.size() > 0:
		return player[0]
	
	# Try to find camera
	var camera = get_tree().get_nodes_in_group("camera")
	if camera.size() > 0:
		return camera[0]
	
	# As fallback, find any Camera2D
	camera = get_tree().get_nodes_in_group("Camera2D")
	if camera.size() > 0:
		return camera[0]
	
	return null

# Handle new nodes added to the scene
func _on_node_added(node: Node) -> void:
	if node is RigidBody2D or node is CharacterBody2D or node is Ship:
		_add_physics_node(node)

# Handle nodes removed from the scene
func _on_node_removed(node: Node) -> void:
	if tracked_physics_nodes.has(node):
		tracked_physics_nodes.erase(node)
