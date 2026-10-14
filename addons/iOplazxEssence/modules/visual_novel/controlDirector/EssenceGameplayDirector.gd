class_name EssenceGameplayDirector
extends Node2D
# ==
# SCENE STRUCTURE: TemplateGameplayDirector (Master Controller)
# ==
# GameplayDirector (Node2D) [Script: EssenceGameplayDirector]
# ├── SceneryManager (TemplateSceneryManager) [TemplateSceneryManager.tscn]
# │   ├── EnvironmentFilter (CanvasModulate)
# │   └── StageContainer (Node2D)
# ├── CharactersStage (Node2D)               <-- Where actors/characters are placed
# │   └── (Empty by default)
# ├── ItemStage  (Node2D)                    <-- 
# │   └── (Empty by default)
# └── HUD_Layer (CanvasLayer)                <-- UI always stays on top
#     ├── TranslationManager (Node)          <-- Addon Autoload/Manager
#     └── DialogBoxUI (Control)              <-- Reference to your text box
#     └── FadeOverlay (ColorRect)            <-- curtain
# ==

enum GameState { DIALOGUE, EXPLORATION, CUTSCENE }
var current_state: GameState = GameState.CUTSCENE

@export_category("Template References")
@export var scenery_manager: EssenceSceneryManager
@export var characters_stage: Node2D
@export var item_stage: Node2D
@export var fade_overlay: ColorRect 
@export var hud_layer: CanvasLayer

@export_category("UI Customization (Optional)")
## If the user drags their own interface (inheriting from EssenceBaseDialogBox), that will be used.
## If left empty (<null>), the Director will automatically load the Addon's default interface.
@export var custom_dialog_box: EssenceBaseDialogBox
## Optional reference to the mode sign. If null, it will search the HUD_Layer or load the default.
@export var custom_mode_indicator: EssenceBaseModeIndicator

# Active internal reference to the dialog box
var active_dialog_box: EssenceBaseDialogBox
# Internal variable to track the currently instantiated room
var current_location_node: EssenceLocation

var active_mode_indicator: EssenceBaseModeIndicator = null

func _ready() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0

	_setup_dialog_system()
	_setup_mode_indicator_system()
	# Start with indicator hidden while curtain is closed on boot
	if is_instance_valid(active_mode_indicator):
		active_mode_indicator.hide_indicator(false)


# ==========================================
# DIALOG SYSTEM INITIALIZATION
# ==========================================

func _setup_dialog_system() -> void:
	# 1. OPTION A: The user assigned an explicit interface in the Inspect.or
	if is_instance_valid(custom_dialog_box):
		active_dialog_box = custom_dialog_box
	
	# 2. OPTION B: Check if a node inheriting from EssenceBaseDialogBox already exists within HUD_Layer.
	elif is_instance_valid(hud_layer):
		for child in hud_layer.get_children():
			if child is EssenceBaseDialogBox:
				active_dialog_box = child
				break
				
	# 3. OPTION C (AUTOMATIC FALLBACK): We load the Addon's default packaged interface.
	if not is_instance_valid(active_dialog_box):
		var default_dialog_path: String = EssencePaths.ESSENCE_DIALOG_BOX_INTERFACE
		if ResourceLoader.exists(default_dialog_path):
			var default_scene = load(default_dialog_path) as PackedScene
			if default_scene:
				active_dialog_box = default_scene.instantiate() as EssenceBaseDialogBox
				if is_instance_valid(hud_layer):
					hud_layer.add_child(active_dialog_box)
				else:
					add_child(active_dialog_box)

	# 4. Termination signal connection
	if is_instance_valid(active_dialog_box):
		if not active_dialog_box.dialogue_finished.is_connected(_on_dialogue_sequence_finished):
			active_dialog_box.dialogue_finished.connect(_on_dialogue_sequence_finished)


# ==============================================================================
# ENVIRONMENT FILTER CONTROL (DELEGATED TO SCENERY MANAGER)
# ==============================================================================

