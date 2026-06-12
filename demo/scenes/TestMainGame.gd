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
var current_room_id: int = LevelManager.RoomID["INITIAL_ROOM"]
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
	
	# Invoca la puerta Variante 0 y la amarra para que al hacer clic viaje a ROOM_3_DOORS
	_spawn_navigation_door(0, LevelManager.RoomID["ROOM_3_DOORS"])

func _on_tutorial_finished() -> void:
	if current_phase == TestPhase.INTRO:
		print("[%s] Tutorial Intro terminado. Esperando cierre de UI..." % ES_NAME_CLASS)
		current_phase = TestPhase.GAMEPLAY
		
		# CAMBIO CRUCIAL: Guardamos en la historia que ya pasamos por aquí
		story_flags["is_first_time_here"] = false
		
		await get_tree().create_timer(0.6).timeout 
		
		_instanciar_actor_principal()
			
## Instantiates the main character and default room elements dynamically
## [param is_instant]: If true, skips spawn animations (perfect for loading saves)
func _instanciar_actor_principal(is_instant: bool = false) -> void:
	# Invocamos al personaje usando la habitación en la que realmente estamos parado
	_spawn_main_character(current_room_id, 0, is_instant)
	
	# Si estamos en la habitación inicial, pintamos su puerta correspondiente
	if current_room_id == LevelManager.RoomID["INITIAL_ROOM"]:
		_spawn_navigation_door(0, LevelManager.RoomID["ROOM_3_DOORS"])
	
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
	
	var room_name = "Habitación Desconocida"
	for key in LevelManager.RoomID.keys():
		if LevelManager.RoomID[key] == current_room_id:
			room_name = key.capitalize().replace("_", " ")
			break
	
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
	var room_saved_id = int(datos.get("habitacion_actual", LevelManager.RoomID["INITIAL_ROOM"]))
	
	if datos.has("story_flags"):
		story_flags = datos.get("story_flags").duplicate()
	
	# El motor se estabiliza. El jugador solo ve negro porque forzamos Color.BLACK en el _ready
	await get_tree().process_frame 
	
	if current_phase == TestPhase.GAMEPLAY:
		if tutorial_panel: tutorial_panel.visible = false 
		director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
		current_room_id = room_saved_id
		
		var room_data = LevelManager.get_scenery_config(room_saved_id, room_saved_id, 1, true)
		
		if not room_data["flag_error"]:
			match room_saved_id:
				LevelManager.RoomID["INITIAL_ROOM"]:
					await _on_ready_initialRoom(room_data, true)
				LevelManager.RoomID["ROOM_3_DOORS"]:
					await _on_ready_room3doors(room_data, true)
		
		if is_instance_valid(active_character):
			var ropa_guardada = datos.get("ropa_estado_personaje", {})
			active_character.load_clothing_state(ropa_guardada)
			
	else:
		_setup_initial_room_layout()
		_iniciar_secuencia_intro()
		
	SaveManager.loaded_game_data.clear()
	
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

## Evento que se dispara al hacer clic sobre el personaje
func _on_character_interacted() -> void:
	if not is_instance_valid(active_character): return
	
	# Verificamos que estemos en Gameplay y que el personaje ya sea interactuable
	if current_phase == TestPhase.GAMEPLAY and active_character.is_interactable:
		print("[%s] El jugador interactuó con: %s" % [ES_NAME_CLASS, active_character.display_name])
		
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
	
	var placement = StageActorManager.get_actor_placement(room_id, StageActorManager.ActorID["PROTAGONIST"], mode)
	
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
		
	# =======================================================
	# 🚨 PROTECCIÓN ANTIDESTELLOS: CERRAMOS EL TELÓN PRIMERO
	# =======================================================
	if director:
		# Le pedimos al director que cierre su cortina negra de inmediato (en 0.25s)
		var curtain_tween = director.close_curtain(0.25)
		if curtain_tween:
			# Escondemos el juego detrás del muro negro antes de mover un solo pixel
			await curtain_tween.finished 
			
	# Ahora que la pantalla está TOTALMENTE negra y segura,
	# ejecutamos la carga pesada. Nadie notará si el fondo se borra o parpadea gris.
	match data["id_room"]:
		LevelManager.RoomID["INITIAL_ROOM"]:
			# Pasamos 'true' en skip_animations porque el director ya cerró la cortina,
			# no necesitamos que la habitación intente hacer otro fundido interno.
			_on_ready_initialRoom(data, true)
		LevelManager.RoomID["ROOM_3_DOORS"]:
			_on_ready_room3doors(data, true)
		LevelManager.RoomID["ROOM_1_DOOR"]:
			print("Cargando habitación de 1 puerta...")
			# _on_ready_room1door(data, true)

	# =======================================================
	# 🚨 REVELAMOS EL JUEGO: EL TELÓN SE ABRE CON EL NUEVO MAPA LISTO
	# =======================================================
	if director:
		# Esperamos un frame de estabilización para que el motor termine de renderizar el mapa
		await get_tree().process_frame
		
		# Abrimos la cortina suavemente para revelar el nuevo escenario
		var open_tween = director.open_curtain(0.4)
		if open_tween:
			await open_tween.finished

