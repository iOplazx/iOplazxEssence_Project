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
# │   └── HUD_Layer (CanvasLayer)
# │       ├── TranslationManager (Node)           
# │       └── DialogBoxUI (Node)            
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
@export var ui_principal: Control # Útil para ocultarla al tomar la foto de guardado

@export_category("World Connections")
@export var character: EssenceInteractiveActor 

# Usamos % en lugar de $ para acceder al instante sin importar la jerarquía
@onready var director: EssenceGameplayDirector = %GameplayDirector
@onready var area2D_door: Area2D = %Area2D_door

const ROUTES_PATH = "res://_static/RouteConfig.tres"
var routes: EssenceRouteConfig

# Variable global para saber en qué ID de habitación numérica estamos parados
var current_room_id: int = LevelManager.RoomID["INITIAL_ROOM"]

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
	_config_character()
	
	# 1. Le decimos al Director que active el modo exploración 
	# (para que permita los clics en el entorno)
	director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
	
	# 2. Conectamos la señal de clic de nuestra ImgPuerta
	if area2D_door:
		area2D_door.input_event.connect(_on_img_puerta_input_event)
	
	# Ocultamos al personaje al inicio de la escena
	if character:
		character.modulate.a = 0.0
		character.is_interactable = false
	
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
		
		# Cambiamos de fase
		current_phase = TestPhase.GAMEPLAY
		
		await get_tree().create_timer(0.6).timeout 
		
		# 2. Hacemos aparecer al personaje usando la "Solución Annie"
		if character:
			if character.has_method("toggle_garment"):
				character.toggle_garment("GenericChrHat", false)
				character.toggle_garment("GenericChrSunglass", false)
			
			character.visible = true
			
			# Hacemos que la raíz vuelva a ser sólida para que el hijo pueda verse
			character.modulate.a = 1.0 
			
			character.is_interactable = false # Lo bloqueamos mientras aparece
			
			# Buscamos el contenedor
			var container = character.get_node_or_null("SubViewportContainer")
			
			if container and container is SubViewportContainer:
				# Hacemos invisible la "foto" completa
				container.modulate.a = 0.0
				
				var tween = create_tween()
				tween.tween_property(container, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
				
				tween.finished.connect(func(): character.is_interactable = true)
			else:
				print("ERROR: No se encontró el SubViewportContainer en el personaje.")
	
# ==========================================
# BLINDAJE DE SEGURIDAD
# ==========================================
func _check_security_nodes() -> void:
	var missing = []
	if not btn_return: missing.append("btn_return")
	if not btn_save: missing.append("btn_save")
	if not btn_load: missing.append("btn_load")
	if not tutorial_panel: missing.append("tutorial_panel")
	if not character: missing.append("character")
	
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

func _config_character() -> void:
	if character:
		character.clicked_on_character.connect(_on_character_interacted)

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
	
	# AGREGAMOS "fase_actual" AL DICCIONARIO
	var current_game_data = {
		"escena_actual": "MainRoom",
		"fase_actual": current_phase, 
		"ropa_estado_personaje": character.get_clothing_state() if character else {}
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
	
	# 1. Recuperamos la fase (Lo forzamos a int por si Godot se confunde con el Enum)
	current_phase = int(datos.get("fase_actual", 0))
	
	# 2. Restauramos la ropa del personaje
	if character:
		var ropa_guardada = datos.get("ropa_estado_personaje", {})
		character.load_clothing_state(ropa_guardada)
		
	# 3. TOMAMOS ACCIONES SEGÚN LA FASE RECUPERADA
	if current_phase == TestPhase.GAMEPLAY:
		print("[%s] Fase GAMEPLAY detectada. Mostrando personaje." % ES_NAME_CLASS)
		
		
		if character:
			character.visible = true 
			character.modulate.a = 1.0
			character.is_interactable = true
			
		# Nos aseguramos de que el tutorial no estorbe
		if tutorial_panel:
			tutorial_panel.visible = false 
			
	else:
		print("[%s] Fase INTRO detectada. Lanzando tutorial inicial." % ES_NAME_CLASS)
		
		# Guardó durante la intro: el personaje sigue oculto y relanzamos el tutorial
		if character:
			character.visible = false
			character.modulate.a = 0.0
			character.is_interactable = false
		_iniciar_secuencia_intro()
		
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
	# Verificamos que estemos en Gameplay y que el personaje ya sea interactuable
	if current_phase == TestPhase.GAMEPLAY and character.is_interactable:
		print("[%s] El jugador interactuó con: %s" % [ES_NAME_CLASS, character.display_name])
		
		if tutorial_panel:
			var interaction_messages: Array[String] = [
				"Character Interaction Detected!",
				"Try removing some of my clothes using the Inspector, or via code.",
				"Then, save the game and load it to verify the Wardrobe System."
			]
			tutorial_panel.load_and_show_tutorial(interaction_messages)
			
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
	
	# ------------------------------------------------==========================
	# PASO 1: ANIMACIÓN DE SALIDA (FADE OUT)
	# ----------------------------------------------------------------==========
	# Desvanecemos el fondo viejo durante 0.4 segundos
	var fade_out_tween: Tween = EssenceUIAnimator.fade_out(background_layer, 0.4)
	
	# La palabra mágica 'await' frena este script hasta que el Fade Out termine al 100%
	if fade_out_tween:
		await fade_out_tween.finished
		
	# ------------------------------------------------==========================
	# PASO 2: CAMBIO DE TEXTURA (OCULTO)
	# ----------------------------------------------------------------==========
	# Ahora que el TextureRect es transparente, cambiamos la imagen sin que el jugador note el "salto"
	match data["id_background_scene"]:
		LevelManager.BackgroundImageID["ROOM_3_DOORS"]:
			background_layer.texture = load(EssencePaths.BACKGROUND_ROOM_3DOORS)
		_:
			push_warning("Background ID not recognized.")
			
	# ------------------------------------------------==========================
	# PASO 3: ANIMACIÓN DE ENTRADA (FADE IN)
	# ----------------------------------------------------------------==========
	# Revelamos el nuevo fondo suavemente durante 0.5 segundos
	var fade_in_tween: Tween = EssenceUIAnimator.fade_in(background_layer, 0.5)
	
	# ------------------------------------------------==========================
	# PASO 4: CARGAR E INYECTAR LA ESCENA INTERACTIVA
	# ----------------------------------------------------------------==========
	# Colocamos los hotspots en la pantalla (las puertas se instanciarán listas pero inmóviles)
	var scene_path: String = DemoItemsRoute.TESTROOMDOOR_SCENE
	var interactive_scene: PackedScene = load(scene_path) as PackedScene
	
	if interactive_scene:
		director.load_location(interactive_scene)
		
		# Conectamos las señales dinámicas para futuras navegaciones
		var current_loc = director.current_location_node
		if current_loc and current_loc.has_signal("navigation_requested"):
			current_loc.navigation_requested.connect(_on_room_navigation_requested)
	else:
		push_error("Failed to load interactive scene from path: " + scene_path)
		
	# Esperamos a que el nuevo fondo termine de revelarse por completo
	if fade_in_tween:
		await fade_in_tween.finished
		
	# ------------------------------------------------==========================
	# PASO 5: ACTIVAR LA INTERACCIÓN (SÓLO CUANDO ACABE LA ANIMACIÓN)
	# ----------------------------------------------------------------==========
	# Ahora que la pantalla ya está completamente visible, le damos el control al jugador
	match data["interaction_mode"]:
		0:
			director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
		1:
			director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
		2:
			director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
			# Aquí iría tu lógica si el modo 2 necesita apagar alguna puerta tras la transición


## Central listener that processes all navigation signals coming from inside the active rooms.
func _on_room_navigation_requested(next_place: int, mode: int, is_only_mode: bool) -> void:
	# Consultamos a nuestra matriz usando nuestro rastreador dinámico 'current_room_id'
	var data = LevelManager.get_scenery_config(current_room_id, next_place, mode, is_only_mode)
	
	if data["flag_error"]:
		push_error("[TestMainGame] Illegal transition requested by room layout.")
		return
		
	# Redirigimos el resultado al callback del cuarto correspondiente
	match data["id_room"]:
		LevelManager.RoomID["INITIAL_ROOM"]:
			pass # Aquí llamarías a tu función: _on_ready_initial_room(data)
		LevelManager.RoomID["ROOM_3_DOORS"]:
			_on_ready_room3doors(data)
		LevelManager.RoomID["ROOM_1_DOOR"]:
			pass # Aquí llamarías a tu función: _on_ready_room1door(data)
