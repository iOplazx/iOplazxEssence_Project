extends Control

@export var btn_save: Button
@export var btn_load: Button
@export var btn_return: Button
@export var lbl_output: Label
@export var test_element: ColorRect

const ROUTES_PATH = EssencePaths.CARPET_STATIC + "RouteConfig.tres"
var routes: EssenceRouteConfig

func _ready():
	btn_save.pressed.connect(_on_btn_save_game_pressed)
	btn_load.pressed.connect(_on_btn_load_game_pressed)
	btn_return.pressed.connect(_on_return_pressed)
	
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig
		
	# 1. Asignamos un color aleatorio SIEMPRE al entrar (simulando una partida nueva)
	if test_element:
		test_element.color = Color(randf(), randf(), randf())
		lbl_output.text = "Escena lista.\nColor nuevo generado: #" + test_element.color.to_html(false)

	# 2. Revisamos si venimos de la pantalla de Cargar Partida
	if not SaveManager.loaded_game_data.is_empty():
		_restaurar_partida_cargada()

func _restaurar_partida_cargada():
	# Extraemos los datos del bolsillo
	var saved_color_hex = SaveManager.loaded_game_data.get("box_color", "ffffff")
	var saved_hp = SaveManager.loaded_game_data.get("player_hp", 0)
	
	# Restauramos el color (Asegurando el formato correcto para Godot)
	if test_element:
		test_element.color = Color(saved_color_hex)
	
	# Imprimimos el reporte detallado en el Output
	var info_text = "¡PARTIDA CARGADA!\n"
	info_text += "Color restaurado: #" + saved_color_hex + "\n"
	info_text += "HP del Jugador: " + str(saved_hp)
	
	lbl_output.text = info_text
	
	# Limpiamos el caché para evitar bugs de carga infinita
	SaveManager.loaded_game_data.clear()

func _on_btn_save_game_pressed():
	lbl_output.text = "Tomando captura y preparando datos..."
	
	await SaveManager.take_temp_screenshot()
	
	# to_html(false) exporta sin el canal Alpha, lo hace más seguro al cargar
	var current_game_data = {
		"box_color": test_element.color.to_html(false) if test_element else "ffffff",
		"player_hp": 100 
	}
	
	var current_meta_data = {
		"title": "Prueba de Guardado",
		"description": "Escena Sandbox - Nivel 1",
		"play_time": "00:15:20"
	}
	
	SaveManager.cache_current_state(current_game_data, current_meta_data)
	SceneManager.goto_save_game(SceneManager.TransitionType.INSTANT)

func _on_btn_load_game_pressed():
	SceneManager.goto_load_game(SceneManager.TransitionType.INSTANT)

func _on_return_pressed():
	SceneManager.goto_main_menu()
