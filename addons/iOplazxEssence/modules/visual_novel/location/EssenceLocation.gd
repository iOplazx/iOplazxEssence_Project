# ==============================================================================
# SCRIPT: EssenceLocation.gd
# DESCRIPTION: Base class for all game stages/scenarios. Manages core data
# like background, music, and zone identification.
# ==============================================================================
class_name EssenceLocation
extends Node2D

const ES_NAME_CLASS = "EssenceLocation"

@export_category("Stage Metadata")
@export var location_id: String = "generic_zone"
@export var location_name: String = "Unknown Zone"

@export_category("Visual References (Optional)")
## Optional background texture reference. Leave null for item-only or overlay scenes.
@export var stage_background: TextureRect

func _ready() -> void:
	EssenceLogger.system_info("[%s] Location initialized: %s (%s)" % [ES_NAME_CLASS, location_name, location_id])
	
## Changes the current background texture.
func change_background(new_texture: Texture2D) -> void:
	if stage_background and new_texture:
		stage_background.texture = new_texture
