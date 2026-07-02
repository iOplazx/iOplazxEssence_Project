class_name TestMainGame
extends Control 

# ==
# TestMainGame.tscn
# ==
# TestMainGame (TestMainGame) [Script: TestMainGame]
# ├── BackgroundLayer (TextureRect)                     
# ├── GameplayDirector (EssenceGameplayDirector)   
# │   ├── EnviromentFilter (CanvasModulate)           
# │   ├── ActiveLocation (Node2D)    
# │   ├── CharacterStage (Node2D) 
# │   ├── ItemStage (Node2D)      
# │   └── HUD_Layer (CanvasLayer) (no visible)
# │       ├── TranslationManager (Node)           
# │       └── DialogBoxUI (Node)           
# ├── Area2D_door (Area2D)     
# │       ├── imgPuerta (Sprite2D)           
# │       └── CollisionShape2D (CollisionShape2D)  
# ├── CharacterRoot (GenericInteractiveCharacter)                    
# ├── TutorialPanelUI (EssenceTutorialPanel)    
# └── PanelControles (Panel)   
#     └── ...   
# ==

const ES_NAME_CLASS = "TestMainGame"

# ==========================================
# GESTIÓN DEL FLUJO
# ==========================================
enum TestPhase { INTRO, GAMEPLAY }
var current_phase: TestPhase = TestPhase.INTRO

# ==========================================
# CONEXIONES DE UI Y MUNDO
# ==========================================
@export_category("UI Connections")
@export var background_layer: TextureRect
@export var btn_return: Button
@export var btn_save: Button
@export var btn_load: Button
@export var tutorial_panel: EssenceTutorialPanel 
@export var ui_principal: Control 

# Usamos % en lugar de $ para acceder al instante sin importar la jerarquía
@onready var director: EssenceGameplayDirector = %GameplayDirector
@onready var active_location_container: Node2D = %GameplayDirector/ActiveLocation
@onready var item_stage_container: Node2D = %GameplayDirector/ItemStage

const ROUTES_PATH = "res://_static/RouteConfig.tres"
var routes: EssenceRouteConfig

# Variable global para saber en qué ID de habitación numérica estamos parados
var current_room_id: int = GameIDs.RoomID.INITIAL_ROOM
# Diccionario de ejemplo para simular las condiciones de tu historia (Flags)
var story_flags: Dictionary = {
	"is_phone_event_active": false,   # La condición de tu ejemplo del teléfono
	"is_first_time_here": true
}

#####################################################
# SECTION declaration of characters and items tscn  #
#####################################################
var active_character: GenericInteractiveCharacter = null
const CHARACTER_ROOT_SCENE = EssencePaths.ITEM_GENERIC_INTERACTIVE_CHARACTER

const DOOR_ITEM_SCENE = DemoItemsRoute.ITEMDOOR_SCENE
var spawned_doors_in_room: Array[Node2D] = []

## Array to massively clean all floating elements when changing rooms
var spawned_items_in_room: Array[Node2D] = []

######################################
# SECTION (ALL SCENES IN THIS TSCN)  #
######################################

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	director.clear_character_stage()
	director.clear_item_stage()
	
	# Conectamos la señal de cuando el tutorial se cierra
	if tutorial_panel:
		tutorial_panel.tutorial_finished.connect(_on_tutorial_finished)
	
	_cargar_configuracion()
	_check_security_nodes()
	_config_buttons()
	
	# 2. Revisamos si venimos de Cargar una Partida o de presionar "Back" en el menú
	if is_instance_valid(SaveManager) and not SaveManager.loaded_game_data.is_empty():
		# Entramos directo al sistema de restauración
		_restaurar_partida_cargada()
	else:
		# Si es un juego 100% nuevo
		#_setup_initial_room_layout()
		director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
		
		# Si es juego nuevo, abrimos la cortina suavemente
		var fade = director.open_curtain(0.4)
		if fade: await fade.finished
		
		_iniciar_secuencia_intro()
		
	EssenceLogger.system_info("[%s/_ready] Escena principal inicializada." % ES_NAME_CLASS)
	