## Evaluates story conditions before enabling player control inside a room.
## [param room_id]: The active Room ID from LevelManager.
## [param default_mode]: The fallback interaction mode if no story events trigger.
func _evaluate_room_narrative_entry(room_id: int, default_mode: int) -> void:
	
	# 1. PASO POR EL FILTRO INTERMEDIO
	# Si el método devuelve true, el evento tomó el control, así que hacemos un 'return' para salir.
	if _check_room_interruptions(room_id):
		return 
		
	# 2. FLUJO NORMAL DE EXPLORACIÓN
	# Si llegamos aquí, es porque la habitación está libre de eventos.
	#print("[Story] Todo despejado. Promoviendo a Exploracion (Modo 1).")
	
	var data = LevelManager.get_scenery_config(room_id, room_id, 1, true)
	if data["flag_error"]: return
		
	_apply_interaction_state(data["interaction_mode"])
	
	# 3. CONSTRUCCIÓN DE LA HABITACIÓN
	# Aquí solo ponemos lo que SIEMPRE aparece cuando la habitación está normal
	match room_id:
		LevelManager.RoomID["INITIAL_ROOM"]:
			_instanciar_actor_principal(false)
			
		LevelManager.RoomID["ROOM_3_DOORS"]:
			_spawn_navigation_door(0, LevelManager.RoomID["ROOM_1_DOOR"])
			_spawn_navigation_door(1, LevelManager.RoomID["INITIAL_ROOM"])
			
			# Si tuvieras un ItemManager, aquí harías aparecer la mochila o cosas fijas:
			# _spawn_screen_item(StageItemManager.ItemID["BACKPACK_ICON"], 0)
				
## Checks for pending story events in the given room.
## Returns TRUE if an event intercepted the flow, FALSE if the room is clear.
func _check_room_interruptions(room_id: int) -> bool:
	# Si ya estamos en Gameplay, NINGÚN evento inicial o tutorial viejo debe colarse.
	if current_phase == TestPhase.GAMEPLAY:
		return false # ✅ No hay interrupción, continúa libremente
		
	match room_id:
		LevelManager.RoomID["INITIAL_ROOM"]:
			if story_flags.get("is_first_time_here", false):
				print("[Story] Interrupción: Primera vez en la habitación inicial. Esperando tutorial.")
				director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
				return true 
				
		LevelManager.RoomID["ROOM_3_DOORS"]:
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
			