## Smoothly fades the CanvasModulate color in SceneryManager over a given duration
func fade_filter_color(target_color: Color, duration: float) -> Tween:
	if not is_instance_valid(scenery_manager) or not scenery_manager.environment_filter: 
		return null
	
	var tween = create_tween()
	tween.tween_property(scenery_manager.environment_filter, "color", target_color, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	return tween


## Instantly sets the CanvasModulate color in SceneryManager via hex string
func set_environment_color(hex_color: String) -> void:
	if is_instance_valid(scenery_manager) and scenery_manager.environment_filter:
		scenery_manager.environment_filter.color = Color(hex_color)
		

# ==========================================
# FADE OVERLAY
# ==========================================

## Smoothly closes the screen curtain and hides active HUD indicators.
func close_curtain(duration: float = 0.4) -> Tween:
	# Hide mode indicator badge as screen fades out
	if is_instance_valid(active_mode_indicator):
		active_mode_indicator.hide_indicator(true)

	if not fade_overlay: return null
	
	fade_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, duration)
	return tween


## Smoothly opens the screen curtain and reveals active HUD indicators.
func open_curtain(duration: float = 0.5) -> Tween:
	# Reveal mode indicator badge as screen opens
	if is_instance_valid(active_mode_indicator):
		active_mode_indicator.show_indicator(true)

	if not fade_overlay: return null
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
	tween.finished.connect(func(): fade_overlay.visible = false)
	return tween


## Instantly forces the curtain closed and suppresses indicator elements.
func force_curtain_closed() -> void:
	# Instantly hide mode indicator badge without transition
	if is_instance_valid(active_mode_indicator):
		active_mode_indicator.hide_indicator(false)

	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0


# ==========================================
# STATE MANAGEMENT
# ==========================================

func change_game_state(new_state: GameState) -> void:
	current_state = new_state
	
	# 1. PHYSICAL INTERACTION CONTROL IN THE ROOM
	if current_state == GameState.EXPLORATION:
		if current_location_node and current_location_node is EssenceInteractiveLocation:
			current_location_node.environment_interactable = true
			
	elif current_state == GameState.DIALOGUE or current_state == GameState.CUTSCENE:
		if current_location_node and current_location_node is EssenceInteractiveLocation:
			current_location_node.environment_interactable = false

	# 2. VISUAL NOTIFICATION ON THE MODE SIGN
	if is_instance_valid(active_mode_indicator):
		active_mode_indicator.set_mode(new_state)

# ==============================================================================
# SCENERY & ENVIRONMENT DELEGATION
# ==============================================================================

## Instantiates a visual room prefab through SceneryManager and syncs interaction state
func load_scenery(packed_stage: PackedScene, stage_id: int = -1, mode: int = 1) -> EssenceLocation:
	if not is_instance_valid(scenery_manager):
		EssenceReportUtils.critical(
			"Scenery Manager Error", 
			"'scenery_manager' reference is missing in %s." % name
		)
		return null

	var stage_node = scenery_manager.load_stage_prefab(packed_stage, stage_id, mode)
	change_game_state(current_state)
	return stage_node


## Instantiates an interactive hotspots prefab through SceneryManager
func load_interactive(packed_interactive: PackedScene) -> EssenceInteractiveLocation:
	if not is_instance_valid(scenery_manager):
		EssenceReportUtils.critical(
			"Scenery Manager Error", 
			"'scenery_manager' reference is missing in %s." % name
		)
		return null

	var interactive_node = scenery_manager.load_interactive_prefab(packed_interactive)
	change_game_state(current_state)
	return interactive_node


## Unloads active scenery (both visual stage and interactive layer)
func unload_scenery() -> void:
	if is_instance_valid(scenery_manager):
		scenery_manager.clear_current_stage()