## Carga el archivo .tres en memoria
func _cargar_configuracion() -> void:
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig
	else:
		push_error("[%s] ERROR: No se encontró RouteConfig.tres en %s" % ["TestMainGame", ROUTES_PATH])
		
# ==========================================
# LÓGICA DE FLUJO (TUTORIALES Y EVENTOS)
# ==========================================

func _iniciar_secuencia_intro() -> void:
	current_phase = TestPhase.INTRO
	
	# Pequeña pausa antes de que salte el tutorial para que no sea tan brusco
	await get_tree().create_timer(0.5).timeout
	
	var intro_messages: Array[String] = [
		"Welcome to the Essence Framework sandbox.",
		"Please note: This is strictly a controls test and technical demo, not the actual game.",
		"Here we will test the rendering, saving systems, and interactive actors.",
		"Click 'Understood' to begin the test."
	]
	
	if tutorial_panel:
		tutorial_panel.load_and_show_tutorial(intro_messages)
		
func _setup_initial_room_layout():
	director.clear_item_stage()

## Callback triggered when the intro tutorial panel is closed.
func _on_tutorial_finished() -> void:
	if current_phase == TestPhase.INTRO:
		print("[%s] Tutorial Intro terminado. Esperando cierre de UI..." % ES_NAME_CLASS)
		current_phase = TestPhase.GAMEPLAY
		
		story_flags["is_first_time_here"] = false
		
		# DYNAMIC PROGRESSION LAYER
		# We register that this specific room has successfully advanced to Modo 1
		story_flags["room_mode_" + str(current_room_id)] = 1
		
		await get_tree().create_timer(0.6).timeout 
		
		_instanciar_actor_principal()
		
		var data = LevelManager.get_scenery_config(current_room_id, current_room_id, 1, true)
		
		if not data["flag_error"]:
			# Aplicamos las reglas del Modo 1 (Habilitar clicks globales en el escenario)
			_apply_interaction_state(data["interaction_mode"])
			
			_build_stage_interactables(current_room_id, data["interaction_mode"])
			
		# 4. Le devolvemos el control físico del mouse y movimiento al jugador
		if director:
			director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
			
	# GAMEPLAY / SECOND TUTORIAL FLOW
	elif current_phase == TestPhase.GAMEPLAY:
		print("[%s] Second tutorial completed successfully by the player." % ES_NAME_CLASS)
		# Save persistent flag so this tutorial never triggers again
		story_flags["has_completed_touch_tutorial"] = true
			
## Instantiates the main character and default room elements dynamically
## [param is_instant]: If true, skips spawn animations (perfect for loading saves)
func _instanciar_actor_principal(is_instant: bool = false) -> void:
	# Invocamos al personaje usando la habitación en la que realmente estamos parado
	_spawn_main_character(current_room_id, 0, is_instant)
	
	# Aplicamos los cambios de vestuario iniciales de Annie de forma segura
	if is_instance_valid(active_character) and active_character.has_method("toggle_garment"):
		active_character.toggle_garment("GenericChrHat", false)
		active_character.toggle_garment("GenericChrSunglass", false)
	
# ==========================================
# BLINDAJE DE SEGURIDAD
# ==========================================
func _check_security_nodes() -> void:
	var missing = []
	if not btn_return: missing.append("btn_return")
	if not btn_save: missing.append("btn_save")
	if not btn_load: missing.append("btn_load")
	if not tutorial_panel: missing.append("tutorial_panel")
	
	if missing.size() > 0:
		var msg = "Faltan nodos exportados en %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		push_error(msg)

# ==========================================
# CONFIGURACIÓN
# ==========================================
func _config_buttons() -> void:
	if btn_return: btn_return.pressed.connect(func(): _play_sfx(); _on_return_pressed())
	if btn_save: btn_save.pressed.connect(func(): _play_sfx(); _on_btn_save_pressed())
	if btn_load: btn_load.pressed.connect(func(): _play_sfx(); _on_btn_load_pressed())


