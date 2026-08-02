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
@export var fade_overlay: ColorRect 
@export var hud_layer: CanvasLayer

@export_category("UI Customization (Optional)")
## Si el usuario arrastra su propia interfaz (que herede de EssenceBaseDialogBox), se usará esa.
## Si se deja vacío (<null>), el Director cargará automáticamente la interfaz por defecto del Addon.
@export var custom_dialog_box: EssenceBaseDialogBox

# Referencia interna activa al cuadro de diálogo
var active_dialog_box: EssenceBaseDialogBox
# Variable interna para rastrear la habitación instanciada actualmente
var current_location_node: EssenceLocation

func _ready() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0

	_setup_dialog_system()


# ==========================================
# DIALOG SYSTEM INITIALIZATION
# ==========================================

func _setup_dialog_system() -> void:
	# 1. OPCIÓN A: El usuario asignó una interfaz explícita en el Inspector
	if is_instance_valid(custom_dialog_box):
		active_dialog_box = custom_dialog_box
	
	# 2. OPCIÓN B: Buscamos si ya existe algún nodo que herede de EssenceBaseDialogBox dentro de HUD_Layer
	elif is_instance_valid(hud_layer):
		for child in hud_layer.get_children():
			if child is EssenceBaseDialogBox:
				active_dialog_box = child
				break
				
	# 3. OPCIÓN C (FALLBACK AUTOMÁTICO): Cargamos la interfaz empaquetada por defecto del Addon
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

	# 4. Conexión de señales de término
	if is_instance_valid(active_dialog_box):
		if not active_dialog_box.dialogue_finished.is_connected(_on_dialogue_sequence_finished):
			active_dialog_box.dialogue_finished.connect(_on_dialogue_sequence_finished)


# ==========================================
# ENVIRONMENT FILTER
# ==========================================

func fade_filter_color(target_color: Color, duration: float) -> Tween:
	if not environment_filter: return null
	
	var tween = create_tween()
	tween.tween_property(environment_filter, "color", target_color, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	return tween


func set_environment_color(hex_color: String) -> void:
	if environment_filter:
		environment_filter.color = Color(hex_color)
		

# ==========================================
# FADE OVERLAY
# ==========================================

func close_curtain(duration: float = 0.4) -> Tween:
	if not fade_overlay: return null
	
	fade_overlay.visible = true
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, duration)
	return tween


func open_curtain(duration: float = 0.5) -> Tween:
	if not fade_overlay: return null
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
	tween.finished.connect(func(): fade_overlay.visible = false)
	return tween


func force_curtain_closed() -> void:
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0


# ==========================================
# STATE MANAGEMENT
# ==========================================

func change_game_state(new_state: GameState) -> void:
	current_state = new_state
	
	if current_state == GameState.EXPLORATION:
		if current_location_node and current_location_node is EssenceInteractiveLocation:
			current_location_node.environment_interactable = true
			
	elif current_state == GameState.DIALOGUE or current_state == GameState.CUTSCENE:
		if current_location_node and current_location_node is EssenceInteractiveLocation:
			current_location_node.environment_interactable = false


# ==========================================
# SCENE & ENVIRONMENT CONTROL
# ==========================================

func load_location(location_scene: PackedScene) -> void:
	if not active_location_container or not location_scene: 
		push_error("[EssenceGameplayDirector] Missing container or scene to load.")
		return
	
	for child in active_location_container.get_children():
		child.queue_free()
	
	var new_location = location_scene.instantiate()
	if new_location is Node2D:
		new_location.transform = Transform2D.IDENTITY
	
	active_location_container.add_child(new_location)
	
	if new_location is EssenceLocation:
		current_location_node = new_location
		change_game_state(current_state)


func unload_location() -> void:
	if not active_location_container: 
		return
	
	for child in active_location_container.get_children():
		child.queue_free()
		
	current_location_node = null


# ==========================================
# NARRATIVE & DIALOGUE ENTRY POINTS
# ==========================================

## API PÚBLICA: Inicia una secuencia de diálogo directa pasando un arreglo de líneas.
func play_dialogue(lines: Array) -> void:
	if not is_instance_valid(active_dialog_box):
		push_error("[%s] Error: No hay ninguna interfaz de diálogo configurada o instanciada." % name)
		return
		
	change_game_state(GameState.DIALOGUE)
	active_dialog_box.start_dialogue(lines)


## Receiver automático que reestablece el control al terminar la conversación.
func _on_dialogue_sequence_finished() -> void:
	change_game_state(GameState.EXPLORATION)
	print("[%s] Diálogo completado. Estado restaurado a EXPLORATION." % name)


## Método legado de compatibilidad para guiones traducidos.
func initialize_dialog_sequence(sequence_id: String) -> void:
	print("\n=============================================")
	print("[EssenceGameplayDirector] STARTING SEQUENCE: ", sequence_id)
	print("=============================================")
	
	change_game_state(GameState.CUTSCENE)
	# TODO: En el futuro el TranslationManager resolverá el ID y llamará a play_dialogue()


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
## Invocación dinámicamente transparente para modales y avisos
func show_modal_prompt(title: String, body: String, preset: EssenceBaseModalPrompt.ButtonPreset = EssenceBaseModalPrompt.ButtonPreset.OK) -> String:
	if not is_instance_valid(hud_layer):
		push_error("[%s] Error: 'hud_layer' no está asignado en el GameplayDirector." % name)
		return ""
		
	# 1. Obtenemos la ruta centralizada desde EssencePaths
	var scene_path: String = EssencePaths.ESSENCE_MODULAR_PROMPT_INTERFACE
	
	if not ResourceLoader.exists(scene_path):
		push_error("[%s] Error: No se encontró la escena modal en la ruta: %s" % [name, scene_path])
		return ""
		
	# 2. Carga e instanciación dinámica
	var modal_resource = load(scene_path) as PackedScene
	var modal_instance = modal_resource.instantiate() as EssenceBaseModalPrompt
	
	# 3. Lo añadimos al HUD_Layer
	hud_layer.add_child(modal_instance)
	
	# 4. Bloqueamos el escenario y esperamos la respuesta del usuario
	change_game_state(GameState.CUTSCENE)
	var user_choice: String = await modal_instance.show_prompt(title, body, preset)
	
	# 5. Limpieza automática y restauración del estado de exploración
	modal_instance.queue_free()
	change_game_state(GameState.EXPLORATION)
	
	return user_choice
