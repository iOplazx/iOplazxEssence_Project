# ==============================================================================
# SCRIPT: EssenceLocation.gd
# DESCRIPTION: Base class for all game stages/scenarios. Manages core data
# like background, music, and zone identification.
# ==============================================================================
class_name EssenceLocation
extends Node2D

const ES_NAME_CLASS = "EssenceLocation"

@export_category("Stage Data")
@export var location_id: String = "generic_zone"
@export var location_name: String = "Unknown Zone"

@export_category("Visuals and Audio References")
@export var stage_background: TextureRect
# @export var background_music: AudioStream # Uncomment if using per-stage music

func _ready() -> void:
	if not stage_background:
		EssenceReportUtils.warning(
			"Location Setup Warning",
			"No TextureRect background assigned for location '%s'." % location_id
		)
		
	EssenceLogger.system_info("[%s] Location loaded: %s (%s)" % [ES_NAME_CLASS, location_name, location_id])

## Changes the current background texture.
## Ideal for simple time transitions (e.g., Day -> Night) when no filters are used.
func change_background(new_texture: Texture2D) -> void:
	if stage_background and new_texture:
		stage_background.texture = new_texture
		print("[%s] Background texture updated." % location_id)