func _play_sfx() -> void:
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()

# ==========================================
# LÓGICA DE GUARDADO / CARGA
# ==========================================
func _preparar_datos_para_menu() -> void:
	print("[%s] Capturando pantalla y preparando datos..." % ES_NAME_CLASS)
	
	await get_tree().process_frame
	await SaveManager.take_temp_screenshot()
	await get_tree().create_timer(0.1).timeout
	
	# ==========================================
	# DICCIONARIO PARA LA INTERFAZ / CACHÉ
	# ==========================================
	var current_game_data = {
		"escena_actual": "MainRoom",
		"fase_actual": current_phase, 
		"habitacion_actual": current_room_id,
		"story_flags": story_flags, 
		"ropa_estado_personaje": active_character.get_clothing_state() if is_instance_valid(active_character) else {}
	}
	
	var room_key = GameIDs.RoomID.find_key(current_room_id)
	var room_name = room_key.capitalize().replace("_", " ") if room_key else "Habitación Desconocida"
	
	var current_meta_data = {
		"title": "Prueba de Framework",
		"description": "Lugar: %s | Fase: %s" % [room_name, ("Intro" if current_phase == TestPhase.INTRO else "Gameplay")],
		"play_time": "00:01:00"
	}
	
	SaveManager.cache_current_state(current_game_data, current_meta_data)

func _restaurar_partida_cargada() -> void:
	print("[%s] Restaurando datos cargados." % ES_NAME_CLASS)
	var datos = SaveManager.loaded_game_data
	
	current_phase = int(datos.get("fase_actual", 0)) as TestPhase
	var room_saved_id = int(datos.get("habitacion_actual", GameIDs.RoomID.INITIAL_ROOM))
	
	if datos.has("story_flags"):
		story_flags = datos.get("story_flags").duplicate()
	
	# El motor se estabiliza. El jugador solo ve negro porque forzamos Color.BLACK en el _ready o en el Director
	await get_tree().process_frame 
	
	if current_phase == TestPhase.GAMEPLAY:
		if tutorial_panel: tutorial_panel.visible = false 
		director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
		current_room_id = room_saved_id
		
		var room_data = LevelManager.get_scenery_config(room_saved_id, room_saved_id, 1, true)
		
		if not room_data["flag_error"]:
			match room_saved_id:
				GameIDs.RoomID.INITIAL_ROOM:
					await _on_ready_initialRoom(room_data, true)
				GameIDs.RoomID.ROOM_3_DOORS:
					await _on_ready_room3doors(room_data, true)
				# CONECTAMOS EL CASO PARA TU NUEVA HABITACIÓN:
				GameIDs.RoomID.ROOM_1_DOOR:
					print("[%s] Restaurador redirigiendo a la habitación de 1 puerta." % ES_NAME_CLASS)
					await _on_ready_room1door(room_data, true) # Pasamos true en skip_animations
		
		if is_instance_valid(active_character):
			var ropa_guardada = datos.get("ropa_estado_personaje", {})
			active_character.load_clothing_state(ropa_guardada)
			
	else:
		_setup_initial_room_layout() #validar TODO
		_iniciar_secuencia_intro()
		
	# Limpiamos la caché inmediatamente para dejar el cargador listo para la siguiente vez
	SaveManager.loaded_game_data.clear()
	
	# Abrimos la cortina de forma automática e impecable
	var fade_in = director.open_curtain(0.5)
	if fade_in: 
		await fade_in.finished
		
	print("[%s] ¡Carga completada y filtro de pantalla iluminado!" % ES_NAME_CLASS)
	
# ==========================================
# EVENTOS DE BOTONES
# ==========================================
func _on_btn_save_pressed() -> void:
	if ui_principal: ui_principal.visible = false
	await _preparar_datos_para_menu()
	if is_instance_valid(SceneManager):
		SceneManager.goto_save_game(SceneManager.TransitionType.INSTANT)

