extends Node
class_name GameManager

# Singleton instance
static var instance: GameManager

# Core systems
var error_handler: ErrorHandler
var scene_manager: SceneManager
var resource_manager: ResourceManager
var physics_optimizer: PhysicsOptimizer
var item_data_system: ItemDataSystem
var ai_factory: AIFactory
# Performance monitoring
var fps_tracker: Array = []
var frame_times: Array = []
var performance_report_interval: float = 60.0 # Report every 60 seconds
var performance_timer: float = 0.0
var memory_usage_history: Array = []

# Mobile detection and quality settings
var is_mobile: bool = false
var is_low_end_device: bool = false
var quality_level: int = 2 # 0 = low, 1 = medium, 2 = high
var target_fps: int = 60

# Space world settings
var world_size: Vector2 = Vector2(50000, 50000)
var auto_optimization: bool = true

# Player reference
var player: Player
var player_ship: Ship

signal performance_report_generated(report)

func _init() -> void:
	if instance == null:
		instance = self
	else:
		push_error("GameManager instance already exists!")

func _ready() -> void:

	# Detect platform and set initial quality
	_detect_platform()
	
	# Initialize core systems
	_initialize_systems()
	
	# Connect to necessary signals
	get_tree().node_added.connect(_on_node_added)
	
	# Start performance monitoring
	set_process(true)

func _process(delta: float) -> void:
	# Track FPS for performance monitoring
	var current_fps = Engine.get_frames_per_second()
	fps_tracker.append(current_fps)
	
	if fps_tracker.size() > 60:
		fps_tracker.pop_front()
	
	# Track frame time
	var frame_time = delta * 1000.0 # Convert to milliseconds
	frame_times.append(frame_time)
	
	if frame_times.size() > 60:
		frame_times.pop_front()
	
	# Track memory usage - using the correct Godot 4.3 functions
	var memory_usage = {
		"total_memory": OS.get_static_memory_usage() / (1024.0 * 1024.0), # MB
		"available_static": OS.get_memory_info()["free"] / (1024.0 * 1024.0), # MB
		"time": Time.get_unix_time_from_system()
	}
	memory_usage_history.append(memory_usage)
	
	if memory_usage_history.size() > 60:
		memory_usage_history.pop_front()
	
	# Generate performance report periodically
	performance_timer += delta
	if performance_timer >= performance_report_interval:
		_generate_performance_report()
		performance_timer = 0.0
	
	# If auto optimization is enabled, adjust quality settings based on performance
	if auto_optimization:
		_auto_optimize(delta)

# Initialize all core systems
func _initialize_systems() -> void:
	# Create ErrorHandler
	error_handler = ErrorHandler.new()
	add_child(error_handler)
	
	# Create SceneManager
	scene_manager = SceneManager.new()
	add_child(scene_manager)
	
	# Create ResourceManager
	resource_manager = ResourceManager.new()
	add_child(resource_manager)
	
	# Create PhysicsOptimizer
	physics_optimizer = PhysicsOptimizer.new()
	add_child(physics_optimizer)
	
	# Initialize ItemDataSystem
	item_data_system = ItemDataSystem.new()
	add_child(item_data_system)
	
	ai_factory = AIFactory.new()
	add_child(ai_factory)
	
	# Set initial quality settings
	_apply_quality_settings()

# Detect platform and hardware capabilities
func _detect_platform() -> void:
	# Check if mobile platform
	is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	
	# Try to detect hardware capabilities
	var processor_count = OS.get_processor_count()
	var memory_info = OS.get_memory_info()
	var memory_mb = memory_info["total"] / (1024 * 1024) if memory_info.has("total") else 4096
	
	# Estimate if we're on a low-end device
	if is_mobile and (processor_count <= 4 or memory_mb < 2048):
		is_low_end_device = true
		quality_level = 0 # Set to low quality for low-end mobile
	elif is_mobile:
		quality_level = 1 # Medium quality for other mobile
	else:
		quality_level = 2 # High quality for desktop
	
	# Set target FPS based on platform
	if is_mobile:
		if is_low_end_device:
			target_fps = 30
		else:
			target_fps = 60
	else:
		target_fps = 60
	
	# Apply FPS limit
	Engine.max_fps = target_fps

