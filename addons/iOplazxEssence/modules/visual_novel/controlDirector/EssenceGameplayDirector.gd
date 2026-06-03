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
#     └── FadeOverlay (ColorRect)            <-- curtain
# ==

enum GameState { DIALOGUE, EXPLORATION, CUTSCENE }
var current_state: GameState = GameState.CUTSCENE

@export_category("Template References")
@export var environment_filter: CanvasModulate
@export var active_location_container: Node2D
@export var characters_stage: Node2D
@export var item_stage: Node2D
@export var dialog_box_ui: Control 
@export var fade_overlay: ColorRect 

# Variable interna para rastrear la habitación instanciada actualmente
var current_location_node: EssenceLocation

func _ready() -> void:
	#print("[EssenceGameplayDirector] Director initialized. Waiting for commands.")
	pass

# ==========================================
# environment_filter
# ==========================================

## Tints the screen smoothly using the CanvasModulate node.
## [param target_color]: The final color (e.g., Color.BLACK to darken, Color.WHITE to illuminate).
## [param duration]: How long the transition takes in seconds.
## Returns the Tween object so the caller can 'await' its completion.
func fade_filter_color(target_color: Color, duration: float) -> Tween:
	if not environment_filter: return null
	
	# Creamos un tween que manipule la propiedad 'color' del CanvasModulate
	var tween = create_tween()
	tween.tween_property(environment_filter, "color", target_color, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	return tween

## Applies a color tint to the entire screen using the EnvironmentFilter.
func set_environment_color(hex_color: String) -> void:
	if environment_filter:
		environment_filter.color = Color(hex_color)
		
# ==========================================
# fade_overlay
# ==========================================
		
## Oculta el juego (cierra la cortina negra) de forma suave o instantánea
func close_curtain(duration: float = 0.4) -> Tween:
	if not fade_overlay: return null
	
	fade_overlay.visible = true
	var tween = create_tween()
	# Animamos la opacidad (alpha) hacia 1.0 (totalmente negro)
	tween.tween_property(fade_overlay, "modulate:a", 1.0, duration)
	return tween

## Revela el juego (abre la cortina negra) de forma suave
func open_curtain(duration: float = 0.5) -> Tween:
	if not fade_overlay: return null
	
	var tween = create_tween()
	# Animamos la opacidad hacia 0.0 (totalmente transparente)
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
	
	# Cuando termine el fundido, apagamos el visible para que no bloquee los clics del mouse
	tween.finished.connect(func(): fade_overlay.visible = false)
	return tween

## Fuerza a que la pantalla esté negra de inmediato (útil para el inicio técnico)
func force_curtain_closed() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0

# ==========================================
# STATE MANAGEMENT
# ==========================================

## Changes the current game state and automatically updates environment interactivity.
func change_game_state(new_state: GameState) -> void:
	current_state = new_state
	#print("[EssenceGameplayDirector] Game state changed to: ", GameState.keys()[new_state])
	
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
	
	if new_location is Node2D:
		new_location.transform = Transform2D.IDENTITY
	# ----------------------------------------
	
	# 3. Añadimos la nueva habitación al ancla
	active_location_container.add_child(new_location)
	
	# 4. Guardamos la referencia para poder interactuar con ella después
	if new_location is EssenceLocation:
		current_location_node = new_location
		#print("[EssenceGameplayDirector] Location loaded successfully: ", new_location.name)
		
		# Aseguramos que inicie con la interactividad correcta según el estado actual
		change_game_state(current_state)

## Removes the current location scene from the ActiveLocation container.
func unload_location() -> void:
	if not active_location_container: 
		return
	
	# 1. Borramos cualquier escenario que esté montado en el ancla
	for child in active_location_container.get_children():
		child.queue_free()
		
	# 2. Rompemos la referencia para que el sistema sepa que no hay escenario activo
	current_location_node = null
	
	#print("[EssenceGameplayDirector] Location unloaded successfully.")


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
		
	#print("[EssenceGameplayDirector] CharactersStage cleared successfully.")
	
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
	#print("[EssenceGameplayDirector] ItemStage cleared.")