func _on_btn_load_pressed() -> void:
	await _preparar_datos_para_menu()
	if is_instance_valid(SceneManager):
		SceneManager.goto_load_game(SceneManager.TransitionType.INSTANT)

func _on_return_pressed() -> void:
	if is_instance_valid(SceneManager):
		SceneManager.goto_main_menu()

## Triggered when the user performs a physical left-click interaction over the active character.
func _on_character_interacted() -> void:
	if not is_instance_valid(active_character): 
		return
	
	# 1. VALIDATION LAYER
	if current_phase == TestPhase.GAMEPLAY and active_character.is_interactable:
		# If the tutorial was already fully completed, do not trigger it again
		if story_flags.get("has_completed_touch_tutorial", false):
			print("[%s] Character clicked, but second tutorial is already completed." % ES_NAME_CLASS)
			return
			
		print("[%s] Player interacted with character: %s" % [ES_NAME_CLASS, active_character.display_name])
		
		# 2. STATE CHECK (First click transition to Mode 2)
		if not story_flags.get("has_touched_character", false):
			story_flags["has_touched_character"] = true
			story_flags["room_mode_" + str(current_room_id)] = 2
			
			print("[%s] First-time interaction approved. Advancing Room to Modo 2..." % ES_NAME_CLASS)
			
			var data = LevelManager.get_scenery_config(current_room_id, current_room_id, 2, true)
			if not data["flag_error"]:
				_apply_interaction_state(data["interaction_mode"])
				director.clear_item_stage()
				_build_stage_interactables(current_room_id, data["interaction_mode"])
		
		# 3. INTERACTION FEEDBACK
		_trigger_character_tutorial()

## Launches the specific wardrobe and saving system tutorial overlay.
func _trigger_character_tutorial() -> void:
	if tutorial_panel:
		var interaction_messages: Array[String] = [
			"Character Interaction Detected!",
			"Try removing some of my clothes using the Inspector, or via code.",
			"Then, save the game and load it to verify the Wardrobe System."
		]
		tutorial_panel.load_and_show_tutorial(interaction_messages)
			
## Instancia, posiciona y conecta al personaje. 
## [param is_instant]: Si es true, aparece de golpe (ideal para cargar partidas).
func _spawn_main_character(room_id: int, mode: int, is_instant: bool = false) -> void:
	if is_instance_valid(active_character): return # Ya está en escena
	
	var actor_scene = load(CHARACTER_ROOT_SCENE) as PackedScene
	active_character = director.add_actor_to_stage(actor_scene)
	
	var placement = StageActorManager.get_actor_placement(room_id, GameIDs.ActorID.PROTAGONIST, mode)
	
	active_character.position = placement["position"]
	active_character.scale = placement["scale"]
	
	active_character.clicked_on_character.connect(_on_character_interacted)
	# ==========================================================
	
	# Manejo visual (Fade In vs Aparición instantánea)
	var container = active_character.get_node_or_null("SubViewportContainer")
	if is_instant:
		active_character.is_interactable = true
		if container: container.modulate.a = 1.0
	else:
		active_character.is_interactable = false
		if container:
			container.modulate.a = 0.0
			var fade = EssenceUIAnimator.fade_in_subviewport(container, 1.0)
			if fade: 
				await fade.finished
		active_character.is_interactable = true
		
