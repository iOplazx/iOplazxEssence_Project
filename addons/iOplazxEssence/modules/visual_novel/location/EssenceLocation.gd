# ==============================================================================
# SCRIPT: EssenceLocation.gd
# DESCRIPTION: Base class for all game stages/scenarios. Manages core data
# like background, music, and zone identification.
# ==============================================================================
class_name EssenceLocation
extends Node2D

const ES_NAME_CLASS_BASE = "EssenceLocation"

func _ready() -> void:
	EssenceLogger.system_info("[%s] Location initialized" % [ES_NAME_CLASS_BASE])
