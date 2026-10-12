class_name EssenceSceneryManager
extends Node2D

const ES_NAME_CLASS = "EssenceSceneryManager"

# [TemplateSceneryManager.tscn]
# SceneryManager (Node2D) [Script: EssenceSceneryManager.gd] 
# ├── EnvironmentFilter (CanvasModulate)  <-- Light/color filter (Day/Night)
# ├── StageContainer (Node2D)             <-- Anchor point for visual scenery .tscn files
# └── InteractiveContainer (Node2D)       <-- Anchor point for hotspots/doors .tscn files

signal stage_loaded(stage_node: EssenceLocation)
signal interactive_loaded(interactive_node: EssenceInteractiveLocation)
signal stage_cleared()

@export_group("Container References")
## Container node where visual room prefabs (.tscn) will be instantiated
@export var stage_container: Node2D
## Container node where interactive hotspots prefabs (.tscn) will be instantiated
@export var interactive_container: Node2D

## Active visual room/stage instance currently loaded in memory
var current_stage_node: EssenceLocation = null
## Active interactive hotspots instance currently loaded in memory
var current_interactive_node: EssenceInteractiveLocation = null

var current_stage_id: int = -1
var current_stage_mode: int = 1


func _ready() -> void:
	# Fallback automático si los exports no fueron asignados manualmente en el Inspector
	if not is_instance_valid(stage_container):
		stage_container = $StageContainer if has_node("StageContainer") else self
	if not is_instance_valid(interactive_container):
		interactive_container = $InteractiveContainer if has_node("InteractiveContainer") else self


# ==============================================================================
# VISUAL SCENERY LOADING
# ==============================================================================

## Dynamically instantiates a visual room prefab scene into the stage container.
func load_stage_prefab(packed_stage: PackedScene, stage_id: int = -1, mode: int = 1) -> EssenceLocation:
	clear_visual_stage()

	if not packed_stage:
		EssenceReportUtils.critical("Scenery Load Error", "Attempted to load a null PackedScene.")
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

	if current_stage_node.has_method("set_environment_mode"):
		current_stage_node.call("set_environment_mode", mode)

	stage_loaded.emit(current_stage_node)
	EssenceLogger.system_info("[%s] Visual stage loaded: %s (ID: %d, Mode: %d)" % [
		ES_NAME_CLASS,
		current_stage_node.name,
		stage_id,
		mode
	])

	return current_stage_node


# ==============================================================================
# INTERACTIVE HOTSPOTS LOADING
# ==============================================================================

## Dynamically instantiates an interactive hotspots prefab scene into the interactive container.
func load_interactive_prefab(packed_interactive: PackedScene) -> EssenceInteractiveLocation:
	clear_interactive_stage()

	if not packed_interactive:
		return null

	var instance: Node = packed_interactive.instantiate()
	if not (instance is EssenceInteractiveLocation or instance is EssenceLocation):
		EssenceReportUtils.critical(
			"Interactive Setup Error",
			"Instantiated scene '%s' does not inherit from EssenceLocation/EssenceInteractiveLocation." % instance.name
		)
		instance.queue_free()
		return null

	current_interactive_node = instance as EssenceInteractiveLocation
	interactive_container.add_child(current_interactive_node)

	# ALINEACIÓN Y RESTAURACIÓN DE TRANSFORMACIÓN
	# Asegura que la escena interactiva coincida exactamente con las coordenadas del origen
	current_interactive_node.position = Vector2.ZERO
	current_interactive_node.rotation = 0.0
	current_interactive_node.scale = Vector2.ONE

	interactive_loaded.emit(current_interactive_node)
	EssenceLogger.system_info("[%s] Interactive layer loaded: %s" % [ES_NAME_CLASS, instance.name])

	return current_interactive_node

# ==============================================================================
# CLEANUP METHODS
# ==============================================================================

## Clears all children inside the visual stage container.
func clear_visual_stage() -> void:
	if is_instance_valid(stage_container):
		for child in stage_container.get_children():
			child.queue_free()
	current_stage_node = null


## Clears all children inside the interactive hotspots container.
func clear_interactive_stage() -> void:
	if is_instance_valid(interactive_container):
		for child in interactive_container.get_children():
			child.queue_free()
	current_interactive_node = null


## Safely clears both visual and interactive stages from memory.
func clear_current_stage() -> void:
	clear_visual_stage()
	clear_interactive_stage()
	current_stage_id = -1
	stage_cleared.emit()