## Central listener that processes all navigation signals coming from inside the active rooms.
## [param next_place]: The RoomID destination.
## [param mode]: The required interaction layout mode.
## [param is_only_mode]: True if we are just switching internal rules instead of reloading.
func _on_room_navigation_requested(next_place: int, mode: int, is_only_mode: bool) -> void:
	var data = LevelManager.get_scenery_config(current_room_id, next_place, mode, is_only_mode)
	
	if data["flag_error"]:
		push_error("[TestMainGame] Illegal transition requested by room layout.")
		return
		
	if is_only_mode:
		_apply_interaction_state(data["interaction_mode"])
		return
		
	if director:
		# Le pedimos al director que cierre su cortina negra de inmediato (en 0.25s)
		var curtain_tween = director.close_curtain(0.25)
		if curtain_tween:
			# Escondemos el juego detrás del muro negro antes de mover un solo pixel
			await curtain_tween.finished 
			
	# Ahora que la pantalla está TOTALMENTE negra y segura,
	# ejecutamos la carga pesada. Nadie notará si el fondo se borra o parpadea gris.
	match data["id_room"]:
		GameIDs.RoomID.INITIAL_ROOM:
			# Pasamos 'true' en skip_animations porque el director ya cerró la cortina,
			# no necesitamos que la habitación intente hacer otro fundido interno.
			_on_ready_initialRoom(data, true)
		GameIDs.RoomID.ROOM_3_DOORS:
			_on_ready_room3doors(data, true)
		GameIDs.RoomID.ROOM_1_DOOR:
			_on_ready_room1door(data, true)
		GameIDs.RoomID.PARK:
			_on_ready_parkScene(data, true)
			
		GameIDs.RoomID.SAVE_SCENE:
			print("[%s] Interceptando viaje técnico. Saltando a la pantalla de guardado..." % ES_NAME_CLASS)
			
			# 1. Ejecutamos la limpieza física del escenario para no dejar "fugas" de memoria
			spawned_doors_in_room.clear()
			if director: 
				director.unload_location()
			
			# 2. Esperamos a que el motor asiente la destrucción de nodos
			await get_tree().process_frame
			
			# 3. Viajamos físicamente usando tu constante centralizada 
			get_tree().change_scene_to_file(DemoItemsRoute.TESTSAVESCENE_SCENE)
			
			return # CRÍTICO: Hacemos un return aquí para que la función muera 
				   # y no intente ejecutar el open_curtain de abajo, ya que cambiamos de escena.

	if director:
		# Esperamos un frame de estabilización para que el motor termine de renderizar el mapa
		await get_tree().process_frame
		
		# Abrimos la cortina suavemente para revelar el nuevo escenario
		var open_tween = director.open_curtain(0.4)
		if open_tween:
			await open_tween.finished

## Evaluates story conditions before enabling player control inside a room.
## [param room_id]: The active Room ID from GameIDs.RoomID.
## [param default_mode]: The fallback interaction mode if no story events trigger.
func _evaluate_room_narrative_entry(room_id: int, default_mode: int) -> void:
	
	# 1. INTERMEDIATE STORY FILTER
	# If an event or cutscene takes control, we interrupt the normal flow.
	if _check_room_interruptions(room_id):
		return 
		
	# 2. DYNAMIC MODE RESOLUTION (DATA-DRIVEN)
	# Construct a generic key based on the current room ID (e.g., "room_mode_1")
	var room_mode_key: String = "room_mode_" + str(room_id)
	
	# Fetch the saved mode for this room if it exists; otherwise, fall back to default_mode.
	var final_mode: int = story_flags.get(room_mode_key, default_mode)
	
	# 3. NORMAL EXPLORATION FLOW
	# Fetch the internal room configuration directly from the LevelManager using the resolved mode.
	var data = LevelManager.get_scenery_config(room_id, room_id, final_mode, true)
	if data["flag_error"]: 
		return
		
	_apply_interaction_state(data["interaction_mode"])
	
	# 4. AUTOMATED STAGE CONSTRUCTION
	# The system reads the StageItemManager manifesto, processes filters, 
	# and instantiates all floating buttons/interactables automatically.
	_build_stage_interactables(room_id, data["interaction_mode"])
	
	# 5. EXCLUSIVE CHARACTER / ACTOR INITIALIZATION
	# Hardcoded overrides are now strictly reserved for persistent narrative actors.
	if room_id == GameIDs.RoomID.INITIAL_ROOM:
		_instanciar_actor_principal(false)
		
		# 6. PENDING TUTORIAL RESTORATION
		# If the room is loaded in Mode 2 but the tutorial wasn't finished, re-show it automatically.
		if data["interaction_mode"] == 2 and not story_flags.get("has_completed_touch_tutorial", false):
			print("[%s] Unfinished second tutorial detected. Re-triggering overlay..." % ES_NAME_CLASS)
			_trigger_character_tutorial()

