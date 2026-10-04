# ==============================================================================
# SCRIPT: EssenceInteractiveLocation.gd
# DESCRIPTION: Inherits from EssenceLocation. Adds containers for interactive
# objects (Hotspots) and manages when they can be clicked.
# ==============================================================================
class_name EssenceInteractiveLocation
extends EssenceLocation

@export_category("Interactive Containers")
@export var fixed_hotspots: Node2D    
@export var dynamic_hotspots: Node2D  

var environment_interactable: bool = false:
	set(value):
		environment_interactable = value
		_toggle_hotspots_interaction(value)

func _ready() -> void:
	super._ready()
	environment_interactable = false
	_connect_fixed_hotspots()

func _connect_fixed_hotspots() -> void:
	if not fixed_hotspots: return
	for object in fixed_hotspots.get_children():
		if object is Area2D and object.has_signal("input_event"):
			object.input_event.connect(func(_vp, event, _idx, obj=object):
				_on_hotspot_clicked(event, obj)
			)

func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	if not environment_interactable: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("[%s] Player interacted with Hotspot: %s" % [location_id, node.name])
		get_viewport().set_input_as_handled()

func _toggle_hotspots_interaction(enabled: bool) -> void:
	if not fixed_hotspots: return
	for object in fixed_hotspots.get_children():
		if object is CollisionObject2D:
			object.input_pickable = enabled