## Helper to retrieve active visual location instance from SceneryManager
func get_current_location() -> EssenceLocation:
	if is_instance_valid(scenery_manager):
		return scenery_manager.current_stage_node
	return null


## Helper to retrieve active interactive location instance from SceneryManager
func get_current_interactive() -> EssenceInteractiveLocation:
	if is_instance_valid(scenery_manager):
		return scenery_manager.current_interactive_node
	return null


# ==============================================================================
# LEGACY COMPATIBILITY ALIASES (DEPRECATED)
# ==============================================================================

## @deprecated Use load_scenery() instead.
func load_location(location_scene: PackedScene) -> void:
	push_warning(
		"'load_location()' is deprecated and will be removed in future releases. Please use 'load_scenery()' instead in %s." % name
	)
	load_scenery(location_scene)


## @deprecated Use unload_scenery() instead.
func unload_location() -> void:
	push_warning(
		"'unload_location()' is deprecated and will be removed in future releases. Please use 'unload_scenery()' instead in %s." % name
	)
	unload_scenery()


# ==========================================
# NARRATIVE & DIALOGUE ENTRY POINTS
# ==========================================

## PUBLIC API: Starts a direct dialogue sequence by passing an array of lines.s.
func play_dialogue(lines: Array) -> void:
	if not is_instance_valid(active_dialog_box):
		EssenceReportUtils.critical(
			"Dialogue Error", 
			"No dialogue interface is configured or instantiated in %s." % name
		)
		return
		
	change_game_state(GameState.DIALOGUE)
	active_dialog_box.start_dialogue(lines)


## Receiver automático que reestablece el control al terminar la conversación.
func _on_dialogue_sequence_finished() -> void:
	change_game_state(GameState.EXPLORATION)
	#print("[%s] Dialogue completed. State restored to EXPLORATION." % name)


## Método legado de compatibilidad para guiones traducidos.
func initialize_dialog_sequence(sequence_id: String) -> void:
	#print("\n=============================================")
	#print("[EssenceGameplayDirector] STARTING SEQUENCE: ", sequence_id)
	#print("=============================================")
	
	change_game_state(GameState.CUTSCENE)
	# TODO: In the future, the TranslationManager will resolve the ID and call play_dialogue()


# ==========================================
# STAGE MANAGEMENT (ACTORS & ITEMS)
# ==========================================

func add_actor_to_stage(actor_scene: PackedScene) -> Node2D:
	if not characters_stage or not actor_scene: return null
	var new_actor = actor_scene.instantiate()
	characters_stage.add_child(new_actor)
	return new_actor


func clear_character_stage() -> void:
	if not characters_stage: return
	for child in characters_stage.get_children():
		child.queue_free()


func add_item_to_stage(item_scene: PackedScene) -> Node2D:
	if not item_stage or not item_scene: return null
	var new_item = item_scene.instantiate()
	item_stage.add_child(new_item)
	return new_item


func remove_item_from_stage(item_node: Node) -> void:
	if is_instance_valid(item_node):
		item_node.queue_free()


func clear_item_stage() -> void:
	if not item_stage: return
	for child in item_stage.get_children():
		child.queue_free()
		
# Modal and warning
## Dynamically transparent invocation for modals and notices
func show_modal_prompt(title: String, body: String, preset: EssenceBaseModalPrompt.ButtonPreset = EssenceBaseModalPrompt.ButtonPreset.OK) -> String:
	if not is_instance_valid(hud_layer):
		EssenceReportUtils.critical(
			"Modal Setup Error", 
			"'hud_layer' is not assigned in %s." % name
		)
		return ""
		
	# 1. We obtain the centralized path from EssencePaths.
	var scene_path: String = EssencePaths.ESSENCE_MODULAR_PROMPT_INTERFACE
	
	if not ResourceLoader.exists(scene_path):
		EssenceReportUtils.critical(
			"Modal Resource Error", 
			"The modal scene was not found at path: %s in %s." % [scene_path, name]
		)
		return ""
		
	# 2. Dynamic loading and instantiation
	var modal_resource = load(scene_path) as PackedScene
	var modal_instance = modal_resource.instantiate() as EssenceBaseModalPrompt
	
	# 3. We add it to the HUD_Layer.
	hud_layer.add_child(modal_instance)
	
	# 4. We block the scenario and wait for the user's response.
	change_game_state(GameState.CUTSCENE)
	var user_choice: String = await modal_instance.show_prompt(title, body, preset)
	
	# 5. Automatic cleanup and restoration of the scan state
	modal_instance.queue_free()
	change_game_state(GameState.EXPLORATION)
	
	return user_choice