## Checks for pending story events in the given room.
## Returns TRUE if an event intercepted the flow, FALSE if the room is clear.
func _check_room_interruptions(room_id: int) -> bool:
	# Si ya estamos en Gameplay, NINGÚN evento inicial o tutorial viejo debe colarse.
	if current_phase == TestPhase.GAMEPLAY:
		return false # ✅ No hay interrupción, continúa libremente
		
	match room_id:
		GameIDs.RoomID.INITIAL_ROOM:
			if story_flags.get("is_first_time_here", false):
				print("[Story] Interrupción: Primera vez en la habitación inicial. Esperando tutorial.")
				director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
				return true 
				
		GameIDs.RoomID.ROOM_3_DOORS:
			if story_flags.get("is_phone_event_active", false):
				print("[Story] Interrupción: ¡Alguien llama al telefono! Bloqueando exploracion.")
				director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
				story_flags["is_phone_event_active"] = false 
				return true 
				
	return false

## Helper method to translate matrix modes into director game states.
func _apply_interaction_state(matrix_mode: int) -> void:
	match matrix_mode:
		0:
			director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
		1, 2:
			director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
			
## CENTRAL AUTOMATION: Builds and validates all interactive elements declared in the room
## [param room_id]: The ID of the current scene (GameIDs.RoomID)
## [param current_layout_mode]: The current sub-mode or variant of the room (0, 1, 2, etc.)
func _build_stage_interactables(room_id: int, current_layout_mode: int) -> void:
	# 1. CONSULTA: Obtenemos el arreglo de ítems que este escenario "desea" tener por diseño
	var raw_items_list: Array = StageItemManager.ROOM_ITEM_MANIFESTO.get(room_id, [])
	
	if raw_items_list.is_empty():
		return # Habitación pasiva o puramente estática, nada que spawnear por código.
		
	# 2. PROCESAMIENTO Y FILTRADO POR CADA ELEMENTO
	for item_data in raw_items_list:
		var item_id: int = item_data["item_id"]
		var destination: int = item_data["destination"]
		
		var placement: Dictionary = StageItemManager.get_item_placement(item_data, current_layout_mode)
		
		# Si las reglas de la historia no se cumplen, o el objeto no es visible, pasamos de largo
		# SIN gastar memoria cargando ni instanciando recursos `.tscn`.
		if not placement.get("is_visible", false):
			continue
		
		if not _should_allow_item_spawn(room_id, item_id, current_layout_mode):
			print("[%s/Spawner] Objeto ID %d RECHAZADO por condiciones adicionales del entorno (Modo: %d)." % [ES_NAME_CLASS, item_id, current_layout_mode])
			continue
			
		# 3. IDENTIFICACIÓN DE RUTA DE ASSET (.TSCN)
		var scene_path: String = ""
		match item_id:
			GameIDs.ItemID.DOOR_SPRITE:      scene_path = DemoItemsRoute.ITEMDOOR_SCENE
			GameIDs.ItemID.HOUSE_SPRITE:     scene_path = DemoItemsRoute.ITEMHOUSE_SCENE 
			GameIDs.ItemID.TOUCH_INDICATOR:  scene_path = DemoItemsRoute.ITEMTOUCH_SCENE
			
		if scene_path == "" or not ResourceLoader.exists(scene_path):
			push_error("[%s] Error crítico: No se encontró escena .tscn para el ItemID %d" % [ES_NAME_CLASS, item_id])
			continue
			
		# 4. INSTANCIACIÓN Detrás de escena
		var packed_item = load(scene_path) as PackedScene
		var item_instance = director.add_item_to_stage(packed_item)
		
		if not is_instance_valid(item_instance):
			push_error("[%s] El Director devolvió un nodo nulo para el ItemID %d" % [ES_NAME_CLASS, item_id])
			continue
			
		# 5. TRANSFORMACIÓN FÍSICA
		# Forzamos los valores físicos espaciales calculados automáticamente por presets o manuales
		item_instance.position = placement["position"]
		item_instance.scale = placement["scale"]
		
		# Guardamos la referencia para el recolector de basura al cambiar de habitación
		spawned_items_in_room.append(item_instance)
		
		# 6. CONFIGURAR LA ACCIÓN (Smart Input Binding)
		var target_area: Area2D = item_instance if item_instance is Area2D else null
		if not target_area:
			for child in item_instance.get_children():
				if child is Area2D:
					target_area = child
					break
					
		# 7. CONEXIÓN Y REVELACIÓN FINAL
		if target_area:
			if destination != -1:
				# ACCIÓN DE VIAJE: Si el ítem amarra un destino, lo conectamos al flujo de la cortina negra
				target_area.input_event.connect(_on_dynamic_door_clicked.bind(destination))
			else:
				# ACCIÓN DE UTILIDAD: Si no tiene destino (como el Touch Indicator), pasa limpiamente
				pass
		else:
			push_warning("[%s] El item %d no posee un Area2D. Se instanció como elemento puramente visual." % [ES_NAME_CLASS, item_id])
			
