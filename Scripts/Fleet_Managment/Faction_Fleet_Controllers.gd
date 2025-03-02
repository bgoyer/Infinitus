# This file contains the specialized fleet controller classes for different factions
# Each controller handles unique faction behavior for fleets

# Base class for faction-specific fleet controllers
class_name FactionFleetController
extends Node

# Reference to the controlled fleet
var fleet: Fleet

func _init(target_fleet: Fleet) -> void:
	fleet = target_fleet

func _ready() -> void:
	# Connect to necessary fleet signals
	if fleet:
		fleet.connect("ship_added", Callable(self, "_on_ship_added"))
		fleet.connect("ship_removed", Callable(self, "_on_ship_removed"))

func _process(delta: float) -> void:
	# Base behavior - update tactical situation and issue commands
	if fleet and is_instance_valid(fleet):
		update_tactical_assessment(delta)

func update_tactical_assessment(delta: float) -> void:
	# Base implementation - update tactical assessment periodically
	# This is overridden by specific faction controllers
	pass

func _on_ship_added(ship: Ship) -> void:
	# Handler for when a ship is added to the fleet
	pass

func _on_ship_removed(ship: Ship) -> void:
	# Handler for when a ship is removed from the fleet
	pass

func cleanup() -> void:
	# Cleanup connections when controller is destroyed
	if fleet:
		if fleet.is_connected("ship_added", Callable(self, "_on_ship_added")):
			fleet.disconnect("ship_added", Callable(self, "_on_ship_added"))
		
		if fleet.is_connected("ship_removed", Callable(self, "_on_ship_removed")):
			fleet.disconnect("ship_removed", Callable(self, "_on_ship_removed"))
