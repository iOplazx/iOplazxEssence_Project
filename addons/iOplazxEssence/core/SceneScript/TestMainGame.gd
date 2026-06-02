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
	_cargar_configuracion()
	_check_security_nodes()
	_config_buttons()
	
	# 1. Le decimos al Director que active el modo exploración 
	# (para que permita los clics en el entorno)
	director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
	
	# 2. Conectamos la señal de clic de nuestra ImgPuerta
	#_setup_initial_room_layout()
	
	director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
	
	# Conectamos la señal de cuando el tutorial se cierra
	if tutorial_panel:
		tutorial_panel.tutorial_finished.connect(_on_tutorial_finished)
	
	# Revisamos si venimos de Cargar una Partida o si es juego nuevo
	if is_instance_valid(SaveManager) and not SaveManager.loaded_game_data.is_empty():
		_restaurar_partida_cargada()
	else:
		# Si es juego nuevo, iniciamos la secuencia
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
		
		# 💾 CAMBIO CRUCIAL: Guardamos en la historia que ya pasamos por aquí
		story_flags["is_first_time_here"] = false
		
		await get_tree().create_timer(0.6).timeout 
		
		_instanciar_actor_principal()
			
func _instanciar_actor_principal():
	# Invocamos al personaje de forma animada (primera aparición)
	_spawn_main_character(LevelManager.RoomID["INITIAL_ROOM"], 0, false)
	
	# Invocamos la puerta inicial dinámicamente para que pueda viajar por primera vez
	_spawn_navigation_door(0, LevelManager.RoomID["ROOM_3_DOORS"])
	
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
	
	var current_game_data = {
		"escena_actual": "MainRoom",
		"fase_actual": current_phase, 
		# Validamos de forma segura si el personaje existe antes de pedirle su ropa
		"ropa_estado_personaje": active_character.get_clothing_state() if is_instance_valid(active_character) else {}
	}
	
	var current_meta_data = {
		"title": "Prueba de Framework",
		"description": "Fase actual: " + ("Intro" if current_phase == TestPhase.INTRO else "Gameplay"),
		"play_time": "00:01:00"
	}
	
	SaveManager.cache_current_state(current_game_data, current_meta_data)

func _restaurar_partida_cargada() -> void:
	print("[%s] Restaurando datos cargados." % ES_NAME_CLASS)
	var datos = SaveManager.loaded_game_data
	
	# 1. Recuperamos la fase
	current_phase = int(datos.get("fase_actual", 0))
		
	# 2. TOMAMOS ACCIONES SEGÚN LA FASE RECUPERADA
	if current_phase == TestPhase.GAMEPLAY:
		print("[%s] Fase GAMEPLAY detectada. Invocando personaje y restaurando ropa." % ES_NAME_CLASS)
		
		# ¡Invocamos al personaje de golpe (is_instant = true)!
		_spawn_main_character(LevelManager.RoomID["INITIAL_ROOM"], 0, true)
		
		# Ahora que ya existe en la memoria, le ponemos la ropa que tenía guardada
		if is_instance_valid(active_character):
			var ropa_guardada = datos.get("ropa_estado_personaje", {})
			active_character.load_clothing_state(ropa_guardada)
			
		# Nos aseguramos de que el tutorial no estorbe
		if tutorial_panel:
			tutorial_panel.visible = false 
			
	else:
		print("[%s] Fase INTRO detectada. Lanzando tutorial inicial." % ES_NAME_CLASS)
		_iniciar_secuencia_intro() # El personaje no se invoca, aparecerá cuando acabe el tuto
		
	# Limpiamos para no crear bucles de recarga
	SaveManager.loaded_game_data.clear()

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
	# 1. Consultamos a la matriz estática del LevelManager usando nuestro rastreador dinámico 'current_room_id'
	var data = LevelManager.get_scenery_config(current_room_id, next_place, mode, is_only_mode)
	
	# 2. Si la matriz dice que el viaje es ilegal, frenamos
	if data["flag_error"]:
		push_error("[TestMainGame] Illegal transition requested by room layout.")
		return
		
	# 3. Si es un cambio de modo interno (ej. desbloquear exploración), usamos la función directa
	if is_only_mode:
		_apply_interaction_state(data["interaction_mode"])
		return
		
	# 4. Si es un viaje real a otra habitación, redirigimos el resultado al callback del cuarto correspondiente
	match data["id_room"]:
		LevelManager.RoomID["INITIAL_ROOM"]:
			# Conectamos tu nueva función mágica de retorno
			_on_ready_initialRoom(data)
		LevelManager.RoomID["ROOM_3_DOORS"]:
			_on_ready_room3doors(data)
		LevelManager.RoomID["ROOM_1_DOOR"]:
			print("Cargando habitación de 1 puerta...")
			# Aquí llamarías a tu función si la tienes: _on_ready_room1door(data)

