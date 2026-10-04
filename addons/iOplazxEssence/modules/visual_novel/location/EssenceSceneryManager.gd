class_name EssenceSceneryManager
extends Node2D

const ES_NAME_CLASS = "EssenceSceneryManager"

signal stage_loaded(stage_node: EssenceLocation)
signal stage_cleared()

@export_group("Stage Container References")
## Container node (Node2D) where room prefabs (.tscn) will be instantiated dynamically
@export var stage_container: Node2D

## Optional global environment filter (CanvasModulate) for time-of-day tints
@export var environment_filter: CanvasModulate

## Active stage instance in memory
var current_stage_node: EssenceLocation = null
var current_stage_id: int = -1
var current_stage_mode: int = 1


func _ready() -> void:
	if not stage_container:
		# Default fallback to self if no specific container node is assigned
		stage_container = self


## Instantiates a stage prefab dynamically into the scene tree.
func load_stage_prefab(packed_stage: PackedScene, stage_id: int = -1, mode: int = 1) -> EssenceLocation:
	clear_current_stage()

	if not packed_stage:
		EssenceReportUtils.critical("Scenery Load Error","Attempted to load a null PackedScene.")
		return null

	var instance: Node = packed_stage.instantiate()
	if not instance is EssenceLocation:
		EssenceReportUtils.critical(
			"Scenery Setup Error", 
			"Instantiated scene '%s' does not inherit from EssenceLocation." % instance.name
		)
		instance.queue_free()
		return null

	current_stage_node = instance as EssenceLocation
	current_stage_id = stage_id
	current_stage_mode = mode

	stage_container.add_child(current_stage_node)

	# Apply room mode variant if the location supports environmental modes
	if current_stage_node.has_method("set_environment_mode"):
		current_stage_node.call("set_environment_mode", mode)

	stage_loaded.emit(current_stage_node)
	EssenceLogger.system_info("[%s] Stage loaded successfully: %s (ID: %d, Mode: %d)" % [
		ES_NAME_CLASS,
		current_stage_node.name,
		stage_id,
		mode
	])

	return current_stage_node


## Safely clears the active stage instance from memory.
func clear_current_stage() -> void:
	if is_instance_valid(current_stage_node):
		current_stage_node.queue_free()
		current_stage_node = null
		current_stage_id = -1
		stage_cleared.emit()


## Applies global environmental color tint via CanvasModulate (e.g. Day/Night/Sunset).
func set_global_atmosphere(color_tint: Color) -> void:
	if environment_filter:
		environment_filter.color = color_tint
