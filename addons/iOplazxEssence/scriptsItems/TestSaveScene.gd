class_name EssenceSandboxSave extends Control

const ES_NAME_CLASS = "EssenceSandboxSave"

@export_category("UI Connections")
@export var btn_save: Button
@export var btn_load: Button
@export var btn_return: Button
@export var lbl_output: Label
@export var test_element: ColorRect

@export_category("Test Triggers")
@export var btn_no_implement: Button
@export var btn_warning: Button

const ROUTES_PATH = EssencePaths.CARPET_STATIC + "RouteConfig.tres"
var routes: EssenceRouteConfig

func _ready():
	_check_security_nodes()
	_config_button()
	
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig
		
	# 1. Asignamos un color aleatorio SIEMPRE al entrar
	if test_element:
		test_element.color = Color(randf(), randf(), randf())
		if lbl_output:
			lbl_output.text = "Escena lista.\nColor nuevo generado: #" + test_element.color.to_html(false)
		EssenceLogger.system_info("[%s/_ready] Sandbox initialized with color: #%s" % [ES_NAME_CLASS, test_element.color.to_html(false)])

	# 2. Revisamos si venimos de la pantalla de Cargar Partida
	if is_instance_valid(SaveManager) and not SaveManager.loaded_game_data.is_empty():
		_restaurar_partida_cargada()

# ==========================================
# BLINDAJE DE SEGURIDAD
# ==========================================
func _check_security_nodes():
	var missing = []
	if not btn_save: missing.append("btn_save")
	if not btn_load: missing.append("btn_load")
	if not btn_return: missing.append("btn_return")
	if not lbl_output: missing.append("lbl_output")
	if not test_element: missing.append("test_element")
	if not btn_no_implement: missing.append("btn_no_implement")
	if not btn_warning: missing.append("btn_warning")
	
	if missing.size() > 0:
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		if is_instance_valid(EssenceError) and EssenceError.has_method("report"):
			EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)
		else:
			push_error(msg)

# ==========================================
# CONFIGURACIÓN DE BOTONES
# ==========================================
func _config_button():
	# Usamos un diccionario/arreglo más directo ya que el blindaje maneja los errores visuales
	if btn_save: btn_save.pressed.connect(func(): _play_sfx(); _on_btn_save_game_pressed())
	if btn_load: btn_load.pressed.connect(func(): _play_sfx(); _on_btn_load_game_pressed())
	if btn_return: btn_return.pressed.connect(func(): _play_sfx(); _on_return_pressed())
	if btn_no_implement: btn_no_implement.pressed.connect(func(): _play_sfx(); _on_no_implement_pressed())
	if btn_warning: btn_warning.pressed.connect(func(): _play_sfx(); _on_print_warning_pressed())

func _play_sfx():
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()

# ==========================================
# LÓGICA DE GUARDADO / CARGA
# ==========================================
func _preparar_datos_para_menu():
	if lbl_output: lbl_output.text = "Capturando pantalla..."
	EssenceLogger.system_info("[%s/_preparar_datos] Taking temporary screenshot..." % ES_NAME_CLASS)
	
	# Forzamos un frame de espera ANTES de la captura para limpiar basura visual
	await get_tree().process_frame
	await SaveManager.take_temp_screenshot()
	
	# Un pequeño delay extra para terminar de escribir el archivo .webp (Optimizado para I/O)
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
	
	EssenceLogger.system_info("[%s/_preparar_datos] Caching state in SaveManager." % ES_NAME_CLASS)
	SaveManager.cache_current_state(current_game_data, current_meta_data)

func _restaurar_partida_cargada():
	EssenceLogger.system_info("[%s/_restaurar_partida] Restoring loaded data from SaveManager." % ES_NAME_CLASS)
	
	var saved_color_hex = SaveManager.loaded_game_data.get("box_color", "ffffff")
	var saved_hp = SaveManager.loaded_game_data.get("player_hp", 0)
	
	if not saved_color_hex.begins_with("#"):
		saved_color_hex = "#" + saved_color_hex
	
	if test_element:
		test_element.color = Color(saved_color_hex)
	
	if lbl_output:
		var info_text = "¡PARTIDA CARGADA!\n"
		info_text += "Color restaurado: " + saved_color_hex + "\n"
		info_text += "HP del Jugador: " + str(saved_hp)
		lbl_output.text = info_text
	
	# Limpiamos el caché
	SaveManager.loaded_game_data.clear()

# ==========================================
# EVENTOS
# ==========================================
func _on_btn_save_game_pressed():
	await _preparar_datos_para_menu()
	SceneManager.goto_save_game(SceneManager.TransitionType.INSTANT)

func _on_btn_load_game_pressed():
	await _preparar_datos_para_menu()
	SceneManager.goto_load_game(SceneManager.TransitionType.INSTANT)

func _on_return_pressed():
	EssenceLogger.system_info("[%s/_on_return] Returning to main menu." % ES_NAME_CLASS)
	SceneManager.goto_main_menu()

func _on_no_implement_pressed():
	EssenceError.ExceptionNotImplement("Prueba")

func _on_print_warning_pressed():
	EssenceError.report("Hardware Check", "La GPU está trabajando a temperatura alta.", EssenceError.Severity.WARNING)