## Evaluates story conditions before enabling player control inside a room.
## [param room_id]: The active Room ID from LevelManager.
## [param default_mode]: The fallback interaction mode if no story events trigger.
func _evaluate_room_narrative_entry(room_id: int, default_mode: int) -> void:
	
	# 1. 🛑 PASO POR EL FILTRO INTERMEDIO
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
			_instanciar_actor_principal()
			
		LevelManager.RoomID["ROOM_3_DOORS"]:
			_spawn_navigation_door(0, LevelManager.RoomID["ROOM_1_DOOR"])
			_spawn_navigation_door(1, LevelManager.RoomID["INITIAL_ROOM"])
			
			# Si tuvieras un ItemManager, aquí harías aparecer la mochila o cosas fijas:
			# _spawn_screen_item(StageItemManager.ItemID["BACKPACK_ICON"], 0)
				
## Checks for pending story events in the given room.
## Returns TRUE if an event intercepted the flow, FALSE if the room is clear.
func _check_room_interruptions(room_id: int) -> bool:
	match room_id:
		LevelManager.RoomID["INITIAL_ROOM"]:
			# Interrupción: Es la primera vez en el juego (Tutorial)
			if story_flags.get("is_first_time_here", false):
				#print("[Story] Interrupción: Primera vez en la habitación inicial. Esperando tutorial.")
				# Lo dejamos en modo diálogo/bloqueado. El tutorial lo desbloqueará.
				director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
				return true # 🛑 Retorna TRUE para detener el flujo normal
				
		LevelManager.RoomID["ROOM_3_DOORS"]:
			# Interrupción: El teléfono está sonando
			if story_flags.get("is_phone_event_active", false):
				print("[Story] Interrupción: ¡Alguien llama al telefono! Bloqueando exploracion.")
				director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
				
				# TODO: Lanzar el UI de diálogo del teléfono aquí...
				
				story_flags["is_phone_event_active"] = false # Consumimos el evento
				return true # 🛑 Retorna TRUE para detener el flujo normal
				
	# Si llega hasta aquí, significa que ningún 'if' se cumplió. ¡Todo está despejado!
	return false # ✅ Retorna FALSE permitiendo que la exploración continúe

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
			
## Sets up the initial room layout when returning to it, cleaning assets and updating states.
func _on_ready_initialRoom(data: Dictionary) -> void:
	current_room_id = data["id_room"]
	
	# A) Desvanecemos el fondo viejo durante 0.4 segundos
	var fade_out_tween: Tween = EssenceUIAnimator.fade_out(background_layer, 0.4)
	if fade_out_tween: 
		await fade_out_tween.finished
		
	# 🧹 LIMPIEZA TOTAL (Detrás de cámaras)
	director.clear_character_stage()
	active_character = null
	director.clear_item_stage()
	spawned_doors_in_room.clear()
	director.unload_location()
	
	# B) Cambiamos la textura al fondo original de la habitación inicial
	match data["id_background_scene"]:
		LevelManager.BackgroundImageID["INITIAL_ROOM"]:
			background_layer.texture = load(EssencePaths.BACKGROUND_ROOM_INITIAL)
			
	# C) Revelamos el nuevo fondo suavemente durante 0.5 segundos
	var fade_in_tween: Tween = EssenceUIAnimator.fade_in(background_layer, 0.5)
	
	# D) Cargamos la locación interactiva base (si tiene colisiones fijas de fondo)
	#var scene_path: String = DemoItemsRoute.TESTINITIALROOM_SCENE # Asegúrate de tener esta ruta
	#var interactive_scene: PackedScene = load(scene_path) as PackedScene
	
	#if interactive_scene:
	#	director.load_location(interactive_scene)
	#	var current_loc = director.current_location_node
	#	if current_loc and current_loc.has_signal("navigation_requested"):
	#		current_loc.navigation_requested.connect(_on_room_navigation_requested)
			
	if fade_in_tween: 
		await fade_in_tween.finished
		
	# E) Pasamos el control al Director de la Trama
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])

#########################
# SECTION Room 3 Doors  #
#########################

## Sets up the 3 doors room by applying backgrounds with animations, loading scenes, and updating director states
func _on_ready_room3doors(data: Dictionary) -> void:
	current_room_id = data["id_room"]
	
	var fade_out_tween: Tween = EssenceUIAnimator.fade_out(background_layer, 0.4)
	if fade_out_tween: await fade_out_tween.finished
	
	director.clear_character_stage()
	
	active_character = null
	
	director.clear_item_stage()
	spawned_doors_in_room.clear()
		
	match data["id_background_scene"]:
		LevelManager.BackgroundImageID["ROOM_3_DOORS"]:
			background_layer.texture = load(EssencePaths.BACKGROUND_ROOM_3DOORS)
	
	var fade_in_tween: Tween = EssenceUIAnimator.fade_in(background_layer, 0.5)
	var scene_path: String = DemoItemsRoute.TESTROOMDOOR_SCENE
	var interactive_scene: PackedScene = load(scene_path) as PackedScene
	
	if interactive_scene:
		director.load_location(interactive_scene)
		var current_loc = director.current_location_node
		if current_loc and current_loc.has_signal("navigation_requested"):
			current_loc.navigation_requested.connect(_on_room_navigation_requested)
	
	if fade_in_tween: await fade_in_tween.finished
		
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])
	