## INTERNAL VALIDATOR: Decides whether an item is eligible to enter based on the current rules
func _should_allow_item_spawn(_room_id: int, _item_id: int, current_mode: int) -> bool:
	# Rule filter example: If it's night mode (Mode 3), we could block non-bed items here
	if current_mode == 0:
		# NOTA: Si necesitas usarlas dentro de un 'if' más adelante, 
		# solo les quitas el guion bajo y listo. Por ahora, si solo usas current_mode,
		# el filtro funciona igual de bien.
		pass
		
	# Ejemplo de la regla que sugeriste: Si es de noche (supongamos Modo 3), bloqueamos todo excepto la cama
	if current_mode == 3: # Filtro de Noche ficticio para pruebas
		# Si estamos en la habitación inicial de noche y el ítem no es el que queremos, lo bloqueamos
		# if item_id != GameIDs.ItemID.BED_ITEM: return false
		pass
		
	# Por defecto, si no hay ninguna regla de la historia o fase que lo prohíba, el objeto entra libre
	return true
		
## Processes the click of any dynamic door and requests navigation to its bound destination.
func _on_dynamic_door_clicked(_viewport: Node, event: InputEvent, _shape_idx: int, next_room_id: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#print("[Framework] ¡Puerta cruzada! Viajando hacia la habitación ID: ", next_room_id)
		
		# Consultamos la matriz del LevelManager con el destino que venía amarrado en la puerta
		var data = LevelManager.get_scenery_config(current_room_id, next_room_id, 0, false)
		
		if not data["flag_error"]:
			# Al cambiar de cuarto, vaciamos nuestra lista de referencias e indicamos al Director que limpie la pantalla
			spawned_doors_in_room.clear()
			director.clear_item_stage() 
			
			# Redirigimos el resultado al callback central que ya construiste
			_on_room_navigation_requested(next_room_id, 0, false)
			
## BASE GENERIC METHOD (The Framework's Build Engine)
## Executes the common steps and returns the location node in case the room
## needs to have extra scripts, interactables, or logic attached to it in the middle of the flow.
func _build_room_base(data: Dictionary, background_path: String, interactive_scene_path: String, skip_animations: bool) -> Node2D:
	current_room_id = data["id_room"]
	
	# 1. Animación de salida (Si aplica)
	if not skip_animations:
		var fade_out_tween: Tween = EssenceUIAnimator.fade_out(background_layer, 0.4)
		if fade_out_tween: await fade_out_tween.finished
	
	# 2. LIMPIEZA TOTAL CENTRALIZADA
	director.clear_character_stage()
	active_character = null
	director.clear_item_stage()
	spawned_doors_in_room.clear()
	director.unload_location() # Aseguramos que descargue el anterior siempre
	
	# 3. Asignación del Fondo
	if background_path != "":
		background_layer.texture = load(background_path)
		
	# 4. Carga de la Escena Interactiva (Hotspots, colisiones, puertas)
	var current_loc: Node2D = null
	if interactive_scene_path != "":
		var interactive_scene = load(interactive_scene_path) as PackedScene
		if interactive_scene:
			director.load_location(interactive_scene)
			current_loc = director.current_location_node
			if current_loc and current_loc.has_signal("navigation_requested"):
				current_loc.navigation_requested.connect(_on_room_navigation_requested)
				
	# 5. Animación de entrada (Si aplica)
	if not skip_animations:
		var fade_in_tween: Tween = EssenceUIAnimator.fade_in(background_layer, 0.5)
		if fade_in_tween: await fade_in_tween.finished
	else:
		background_layer.modulate.a = 1.0
		
	return current_loc

#########################
# SECTION Initial Room  #
#########################
			
## Sets up the initial room layout. If skip_animations is true, it builds instantly.
func _on_ready_initialRoom(data: Dictionary, skip_animations: bool = false) -> void:
	# Llamamos a la base (pasamos "" en la escena interactiva porque no lleva)
	await _build_room_base(data, EssencePaths.BACKGROUND_ROOM_INITIAL, "", skip_animations)
	
	# Fin de transición
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])

