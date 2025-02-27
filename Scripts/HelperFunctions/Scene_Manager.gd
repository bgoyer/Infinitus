extends Node
class_name SceneManager

# Singleton pattern
static var instance: SceneManager

# Current scene reference
var current_scene: Node
# Previous scene for back operations
var previous_scene: String = ""
# Scene transition settings
var transition_speed: float = 0.5
# Flag for scene loading in progress
var is_loading: bool = false

# Dictionary to store scene cache
var scene_cache: Dictionary = {}
# Dictionary to track scene load times for analytics
var scene_load_times: Dictionary = {}

# Signals
signal scene_changing(from_scene, to_scene)
signal scene_changed(scene_name)
signal scene_load_started(scene_name)
signal scene_load_progress(scene_name, progress)
signal scene_load_completed(scene_name, load_time)

func _init() -> void:
	if instance == null:
		instance = self
	else:
		push_error("SceneManager instance already exists!")

func _ready() -> void:
	# Get the current scene
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

# Change scene with optional transition
func change_scene(scene_path: String, transition: bool = true) -> void:
	if is_loading:
		return
	
	is_loading = true
	previous_scene = current_scene.scene_file_path
	
	emit_signal("scene_changing", current_scene.scene_file_path, scene_path)
	emit_signal("scene_load_started", scene_path)
	
	# Handle transition
	if transition:
		# Animate transition here if needed
		await _fade_out()
	
	var load_start_time = Time.get_ticks_msec()
	
	# Try to use cached scene first
	if scene_cache.has(scene_path):
		_set_new_scene(scene_cache[scene_path])
		var load_time = Time.get_ticks_msec() - load_start_time
		scene_load_times[scene_path] = load_time
		emit_signal("scene_load_completed", scene_path, load_time)
	else:
		# Load scene resource
		var new_scene = load(scene_path)
		
		if new_scene:
			# Instantiate the new scene
			var scene_instance = new_scene.instantiate()
			_set_new_scene(scene_instance)
			
			var load_time = Time.get_ticks_msec() - load_start_time
			scene_load_times[scene_path] = load_time
			emit_signal("scene_load_completed", scene_path, load_time)
		else:
			push_error("Failed to load scene: " + scene_path)
			is_loading = false
	
	if transition:
		await _fade_in()
	
	is_loading = false
	emit_signal("scene_changed", scene_path)

# Preload a scene into cache for faster loading
func preload_scene(scene_path: String) -> bool:
	if scene_cache.has(scene_path):
		return true
	
	var scene_resource = load(scene_path)
	if scene_resource:
		scene_cache[scene_path] = scene_resource.instantiate()
		return true
	
	return false

# Change scene using async loading for large scenes
func change_scene_async(scene_path: String, transition: bool = true) -> void:
	if is_loading:
		return
	
	is_loading = true
	previous_scene = current_scene.scene_file_path
	
	emit_signal("scene_changing", current_scene.scene_file_path, scene_path)
	emit_signal("scene_load_started", scene_path)
	
	# Handle transition
	if transition:
		await _fade_out()
	
	var load_start_time = Time.get_ticks_msec()
	
	var loader = ResourceLoader.load_threaded_request(scene_path)
	
	if loader == OK:
		while true:
			var progress = []
			var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
			
			match status:
				ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					emit_signal("scene_load_progress", scene_path, progress[0])
					
				ResourceLoader.THREAD_LOAD_LOADED:
					var scene_resource = ResourceLoader.load_threaded_get(scene_path)
					var scene_instance = scene_resource.instantiate()
					_set_new_scene(scene_instance)
					
					var load_time = Time.get_ticks_msec() - load_start_time
					scene_load_times[scene_path] = load_time
					emit_signal("scene_load_completed", scene_path, load_time)
					break
					
				ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
					push_error("Failed to load scene: " + scene_path)
					is_loading = false
					break
			
			await get_tree().process_frame
	else:
		push_error("Failed to start threaded loading for scene: " + scene_path)
		is_loading = false
	
	if transition:
		await _fade_in()
	
	is_loading = false
	emit_signal("scene_changed", scene_path)

# Go back to the previous scene
func go_back(transition: bool = true) -> void:
	if previous_scene != "":
		change_scene(previous_scene, transition)

# Set the new scene as current
func _set_new_scene(new_scene: Node) -> void:
	# Free the current scene
	current_scene.queue_free()
	
	# Add the new scene to the tree
	var root = get_tree().root
	root.add_child(new_scene)
	
	# Set it as the current scene
	current_scene = new_scene
	
	# Optional: Initialize the new scene if it has a custom initialization method
	if current_scene.has_method("initialize"):
		current_scene.initialize()

# Fade out transition effect
func _fade_out() -> void:
	# Create a CanvasLayer with a ColorRect for fading
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.size = get_viewport().size
	fade_layer.add_child(fade_rect)
	
	# Animate the fade
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), transition_speed)
	await tween.finished
	
	# Keep the fade layer for fade_in

# Fade in transition effect
func _fade_in() -> void:
	# Find the fade layer we created in _fade_out
	var fade_layer = get_node_or_null("CanvasLayer")
	if fade_layer:
		var fade_rect = fade_layer.get_node("ColorRect")
		if fade_rect:
			# Animate the fade
			var tween = create_tween()
			tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), transition_speed)
			await tween.finished
			
			# Remove the fade layer
			fade_layer.queue_free()

# Get scene load statistics
func get_load_statistics() -> Dictionary:
	var stats = {
		"total_scenes_loaded": scene_load_times.size(),
		"average_load_time": 0.0,
		"max_load_time": 0.0,
		"min_load_time": INF if scene_load_times.size() > 0 else 0.0,
		"scene_details": scene_load_times
	}
	
	var total_time = 0.0
	for scene_path in scene_load_times:
		var load_time = scene_load_times[scene_path]
		total_time += load_time
		stats.max_load_time = max(stats.max_load_time, load_time)
		stats.min_load_time = min(stats.min_load_time, load_time)
	
	if scene_load_times.size() > 0:
		stats.average_load_time = total_time / scene_load_times.size()
	
	return stats

# Clear the scene cache to free memory
func clear_cache() -> void:
	for scene_path in scene_cache:
		var scene = scene_cache[scene_path]
		if is_instance_valid(scene) and scene != current_scene:
			scene.queue_free()
	
	scene_cache.clear()

# Reload the current scene
func reload_current_scene(transition: bool = true) -> void:
	if current_scene and current_scene.scene_file_path:
		change_scene(current_scene.scene_file_path, transition)
