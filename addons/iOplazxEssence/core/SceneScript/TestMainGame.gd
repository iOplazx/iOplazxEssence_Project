class_name TestMainGame
extends Control 

const ES_NAME_CLASS = "TestMainGame"

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

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	_check_security_nodes()
	_config_buttons()
	_config_character()
	
	# Revisamos si venimos de Cargar una Partida
	if is_instance_valid(SaveManager) and not SaveManager.loaded_game_data.is_empty():
		_restaurar_partida_cargada()
		
	EssenceLogger.system_info("[%s/_ready] Escena principal inicializada." % ES_NAME_CLASS)

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
		if is_instance_valid(EssenceError) and EssenceError.has_method("report"):
			EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)
		else:
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
	EssenceLogger.system_info("[%s] Capturando pantalla y preparando datos..." % ES_NAME_CLASS)
	
	# 1. Esperamos y tomamos la foto (exactamente como en tu game.gd)
	await get_tree().process_frame
	await SaveManager.take_temp_screenshot()
	await get_tree().create_timer(0.1).timeout
	
	# 2. Preparamos los datos del nivel y de los personajes
	var current_game_data = {
		"escena_actual": "MainRoom",
		# ¡Aquí usamos el nuevo framework! El personaje devuelve su ropa dinámicamente
		"ropa_estado_personaje": character.get_clothing_state() if character else {}
	}
	
	var current_meta_data = {
		"title": "Prueba de Framework",
		"description": "Probando Guardado Modular",
		"play_time": "00:01:00"
	}
	
	SaveManager.cache_current_state(current_game_data, current_meta_data)

func _restaurar_partida_cargada() -> void:
	EssenceLogger.system_info("[%s] Restaurando datos cargados." % ES_NAME_CLASS)
	var datos = SaveManager.loaded_game_data
	
	# 1. Restauramos al personaje
	if character:
		var ropa_guardada = datos.get("ropa_estado_personaje", {})
		# El framework se encarga de aplicar los nodos visuales
		character.load_clothing_state(ropa_guardada)
	
	# 2. Limpiamos para que no se recargue infinitamente
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
	EssenceLogger.system_info("[%s] El jugador interactuó con: %s" % [ES_NAME_CLASS, character.display_name])
	
	# Cambiamos algo de ropa de forma dinámica para ver si se guarda
	# (Esto asume que le pusiste una prenda llamada "Camisa" en su Wardrobe Nodes)
	# character.toggle_garment("Camisa", false) 
	
	if tutorial_panel:
		var mensajes_demo: Array[String] = [
			"Prueba a quitarme alguna prenda desde el inspector o el código...",
			"Luego pulsa 'Save' y ve al menú de guardado.",
			"Cuando cargues la partida, ¡debería tener la misma ropa!"
		]
		tutorial_panel.load_and_show_tutorial(mensajes_demo)
		
