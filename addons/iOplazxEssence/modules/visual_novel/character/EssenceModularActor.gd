## [EssenceModularActor]
## Handles modular visual parts like clothing, accessories, or visual variations.
## Automatically registers nodes added to the 'Wardrobe Nodes' array.
class_name EssenceModularActor
extends EssenceActor

## Drag and drop clothing or expression nodes directly from the Inspector.
@export var wardrobe_nodes: Array[Node2D] = []

## Internal lookup table to resolve garment visibility changes in O(1) time.
var _wardrobe_map: Dictionary = {}

func _ready() -> void:
	# 1. Call parent (EssenceActor) initialization if needed
	super._ready()
	
	# 2. Automatically bake the array into a high-performance hash map
	_build_wardrobe_map()

## Converts the inspector array into a fast-lookup dictionary using node names as keys.
func _build_wardrobe_map() -> void:
	for node in wardrobe_nodes:
		if is_instance_valid(node):
			_wardrobe_map[node.name] = node

## Toggles the visibility of a specific garment or accessory instantly.
## [param garment_id]: The exact name of the node in the wardrobe map.
## [param is_enabled]: True to show, False to hide.
func toggle_garment(garment_id: String, is_enabled: bool) -> void:
	if _wardrobe_map.has(garment_id):
		_wardrobe_map[garment_id].visible = is_enabled
	else:
		push_warning("[%s] Wardrobe Warning: Garment '%s' not found in registry." % [name, garment_id])
		
