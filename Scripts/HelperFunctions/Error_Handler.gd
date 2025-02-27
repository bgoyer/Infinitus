extends Node
class_name ErrorHandler

# Singleton pattern
static var instance: ErrorHandler

# Define error levels
enum ErrorLevel {
	INFO,
	WARNING,
	ERROR,
	CRITICAL
}

# Error log structure
var error_log: Array = []
# Max log entries to prevent memory leaks
var max_log_size: int = 100
# Should errors be printed to console
var print_to_console: bool = true
# Should critical errors trigger a crash report
var report_critical_errors: bool = true

# Signals
signal error_occurred(error_info)
signal critical_error_occurred(error_info)

func _init() -> void:
	if instance == null:
		instance = self
	else:
		push_error("ErrorHandler instance already exists!")

func _ready() -> void:
	# Set up error handling for the entire engine
	get_tree().debug_collisions_hint = true
	
	# Connect to built-in Godot signals
	get_tree().node_added.connect(_on_node_added)
	
	# Override the engine's error handling
	if OS.is_debug_build():
		Engine.print_error_messages = true
	else:
		Engine.print_error_messages = false

# Log an error with a specific level
func log_error(level: ErrorLevel, source: String, message: String, details: Dictionary = {}) -> void:
	var timestamp = Time.get_unix_time_from_system()
	
	var error_info = {
		"level": level,
		"source": source,
		"message": message,
		"details": details,
		"timestamp": timestamp,
		"stack_trace": get_stack()
	}
	
	# Keep log size under control
	if error_log.size() >= max_log_size:
		error_log.pop_front()
	
	error_log.append(error_info)
	
	# Emit signal for any error listeners
	error_occurred.emit(error_info)
	
	# Handle based on error level
	match level:
		ErrorLevel.INFO:
			if print_to_console:
				print("INFO [%s]: %s" % [source, message])
				
		ErrorLevel.WARNING:
			if print_to_console:
				push_warning("WARNING [%s]: %s" % [source, message])
				
		ErrorLevel.ERROR:
			if print_to_console:
				push_error("ERROR [%s]: %s" % [source, message])
				
		ErrorLevel.CRITICAL:
			if print_to_console:
				push_error("CRITICAL [%s]: %s" % [source, message])
			
			critical_error_occurred.emit(error_info)
			
			if report_critical_errors:
				_create_crash_report(error_info)

# Monitor new nodes for potential errors
func _on_node_added(node: Node) -> void:
	# In Godot 4.3, we need to check if the node has a script first
	if node.get_script() and node.get_script().has_script_signal("script_error"):
		# Try to connect to the script_error signal if available
		if node.has_signal("script_error"):
			if not node.is_connected("script_error", Callable(self, "_on_script_error")):
				node.connect("script_error", Callable(self, "_on_script_error").bind(node))

# Handle script errors
func _on_script_error(node: Node) -> void:
	log_error(ErrorLevel.ERROR, node.name, "Script error in node", {"node_path": str(node.get_path())})

# Create a crash report
func _create_crash_report(error_info: Dictionary) -> void:
	# Make sure the user directory exists
	DirAccess.make_dir_recursive_absolute("user://crash_reports")
	
	# Create a unique filename with timestamp
	var filename = "user://crash_reports/crash_report_%s.json" % Time.get_unix_time_from_system()
	
	# Try to open the file
	var file = FileAccess.open(filename, FileAccess.WRITE)
	
	if file:
		# Collect system info with error handling for API differences
		var system_info = {
			"os_name": OS.get_name(),
			"model_name": OS.get_model_name(),
			"godot_version": Engine.get_version_info()
		}
		
		# Try to add video adapter info if available
		var adapter_info = []
		if OS.has_method("get_video_adapter_driver_info"):
			adapter_info = OS.get_video_adapter_driver_info()
			system_info["video_adapter_driver_info"] = adapter_info
		
		# Add screen information
		system_info["screen_size"] = DisplayServer.screen_get_size()
		system_info["screen_dpi"] = DisplayServer.screen_get_dpi()
		system_info["processor_count"] = OS.get_processor_count()
		
		# Add memory information using the new API
		var memory_info = OS.get_memory_info()
		if memory_info:
			system_info["memory"] = memory_info
		
		# Create the report
		var crash_report = {
			"error": error_info,
			"system_info": system_info,
			"error_log": error_log,
			"timestamp": Time.get_unix_time_from_system()
		}
		
		# Write to file with pretty formatting
		file.store_string(JSON.stringify(crash_report, "  "))
		file.close()
		
		print("Crash report saved to: ", filename)
	else:
		push_error("Failed to create crash report file")

# Get recent errors
func get_recent_errors(max_count: int = 10) -> Array:
	var count = min(max_count, error_log.size())
	return error_log.slice(error_log.size() - count, error_log.size())

# Clear the error log
func clear_log() -> void:
	error_log.clear()

# Static helper methods for easier access
static func log(level: ErrorLevel, source: String, message: String, details: Dictionary = {}) -> void:
	if instance:
		instance.log_error(level, source, message, details)
	else:
		push_error("ErrorHandler instance not available")

static func info(source: String, message: String, details: Dictionary = {}) -> void:
	print(ErrorLevel.INFO, source, message, details)

static func warning(source: String, message: String, details: Dictionary = {}) -> void:
	print(ErrorLevel.WARNING, source, message, details)

static func error(source: String, message: String, details: Dictionary = {}) -> void:
	print(ErrorLevel.ERROR, source, message, details)

static func critical(source: String, message: String, details: Dictionary = {}) -> void:
	print(ErrorLevel.CRITICAL, source, message, details)

# Add a method to save the error log to a file for debugging purposes
func save_error_log(filename: String = "user://error_log.json") -> bool:
	var file = FileAccess.open(filename, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(error_log, "  "))
		file.close()
		return true
	
	return false

# Add a crash handler that can be connected to the application's crash signal
func crash_handler() -> void:
	# Generate a crash report with the last known error
	if error_log.size() > 0:
		_create_crash_report(error_log.back())
	else:
		# Create a generic crash report if no errors were logged
		log_error(ErrorLevel.CRITICAL, "System", "Application crashed without logged errors")
		_create_crash_report(error_log.back())
