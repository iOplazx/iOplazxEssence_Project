class_name EssenceGameplayDirector
extends Node2D
# ==
# SCENE STRUCTURE: TemplateGameplayDirector (Master Controller)
# ==
# GameplayDirector (Node2D) [Script: EssenceGameplayDirector]
# ├── EnvironmentFilter (CanvasModulate)     <-- Colors the whole screen (Day/Night)
# ├── ActiveLocation (Node2D)                <-- The anchor where interactive hotspots are loaded
# │   └── (Empty by default)
# ├── CharactersStage (Node2D)               <-- Where actors/characters are placed
# │   └── (Empty by default)
# ├── ItemStage  (Node2D)                    <-- 
# │   └── (Empty by default)
# └── HUD_Layer (CanvasLayer)                <-- UI always stays on top
#     ├── TranslationManager (Node)          <-- Addon Autoload/Manager
#     └── DialogBoxUI (Control)              <-- Reference to your text box
# ==

enum GameState { DIALOGUE, EXPLORATION, CUTSCENE }
var current_state: GameState = GameState.CUTSCENE

@export_category("Template References")
@export var environment_filter: CanvasModulate
@export var active_location_container: Node2D
@export var characters_stage: Node2D
@export var item_stage: Node2D
@export var dialog_box_ui: Control 

# Variable interna para rastrear la habitación instanciada actualmente
var current_location_node: EssenceLocation

func _ready() -> void:
	#print("[EssenceGameplayDirector] Director initialized. Waiting for commands.")
	pass

# ==========================================
# STATE MANAGEMENT
# ==========================================

## Changes the current game state and automatically updates environment interactivity.
func change_game_state(new_state: GameState) -> void:
	current_state = new_state
	print("[EssenceGameplayDirector] Game state changed to: ", GameState.keys()[new_state])
	
	# Si pasamos a Exploración, encendemos el escenario interactivo
	if current_state == GameState.EXPLORATION:
		if current_location_node and current_location_node is EssenceInteractiveLocation:
			current_location_node.environment_interactable = true
			#print(" -> Environment interaction ENABLED.")
			
	# Si pasamos a Diálogo/Cinemática, bloqueamos el escenario
	elif current_state == GameState.DIALOGUE or current_state == GameState.CUTSCENE:
		if current_location_node and current_location_node is EssenceInteractiveLocation:
			current_location_node.environment_interactable = false
			#print(" -> Environment interaction DISABLED.")

# ==========================================
# SCENE & ENVIRONMENT CONTROL
# ==========================================
## Loads and instantiates a new location scene into the ActiveLocation container.
func load_location(location_scene: PackedScene) -> void:
	if not active_location_container or not location_scene: 
		push_error("[EssenceGameplayDirector] Missing container or scene to load.")
		return
	
	# 1. Limpiamos la habitación anterior si existía
	for child in active_location_container.get_children():
		child.queue_free()
	
	# 2. Instanciamos la nueva habitación
	var new_location = location_scene.instantiate()
	
	# --- ¡AQUÍ ESTÁ LA MAGIA DEL RESETEO! ---
	# Forzamos posición (0,0), rotación (0) y escala (1,1)
	if new_location is Node2D:
		new_location.transform = Transform2D.IDENTITY
	# ----------------------------------------
	
	# 3. Añadimos la nueva habitación al ancla
	active_location_container.add_child(new_location)
	
	# 4. Guardamos la referencia para poder interactuar con ella después
	if new_location is EssenceLocation:
		current_location_node = new_location
		print("[EssenceGameplayDirector] Location loaded successfully: ", new_location.name)
		
		# Aseguramos que inicie con la interactividad correcta según el estado actual
		change_game_state(current_state)

## Applies a color tint to the entire screen using the EnvironmentFilter.
func set_environment_color(hex_color: String) -> void:
	if environment_filter:
		environment_filter.color = Color(hex_color)

# ==========================================
# NARRATIVE ENTRY POINT
# ==========================================

## Starts a narrative sequence using the provided translation ID.
func initialize_dialog_sequence(sequence_id: String) -> void:
	print("\n=============================================")
	print("[EssenceGameplayDirector] STARTING SEQUENCE: ", sequence_id)
	print("=============================================")
	
	# 1. Bloqueamos el juego mientras carga y preparamos la pantalla
	change_game_state(GameState.CUTSCENE)
	
	# 2. Aquí llamaremos al TranslationManager/Gestor de Guión en el futuro
	print(" -> Fetching script for ID: %s..." % sequence_id)
	
	# 3. Pasamos a modo diálogo para que el jugador lea
	change_game_state(GameState.DIALOGUE)
	
	# 4. Mostramos la UI
	if dialog_box_ui:
		dialog_box_ui.visible = true
		# TODO: dialog_box_ui.display_text(...)

## Instantiates and adds an actor to the CharactersStage container.
## Returns the instantiated Node for further manipulation.
func add_actor_to_stage(actor_scene: PackedScene) -> Node2D:
	if not characters_stage or not actor_scene: return null
	
	var new_actor = actor_scene.instantiate()
	characters_stage.add_child(new_actor)
	return new_actor
	
## Clears and removes all instantiated characters inside the CharactersStage container.
func clear_character_stage() -> void:
	if not characters_stage: return
	
	for child in characters_stage.get_children():
		child.queue_free()
		
	print("[EssenceGameplayDirector] CharactersStage cleared successfully.")
	
## Instantiates and adds an interactive item/icon to the screen.
func add_item_to_stage(item_scene: PackedScene) -> Node2D:
	if not item_stage or not item_scene: return null
	
	var new_item = item_scene.instantiate()
	item_stage.add_child(new_item)
	return new_item


## Removes a specific item from the screen by its node reference.
func remove_item_from_stage(item_node: Node) -> void:
	if is_instance_valid(item_node):
		item_node.queue_free()


## Clears all floating items from the screen.
func clear_item_stage() -> void:
	if not item_stage: return
	for child in item_stage.get_children():
		child.queue_free()
	print("[EssenceGameplayDirector] ItemStage cleared.")