# ==========================================
# MINIGAME STAGE SYSTEM
# ==========================================

## Launches a modal minigame scene, disables background interactions, and returns execution result via await.
func launch_minigame(minigame_scene_path: String, init_data: Dictionary = {}) -> Dictionary:
	if not is_instance_valid(hud_layer):
		EssenceReportUtils.critical(
			"Minigame Launch Error", 
			"'hud_layer' is not assigned in %s." % name
		)
		return {"victory": false, "cancelled": true}
		
	# 1. Get the container stage scene path from EssencePaths
	var stage_path: String = EssencePaths.ESSENCE_MINIGAME_STAGE_INTERFACE
	
	if not ResourceLoader.exists(stage_path):
		EssenceReportUtils.critical(
			"Minigame Resource Error", 
			"MiniGameStage scene not found at path: %s in %s." % [stage_path, name]
		)
		return {"victory": false, "cancelled": true}
		
	if not ResourceLoader.exists(minigame_scene_path):
		EssenceReportUtils.critical(
			"Minigame Resource Error", 
			"Target minigame scene not found at path: %s in %s." % [minigame_scene_path, name]
		)
		return {"victory": false, "cancelled": true}

	# 2. Instantiate the MiniGameStage host inside HUD_Layer
	var stage_resource = load(stage_path) as PackedScene
	var stage_instance = stage_resource.instantiate() as EssenceMiniGameStage
	hud_layer.add_child(stage_instance)

	# 3. Block background interaction while minigame is active
	change_game_state(GameState.CUTSCENE)

	# 4. Load the minigame scene and wait asynchronously for its completion
	var minigame_resource = load(minigame_scene_path) as PackedScene
	var result: Dictionary = await stage_instance.launch_minigame_scene(minigame_resource, init_data)

	# 5. Clean up host instance and restore exploration state
	stage_instance.queue_free()
	change_game_state(GameState.EXPLORATION)

	return result

######################
#
##################
func _setup_mode_indicator_system() -> void:
	# 1. OPTION A: Asignado explícitamente en el Inspector
	if is_instance_valid(custom_mode_indicator):
		active_mode_indicator = custom_mode_indicator
		
	# 2. OPTION B: Buscar dentro del HUD_Layer existente
	elif is_instance_valid(hud_layer):
		for child in hud_layer.get_children():
			if child is EssenceBaseModeIndicator:
				active_mode_indicator = child
				break
				
	# 3. OPTION C: Fallback automático al prefab base del Addon
	if not is_instance_valid(active_mode_indicator):
		var default_path: String = EssencePaths.ESSENCE_MODE_INDICATOR_INTERFACE
		if ResourceLoader.exists(default_path):
			var scene = load(default_path) as PackedScene
			if scene:
				var instance: Node = scene.instantiate()
				if instance is EssenceBaseModeIndicator:
					active_mode_indicator = instance as EssenceBaseModeIndicator
					if is_instance_valid(hud_layer):
						hud_layer.add_child(active_mode_indicator)
					else:
						add_child(active_mode_indicator)
				else:
					EssenceReportUtils.critical(
						"UI Setup Error",
						"The instantiated scene '%s' does not inherit from EssenceBaseModeIndicator." % default_path
					)
					instance.queue_free()
