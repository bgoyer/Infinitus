extends Node
class_name ObjectPool

# The scene to instantiate
var _scene: PackedScene
# Array of available objects
var _available_objects: Array = []
# Parent node for the objects
var _parent_node: Node

# Maximum number of objects in the pool
var _max_size: int = 100
# Automatic expansion size when pool is empty
var _expansion_size: int = 10

# Initialize the pool
func _init(scene: PackedScene, parent: Node, initial_size: int = 10, max_size: int = 100, expansion_size: int = 10) -> void:
	_scene = scene
	_parent_node = parent
	_max_size = max_size
	_expansion_size = expansion_size
	
	# Pre-instantiate initial objects
	_expand_pool(initial_size)

# Get an object from the pool
func get_object() -> Node:
	if _available_objects.is_empty():
		# Automatically expand the pool if empty (up to max size)
		var expansion_amount = min(_expansion_size, _max_size - count_total())
		if expansion_amount > 0:
			_expand_pool(expansion_amount)
		else:
			# If we can't expand, try to recycle the oldest active object
			return _recycle_oldest()
	
	if _available_objects.is_empty():
		push_warning("Object pool depleted and cannot expand further")
		return null
	
	# Get an object from the pool and activate it
	var object = _available_objects.pop_back()
	object.visible = true
	
	# If the object has a "reset" method, call it
	if object.has_method("reset"):
		object.reset()
	
	return object

# Return an object to the pool
func return_object(object: Node) -> void:
	if object == null:
		return
		
	# Disable the object
	object.visible = false
	
	# Add specific deactivation logic here (e.g., stop particles, disable physics)
	if object is RigidBody2D:
		object.set_physics_process(false)
	
	# Add back to the available objects
	_available_objects.append(object)

# Expand the pool by creating more objects
func _expand_pool(amount: int) -> void:
	for i in range(amount):
		var object = _scene.instantiate()
		_parent_node.add_child(object)
		object.visible = false
		
		# Disable physics processing for performance
		if object is RigidBody2D:
			object.set_physics_process(false)
			
		_available_objects.append(object)

# Recycle the oldest active object when pool is full
func _recycle_oldest() -> Node:
	# Find an active object to recycle
	for child in _parent_node.get_children():
		if child.visible and child.get_script() == _scene.get_script():
			child.visible = false
			# If the object has a "reset" method, call it
			if child.has_method("reset"):
				child.reset()
			return child
	
	# If no objects found to recycle
	return null

# Get the total number of objects in the pool (both available and in use)
func count_total() -> int:
	var count = 0
	for child in _parent_node.get_children():
		if child.get_script() == _scene.get_script():
			count += 1
	return count

# Get the number of available objects
func count_available() -> int:
	return _available_objects.size()

# Clear the entire pool
func clear() -> void:
	for object in _available_objects:
		object.queue_free()
	_available_objects.clear()
