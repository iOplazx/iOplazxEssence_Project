# ==============================================================================
# SCRIPT: EssenceInteractiveLocation.gd
# DESCRIPTION: Inherits from EssenceLocation. Adds containers for interactive
# objects (Hotspots) and manages when they can be clicked.
# ==============================================================================
class_name EssenceInteractiveLocation
extends EssenceLocation

@export_category("Interactive Containers")
## Folder (Node2D) where the user will place doors and fixed objects (Area2D)
@export var fixed_hotspots: Node2D    
## Folder (Node2D) reserved for instantiating dynamic/random objects
@export var dynamic_hotspots: Node2D  

## Setter variable to automatically toggle interaction states across hotspots.
var environment_interactable: bool = false:
	set(value):
		environment_interactable = value
		_toggle_hotspots_interaction(value)

func _ready() -> void:
	# Call parent _ready to register background
	super._ready() 
	
	# Lock environment by default on load (awaiting Director instructions)
	environment_interactable = false
	_connect_fixed_hotspots()

## Finds doors/objects and connects their click signals to the script
func _connect_fixed_hotspots() -> void:
	if not fixed_hotspots: return
	
	for object in fixed_hotspots.get_children():
		if object is Area2D and object.has_signal("input_event"):
			# Connect via Lambda function to pass the exact clicked node
			object.input_event.connect(func(_vp, event, _idx, obj=object):
				_on_hotspot_clicked(event, obj)
			)

## Captures clicks on any object and notifies the system.
func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	if not environment_interactable: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("[%s] Player interacted with Hotspot: %s" % [location_id, node.name])
		get_viewport().set_input_as_handled()

## Enables or disables door/hotspot collisions (Exploration vs Dialogue mode)
func _toggle_hotspots_interaction(enabled: bool) -> void:
	if not fixed_hotspots: return
	
	for object in fixed_hotspots.get_children():
		if object is CollisionObject2D:
			object.input_pickable = enabled
