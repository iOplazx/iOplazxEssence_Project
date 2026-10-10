# ==============================================================================
# SCRIPT: EssenceTemplateScenery.gd
# DESCRIPTION: Standard template for layered room scenarios.
# Duplicate this script and scene when creating new game rooms.
# ==============================================================================
class_name EssenceTemplateScenery
extends EssenceLayeredLocation

const ES_NAME_CLASS = "EssenceTemplateScenery"

@export_category("Room Specific References")
## Optional specific node references for this room (e.g. window glare, specific props)
@export var room_details: CanvasItem


func set_environment_mode(mode: int) -> void:
	super.set_environment_mode(mode)
	
	match mode:
		1: # Day Mode
			if is_instance_valid(room_details):
				room_details.visible = true
		2: # Night Mode
			if is_instance_valid(room_details):
				room_details.visible = false