# Apply quality settings based on quality level
func _apply_quality_settings() -> void:
	match quality_level:
		0: # Low
			# Physics settings
			Engine.physics_ticks_per_second = 30
			PhysicsServer2D.set_active(true)
			physics_optimizer.physics_culling_distance = 3000.0
			physics_optimizer.physics_pause_distance = 6000.0
			
			# Visual settings
			get_viewport().msaa_2d = Viewport.MSAA_DISABLED
			get_viewport().use_debanding = false
			
			# Custom settings for your game
			if physics_optimizer:
				physics_optimizer.distant_update_interval = 15
			
		1: # Medium
			# Physics settings
			Engine.physics_ticks_per_second = 60
			PhysicsServer2D.set_active(true)
			physics_optimizer.physics_culling_distance = 4000.0
			physics_optimizer.physics_pause_distance = 8000.0
			
			# Visual settings
			get_viewport().msaa_2d = Viewport.MSAA_2X
			get_viewport().use_debanding = true
			
			# Custom settings for your game
			if physics_optimizer:
				physics_optimizer.distant_update_interval = 10
			
		2: # High
			# Physics settings
			Engine.physics_ticks_per_second = 60
			PhysicsServer2D.set_active(true)
			physics_optimizer.physics_culling_distance = 5000.0
			physics_optimizer.physics_pause_distance = 10000.0
			
			# Visual settings
			get_viewport().msaa_2d = Viewport.MSAA_4X
			get_viewport().use_debanding = true
			
			# Custom settings for your game
			if physics_optimizer:
				physics_optimizer.distant_update_interval = 5

# Auto-optimize quality settings based on performance
func _auto_optimize(delta: float) -> void:
	# Only adjust settings if we have enough data
	if fps_tracker.size() < 60:
		return
	
	# Calculate average FPS
	var avg_fps = 0.0
	for fps in fps_tracker:
		avg_fps += fps
	avg_fps /= fps_tracker.size()
	
	# Check if we need to adjust quality
	if avg_fps < target_fps * 0.8 and quality_level > 0:
		# FPS is too low, decrease quality
		quality_level -= 1
		_apply_quality_settings()
		ErrorHandler.info("GameManager", "Decreased quality level to " + str(quality_level) + " due to low FPS: " + str(avg_fps))
	elif avg_fps > target_fps * 0.95 and quality_level < 2:
		# FPS is good, try to increase quality
		quality_level += 1
		_apply_quality_settings()
		ErrorHandler.info("GameManager", "Increased quality level to " + str(quality_level) + " due to good FPS: " + str(avg_fps))

# Generate a performance report
func _generate_performance_report() -> void:
	if fps_tracker.size() == 0:
		return
	
	# Calculate average FPS
	var avg_fps = 0.0
	for fps in fps_tracker:
		avg_fps += fps
	avg_fps /= fps_tracker.size()
	
	# Calculate FPS variability (standard deviation)
	var fps_variance = 0.0
	for fps in fps_tracker:
		fps_variance += (fps - avg_fps) * (fps - avg_fps)
	fps_variance /= fps_tracker.size()
	var fps_std_dev = sqrt(fps_variance)
	
	# Calculate frame time statistics
	var avg_frame_time = 0.0
	var min_frame_time = 1000.0
	var max_frame_time = 0.0
	
	for time in frame_times:
		avg_frame_time += time
		min_frame_time = min(min_frame_time, time)
		max_frame_time = max(max_frame_time, time)
	
	if frame_times.size() > 0:
		avg_frame_time /= frame_times.size()
	
	# Get memory usage
	var current_memory = memory_usage_history.back() if memory_usage_history.size() > 0 else {"total_memory": 0, "available_static": 0}
	
	# Create the report
	var report = {
		"fps": {
			"average": avg_fps,
			"std_dev": fps_std_dev,
			"target": target_fps
		},
		"frame_time": {
			"average_ms": avg_frame_time,
			"min_ms": min_frame_time,
			"max_ms": max_frame_time
		},
		"memory": {
			"total_mb": current_memory.total_memory,
			"available_mb": current_memory.available_static
		},
		"quality": {
			"level": quality_level,
			"platform": OS.get_name(),
			"is_mobile": is_mobile,
			"is_low_end": is_low_end_device
		},
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Emit signal with the report
	performance_report_generated.emit(report)
	
	# Log report to console if in debug mode
	if OS.is_debug_build():
		print("Performance Report: ", JSON.stringify(report, "  "))

# Handle new nodes added to the scene
func _on_node_added(node: Node) -> void:
	if node is Player:
		player = node
		if physics_optimizer:
			physics_optimizer.set_tracked_node(player)
	elif node is Ship and player and node.get_parent() == player:
		player_ship = node

# Set quality level manually
func set_quality_level(level: int) -> void:
	quality_level = clamp(level, 0, 2)
	_apply_quality_settings()
	auto_optimization = false # Disable auto-optimization when manually setting quality

# Toggle auto-optimization
func toggle_auto_optimization(enabled: bool) -> void:
	auto_optimization = enabled