#########################
# SECTION Room 3 Doors  #
#########################

## Sets up the 3 doors room. If skip_animations is true, it builds instantly.
func _on_ready_room3doors(data: Dictionary, skip_animations: bool = false) -> void:
	await _build_room_base(data, EssencePaths.BACKGROUND_ROOM_3DOORS, DemoItemsRoute.TESTROOMDOOR_SCENE, skip_animations)
	if tutorial_panel:
		tutorial_panel.visible = false
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])

#########################
# SECTION Room 1 Door   #
#########################

## Sets up the 3 doors room. If skip_animations is true, it builds instantly.
func _on_ready_room1door(data: Dictionary, skip_animations: bool = false) -> void:
	await _build_room_base(data, EssencePaths.BACKGROUND_ROOM_1DOOR, DemoItemsRoute.ONEDOORROOM_SCENE, skip_animations)
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])
	
##################
# SECTION PARK   #
##################
func _on_ready_parkScene(data: Dictionary, skip_animations: bool = false) -> void:
	await _build_room_base(data, EssencePaths.BACKGROUND_PARK, "", skip_animations)
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])

##############
# Ejemplo
#############
func _on_ready_habitacion_secreta(data: Dictionary, skip_animations: bool = false) -> void:
	# 🟢 Código ESPECÍFICO ANTES de cargar:
	print("¡Alerta! El jugador entró a una zona peligrosa. Modificando música...")
	#AudioManager.play_music("Musica_Tension")
	
	# 🛠️ Ejecutamos la carga base común y atrapamos el nodo que genera
	var locacion_actual = await _build_room_base(data, "res://FondoSecreto.tscn", "res://ColisionesSecretas.tscn", skip_animations)
	
	# 🔵 Código ESPECÍFICO DESPUÉS de cargar (Modificar cosas dentro del cuarto):
	if is_instance_valid(locacion_actual):
		# Buscamos un cofre que solo existe en esta habitación y lo alteramos por código
		var cofre = locacion_actual.get_node_or_null("CofreOculto")
		if cofre:
			print("x")
		#if cofre and GlobalSave.ya_abrio_cofre:
		#	cofre.queue_free() # Borramos el cofre si ya lo usó
			
	# Pasamos el control narrativo normal
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])
