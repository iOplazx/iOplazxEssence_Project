extends Control

@export var btn_save: Button
@export var btn_load: Button
@export var btn_return: Button
@export var lbl_output: Label
@export var test_element: ColorRect
@export var btn_no_implement: Button
@export var btn_warning: Button

const ROUTES_PATH = EssencePaths.CARPET_STATIC + "RouteConfig.tres"
var routes: EssenceRouteConfig

func _ready():
	_config_button()
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig
		
	# 1. Asignamos un color aleatorio SIEMPRE al entrar (simulando una partida nueva)
	if test_element:
		test_element.color = Color(randf(), randf(), randf())
		lbl_output.text = "Escena lista.\nColor nuevo generado: #" + test_element.color.to_html(false)

	# 2. Revisamos si venimos de la pantalla de Cargar Partida
	if not SaveManager.loaded_game_data.is_empty():
		_restaurar_partida_cargada()
		
			
func _config_button():
	var buttons_to_setup = [
		[btn_save, _on_btn_save_game_pressed, "btn_save"],
		[btn_load, _on_btn_load_game_pressed, "btn_load"],
		[btn_return, _on_return_pressed, "btn_return"],
		[btn_no_implement, _on_no_implement_pressed, "btn_no_implement"],
		[btn_warning, _on_print_warning_pressed, "btn_warning"]
	]

	for data in buttons_to_setup:
		var btn_node = data[0]
		var btn_func = data[1]
		var btn_name = data[2]

		# Validamos que el nodo sea una instancia válida antes de conectar [cite: 31]
		if is_instance_valid(btn_node):
			if not btn_node.pressed.is_connected(btn_func):
				btn_node.pressed.connect(btn_func)
		else:
			# Si el botón no existe, mandamos un warning al nuevo sistema [cite: 31]
			EssenceError.report(
			"UI Reference Lost", 
			"The button '%s' is missing in the inspector." % btn_name, 
			EssenceError.Severity.WARNING
			)
			
func _preparar_datos_para_menu():
	lbl_output.text = "Capturando pantalla..."
	
	# Forzamos un frame de espera ANTES de la captura para limpiar basura visual
	await get_tree().process_frame
	await SaveManager.take_temp_screenshot()
	
	# Un pequeño delay extra para que el Athlon termine de escribir el archivo .webp
	# 0.1 segundos es imperceptible pero vital para el disco duro
	await get_tree().create_timer(0.1).timeout
	
	var current_game_data = {
		"box_color": test_element.color.to_html(false) if test_element else "ffffff",
		"player_hp": 100 
	}
	
	var current_meta_data = {
		"title": "Prueba de Guardado",
		"description": "Escena Sandbox - Nivel 1",
		"play_time": "99:15:20"
	}
	
	# Llenamos la caché (Esto es lo que avisa al Modern UI que hay partida)
	SaveManager.cache_current_state(current_game_data, current_meta_data)

func _restaurar_partida_cargada():
	# Extraemos los datos del bolsillo
	var saved_color_hex = SaveManager.loaded_game_data.get("box_color", "ffffff")
	var saved_hp = SaveManager.loaded_game_data.get("player_hp", 0)
	
	# ¡EL ARREGLO ESTÁ AQUÍ!
	# Validamos que el texto tenga el prefijo "#" para que Godot no se confunda
	if not saved_color_hex.begins_with("#"):
		saved_color_hex = "#" + saved_color_hex
	
	# Restauramos el color usando el formato estricto
	if test_element:
		test_element.color = Color(saved_color_hex)
	
	# Imprimimos el reporte detallado en el Output
	var info_text = "¡PARTIDA CARGADA!\n"
	info_text += "Color restaurado: " + saved_color_hex + "\n"
	info_text += "HP del Jugador: " + str(saved_hp)
	
	lbl_output.text = info_text
	
	# Limpiamos el caché para evitar bugs de carga infinita
	SaveManager.loaded_game_data.clear()

func _on_btn_save_game_pressed():
	await _preparar_datos_para_menu()
	SceneManager.goto_save_game(SceneManager.TransitionType.INSTANT)

func _on_btn_load_game_pressed():
	await _preparar_datos_para_menu()
	SceneManager.goto_load_game(SceneManager.TransitionType.INSTANT)

func _on_return_pressed():
	SceneManager.goto_main_menu()

func _on_no_implement_pressed():
	EssenceError.ExceptionNotImplement("Prueba")

func _on_print_warning_pressed():
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceLogger.system_info("prueba")
	EssenceError.report("Hardware Check", "La GPU está trabajando a temperatura alta.", EssenceError.Severity.WARNING)
