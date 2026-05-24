class_name TestMainGame
extends Control 

# ==
# TestMainGame.tscn
# ==
# TestMainGame (TestMainGame) [Script: TestMainGame]
# ├── background (TestureRect)                     
# ├── GameplayDirector (EssenceGameplayDirector)   
# │   ├── EnveriromentFilter (CanvasModulate)           
# │   ├── ActiveLocation (Node2D)           
# │   │   └── ImgPuerta (Node2D)  
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
		
		# ¡TU DEDUCCIÓN APLICADA AQUÍ!
		if character:
			character.visible = true # <--- Obligamos al motor a dibujarlo
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

## Esta función se dispara automáticamente cuando el ratón hace algo sobre ImgPuerta
func _on_img_puerta_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# Verificamos que el archivo de rutas se haya cargado bien
		if routes == null:
			push_error("No se pueden cargar escenas porque RouteConfig es nulo.")
			return
			
		# Buscamos la clave en tu diccionario custom_routes (asegúrate de que el nombre coincida)
		var clave_habitacion = "room_3"
		
		if routes.custom_routes.has(clave_habitacion):
			var ruta_escena = routes.custom_routes[clave_habitacion]
			var escena_a_cargar = load(ruta_escena) as PackedScene
			
			print("Cargando nivel desde ruta dinámica: ", ruta_escena)
			director.load_location(escena_a_cargar)
		else:
			push_error("La clave '%s' no existe en el diccionario custom_routes." % clave_habitacion)
