## [EssenceWardrobeGroup]
## Abstract base class. Does not expose anything to the Inspector on its own.
## Contains the mathematical and physical synchronization logic.
extends Node2D
class_name EssenceWardrobeGroup

## Generic dictionary in RAM to be used by internal methods.
var registry: Dictionary = {}


func hide_all_registered() -> void:
	for node in registry.values():
		if is_instance_valid(node): 
			node.visible = false


func sync_equipped_items(equipped_list: Array) -> void:
	for item_id in registry.keys():
		var node = registry[item_id]
		if is_instance_valid(node):
			var should_be_visible: bool = int(item_id) in equipped_list
			node.visible = should_be_visible
		
