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
	
	lbl_output.text = "Escena de prueba lista.\nEsperando acción..."
	
	if test_element:
		test_element.color = Color(randf(), randf(), randf())
		
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig
	
	# Si hay datos de carga pendientes en el Manager, los aplicamos
	if not SaveManager.loaded_game_data.is_empty():
		var saved_color = SaveManager.loaded_game_data.get("box_color", "ffffff")
		test_element.color = Color(saved_color)
		lbl_output.text = "¡Partida cargada exitosamente!"
		
		# Limpiamos el caché para no volver a cargarlo si entramos otra vez
		SaveManager.loaded_game_data.clear()

func _on_btn_save_game_pressed():
	lbl_output.text = "Tomando captura y preparando datos..."
	
	# 1. Tomamos la foto temporal (usamos await porque espera el renderizado)
	await SaveManager.take_temp_screenshot()
	
	# 2. Empaquetamos los datos del "juego"
	var current_game_data = {
		"box_color": test_element.color.to_html() if test_element else "ffffff",
		"player_hp": 100 # Ejemplo extra
	}
	
	# 3. Empaquetamos los datos visuales para la lista de UI
	var current_meta_data = {
		"title": "Prueba de Guardado",
		"description": "Escena Sandbox - Nivel 1",
		"play_time": "00:15:20"
	}
	
	# 4. Guardamos en el bolsillo del Autoload y viajamos
	SaveManager.cache_current_state(current_game_data, current_meta_data)
	SceneManager.goto_save_game(SceneManager.TransitionType.INSTANT)

func _on_btn_load_game_pressed():
	# Para cargar no necesitamos empacar datos, solo ir a la UI
	SceneManager.goto_load_game(SceneManager.TransitionType.INSTANT)

func _on_return_pressed():
	SceneManager.goto_main_menu()
