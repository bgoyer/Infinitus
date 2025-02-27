extends Node
class_name ResourceManager

# Dictionary of loaded resources
var _resources: Dictionary = {}
# Dictionary to track reference counts for each resource
var _reference_counts: Dictionary = {}
# Dictionary to track when resources were last accessed
var _last_accessed: Dictionary = {}

# Flag to enable background loading
var _background_loading: bool = true
# Maximum number of resources to keep in memory
var _max_resources: int = 100

signal resource_loaded(path, resource)
signal resource_unloaded(path)

func _ready() -> void:
	# Start a timer to periodically check for unused resources
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 60  # Check every minute
	timer.one_shot = false
	timer.timeout.connect(_check_unused_resources)
	timer.start()

# Load a resource synchronously
func load_resource(path: String) -> Resource:
	if _resources.has(path):
		_reference_counts[path] += 1
		_last_accessed[path] = Time.get_ticks_msec()
		return _resources[path]
	
	# If we've reached the maximum number of resources, unload the least recently used
	if _resources.size() >= _max_resources:
		_unload_least_recently_used()
	
	var resource = load(path)
	if resource:
		_resources[path] = resource
		_reference_counts[path] = 1
		_last_accessed[path] = Time.get_ticks_msec()
	
	return resource

# Load a resource asynchronously - returns the resource when loaded
# In Godot 4.3, this should be marked as async to use await
func load_resource_async(path: String) -> Resource:
	if _resources.has(path):
		_reference_counts[path] += 1
		_last_accessed[path] = Time.get_ticks_msec()
		resource_loaded.emit(path, _resources[path])
		return _resources[path]
	
	if _resources.size() >= _max_resources:
		_unload_least_recently_used()
	
	var loader_status = ResourceLoader.load_threaded_request(path)
	
	if loader_status == OK:
		var resource = await _monitor_resource_loading(path)
		return resource
	else:
		push_error("Failed to start threaded loading for resource: " + path)
		return null

# Release a resource when it's no longer needed
func release_resource(path: String) -> void:
	if _resources.has(path):
		_reference_counts[path] -= 1
		
		# If reference count reaches 0, consider unloading later
		if _reference_counts[path] <= 0:
			_reference_counts[path] = 0

# Forcefully unload a resource
func unload_resource(path: String) -> void:
	if _resources.has(path):
		_resources.erase(path)
		_reference_counts.erase(path)
		_last_accessed.erase(path)
		resource_unloaded.emit(path)

# Check if a resource is loaded
func is_resource_loaded(path: String) -> bool:
	return _resources.has(path)

# Get the total number of loaded resources
func get_loaded_resource_count() -> int:
	return _resources.size()

# Monitor the status of an asynchronously loading resource
# This is a coroutine that returns the loaded resource when complete
func _monitor_resource_loading(path: String) -> Resource:
	while true:
		var loading_status = ResourceLoader.load_threaded_get_status(path)
		
		match loading_status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var resource = ResourceLoader.load_threaded_get(path)
				_resources[path] = resource
				_reference_counts[path] = 1
				_last_accessed[path] = Time.get_ticks_msec()
				resource_loaded.emit(path, resource)
				return resource
				
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load resource: " + path)
				return null
				
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Invalid resource: " + path)
				return null
		
		await get_tree().process_frame
	return

# Unload the least recently used resource
func _unload_least_recently_used() -> void:
	var oldest_time = Time.get_ticks_msec()
	var oldest_path = ""
	
	for path in _last_accessed:
		if _reference_counts[path] <= 0 and _last_accessed[path] < oldest_time:
			oldest_time = _last_accessed[path]
			oldest_path = path
	
	if oldest_path != "":
		unload_resource(oldest_path)

# Periodically check for unused resources
func _check_unused_resources() -> void:
	var current_time = Time.get_ticks_msec()
	var unused_threshold = 5 * 60 * 1000  # 5 minutes in milliseconds
	
	var paths_to_unload = []
	
	for path in _resources:
		if _reference_counts[path] <= 0 and (current_time - _last_accessed[path]) > unused_threshold:
			paths_to_unload.append(path)
	
	for path in paths_to_unload:
		unload_resource(path)

# Helper method to preload multiple resources in parallel
func preload_resources(paths: Array) -> Dictionary:
	var results = {}
	var loading_tasks = []
	
	for path in paths:
		loading_tasks.append(await load_resource_async(path))
	
	# Wait for all resources to load
	for i in range(paths.size()):
		var resource = await loading_tasks[i]
		results[paths[i]] = resource
	
	return results
