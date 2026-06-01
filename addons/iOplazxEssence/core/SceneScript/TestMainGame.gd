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
@onready var area2D_door: Area2D = %Area2D_door
@onready var active_location_container: Node2D = %GameplayDirector/ActiveLocation

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
	if area2D_door:
		area2D_door.input_event.connect(_on_img_puerta_input_event)
	
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

func _on_tutorial_finished() -> void:
	if current_phase == TestPhase.INTRO:
		print("[%s] Tutorial Intro terminado. Esperando cierre de UI..." % ES_NAME_CLASS)
		current_phase = TestPhase.GAMEPLAY
		
		await get_tree().create_timer(0.6).timeout 
		
		# Invocamos al personaje con animación suave (is_instant = false)
		_spawn_main_character(LevelManager.RoomID["INITIAL_ROOM"], 0, false)
		
		# Quitamos accesorios por defecto
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
	
	# === AQUÍ REEMPLAZAMOS TU ANTIGUO _config_character() ===
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
			print("Cargando habitación inicial...")
			# Aquí llamarías a tu función si la tienes: _on_ready_initial_room(data)
		LevelManager.RoomID["ROOM_3_DOORS"]:
			_on_ready_room3doors(data)
		LevelManager.RoomID["ROOM_1_DOOR"]:
			print("Cargando habitación de 1 puerta...")
			# Aquí llamarías a tu función si la tienes: _on_ready_room1door(data)

## Evaluates story conditions before enabling player control inside a room.
## [param room_id]: The active Room ID from LevelManager.
## [param default_mode]: The fallback interaction mode if no story events trigger.
func _evaluate_room_narrative_entry(room_id: int, default_mode: int) -> void:
	match room_id:
		LevelManager.RoomID["ROOM_3_DOORS"]:
			# 1. ¿Hay alguna interrupción narrativa de la historia? (Ej: El teléfono)
			if story_flags["is_phone_event_active"]:
				print("[Story] ¡EVENTO DETECTADO! Alguien llama al telefono. Bloqueando exploracion.")
				
				# Forzamos el estado cinemático/diálogo
				director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
				
				# TODO: Aquí disparas tu cuadro de texto (DialogBoxUI) para la llamada.
				# Cuando el jugador termine de leer ese diálogo, el botón de "Continuar" de la UI
				# será el encargado de llamar a: update_current_room_mode(1) para desbloquear el cuarto.
				
				story_flags["is_phone_event_active"] = false # Consumimos el evento
				return # Cortamos el flujo aquí; el teléfono tomó el control.
			
			# 2. ¡VALIDACIÓN EXITOSA! No hay eventos de historia pendientes en este cuarto.
			print("[Story] No hay eventos narrativos pendientes. Promoviendo a Exploracion (Modo 1).")
			
			# Le pedimos al LevelManager que nos devuelva las reglas del Modo 1 de forma interna (is_only_change_mode = true)
			var data = LevelManager.get_scenery_config(room_id, room_id, 1, true)
			if not data["flag_error"]:
				_apply_interaction_state(data["interaction_mode"])
				
		LevelManager.RoomID["INITIAL_ROOM"]:
			# Para la habitación inicial aplicamos el comportamiento directo que venga de la matriz
			_apply_interaction_state(default_mode)

## Helper method to translate matrix modes into director game states.
func _apply_interaction_state(matrix_mode: int) -> void:
	match matrix_mode:
		0:
			director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
		1, 2:
			director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
			
## Clears and removes all instantiated nodes inside the ActiveLocation container.
func unload_location() -> void:
	if not active_location_container: return
	
	for child in active_location_container.get_children():
		child.queue_free()
		
	print("[EssenceGameplayDirector] ActiveLocation container cleared successfully.")
			
#########################
# SECTION Initial Room  #
#########################
			
func _on_ready_initialRoom(data: Dictionary) -> void:
	pass

## Esta función se dispara automáticamente cuando el ratón hace algo sobre ImgPuerta
func _on_img_puerta_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# 1. Consultamos a la matriz (Pasamos de INITIAL_ROOM a ROOM_3_DOORS)
		var data = LevelManager.get_scenery_config(
			LevelManager.RoomID["INITIAL_ROOM"], 
			LevelManager.RoomID["ROOM_3_DOORS"], 
			0, 
			false
		)
		
		# 2. Si no hay error, disparamos tu callback específico
		if not data["flag_error"]:
			_on_ready_room3doors(data)


#########################
# SECTION Room 3 Doors  #
#########################

## Sets up the 3 doors room by applying backgrounds with animations, loading scenes, and updating director states
func _on_ready_room3doors(data: Dictionary) -> void:
	current_room_id = data["id_room"]
	
	# [Toda tu lógica técnica de animaciones y cargas se queda exactamente IGUAL]
	var fade_out_tween: Tween = EssenceUIAnimator.fade_out(background_layer, 0.4)
	if fade_out_tween: await fade_out_tween.finished
		
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
		
	# --- EL CAMBIO ARQUITECTÓNICO ESTÁ AQUÍ ---
	# En lugar de hacer un match directo de 'data["interaction_mode"]', 
	# le pasamos el control al "Director de la Trama" y le sugerimos el modo por defecto.
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])
	