## Instantiates a dynamic transition door into the ItemStage and binds its destination room.
## [param door_mode_index]: The variant index (0 for left/first door, 1 for right/second door, etc.)
## [param destination_room_id]: The LevelManager.RoomID where this door will lead.
func _spawn_navigation_door(door_mode_index: int, destination_room_id: int) -> void:
	# 1. Cargamos el archivo .tscn desde tu ruta centralizada
	var packed_door = load(DOOR_ITEM_SCENE) as PackedScene
	if not packed_door:
		push_error("[TestMainGame] Error crítico: No se pudo cargar la escena desde: " + DOOR_ITEM_SCENE)
		return
		
	# 2. Le ordenamos al Director que la instancie dentro del contenedor ItemStage
	var door_instance = director.add_item_to_stage(packed_door)
	
	# 3. PREGUNTA/VALIDACIÓN: ¿Se instanció correctamente?
	if is_instance_valid(door_instance):
		#print("[TestMainGame] ¡Éxito! Puerta variante %d instanciada correctamente." % door_mode_index)
		
		# 4. Posicionamiento dinámico: Buscamos las coordenadas en tu StageItemManager
		# Le pasamos el cuarto actual, el ID general de puertas y el índice del modo (0, 1, etc.)
		var config = StageItemManager.get_item_placement(
			current_room_id, 
			StageItemManager.ItemID["DOOR_SPRITE"], 
			door_mode_index
		)
		
		# Si por alguna regla de la historia el mánager dice que no es visible, la borramos y salimos
		if not config.get("is_visible", true):
			door_instance.queue_free()
			return
			
		door_instance.position = config["position"]
		door_instance.scale = config["scale"]
		
		# Guardamos la referencia en nuestra lista general para poder limpiarla al cambiar de cuarto
		spawned_doors_in_room.append(door_instance)
		
		# 5. PROGRAMAR EL EVENTO DE SER TOCADA (Smart Input Binding)
		var target_area: Area2D = door_instance if door_instance is Area2D else null
		if not target_area:
			for child in door_instance.get_children():
				if child is Area2D:
					target_area = child
					break
		
		# 6. Conectamos la señal nativa de Godot amarrando (bind) el destino dinámico
		if target_area:
			# Usamos .bind() para inyectar de forma segura el ID de destino al hacer clic
			target_area.input_event.connect(_on_dynamic_door_clicked.bind(destination_room_id))
			#print("[TestMainGame] Sensores de físicas listos. Puerta amarrada al cuarto ID: ", destination_room_id)
		else:
			push_error("[TestMainGame] Advertencia: No se encontró ningún Area2D en la puerta.")
			
	else:
		push_error("[TestMainGame] Fallo crítico: El Director devolvió un nodo nulo al intentar añadir la puerta.")
		
		
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

#########################
# SECTION Initial Room  #
#########################
			
## Sets up the initial room layout. If skip_animations is true, it builds instantly.
func _on_ready_initialRoom(data: Dictionary, skip_animations: bool = false) -> void:
	current_room_id = data["id_room"]
	
	# A) Desvanecimiento (Solo si NO saltamos animaciones)
	if not skip_animations:
		var fade_out_tween: Tween = EssenceUIAnimator.fade_out(background_layer, 0.4)
		if fade_out_tween: 
			await fade_out_tween.finished
			
	# LIMPIEZA TOTAL
	director.clear_character_stage()
	active_character = null
	director.clear_item_stage()
	spawned_doors_in_room.clear()
	director.unload_location()
	
	# B) Cambiamos la textura al fondo original
	match data["id_background_scene"]:
		LevelManager.BackgroundImageID["INITIAL_ROOM"]:
			background_layer.texture = load(EssencePaths.BACKGROUND_ROOM_INITIAL)
			
	# C) Revelamos el nuevo fondo
	if not skip_animations:
		var fade_in_tween: Tween = EssenceUIAnimator.fade_in(background_layer, 0.5)
		if fade_in_tween: 
			await fade_in_tween.finished
	else:
		# Si saltamos la animación, forzamos la opacidad al 100% por seguridad
		background_layer.modulate.a = 1.0
		
	# D) Pasamos el control al Director de la Trama
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])

#########################
# SECTION Room 3 Doors  #
#########################

## Sets up the 3 doors room. If skip_animations is true, it builds instantly.
func _on_ready_room3doors(data: Dictionary, skip_animations: bool = false) -> void:
	current_room_id = data["id_room"]
	
	if not skip_animations:
		var fade_out_tween: Tween = EssenceUIAnimator.fade_out(background_layer, 0.4)
		if fade_out_tween: await fade_out_tween.finished
	
	# LIMPIEZA TOTAL
	director.clear_character_stage()
	active_character = null
	director.clear_item_stage()
	spawned_doors_in_room.clear()
		
	match data["id_background_scene"]:
		LevelManager.BackgroundImageID["ROOM_3_DOORS"]:
			background_layer.texture = load(EssencePaths.BACKGROUND_ROOM_3DOORS)
			
	# Carga de la locación con colisiones
	var scene_path: String = DemoItemsRoute.TESTROOMDOOR_SCENE
	var interactive_scene: PackedScene = load(scene_path) as PackedScene
	if interactive_scene:
		director.load_location(interactive_scene)
		var current_loc = director.current_location_node
		if current_loc and current_loc.has_signal("navigation_requested"):
			current_loc.navigation_requested.connect(_on_room_navigation_requested)
	
	if not skip_animations:
		var fade_in_tween: Tween = EssenceUIAnimator.fade_in(background_layer, 0.5)
		if fade_in_tween: await fade_in_tween.finished
	else:
		background_layer.modulate.a = 1.0
		
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])
