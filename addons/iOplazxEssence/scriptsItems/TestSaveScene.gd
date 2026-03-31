extends Control

@export var btn_save: Button
@export var btn_load: Button
@export var btn_return: Button
@export var lbl_output: Label
@export var test_element: ColorRect

const ROUTES_PATH = "res://_static/RouteConfig.tres"
var routes: EssenceRouteConfig

# Usaremos un slot fijo para esta prueba
var _test_slot_id: String = "save_1_1"

func _ready():
	btn_save.pressed.connect(_on_btn_save_game_pressed)
	btn_load.pressed.connect(_on_btn_load_game_pressed)
	btn_return.pressed.connect(_on_return_pressed)
	
	lbl_output.text = "Escena de prueba lista.\nEsperando acción..."
	
	# Cambiamos el color del cuadro al iniciar para la prueba visual
	if test_element:
		test_element.color = Color(randf(), randf(), randf())
		
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig

func _on_btn_save_game_pressed():
	SceneManager.goto_save_game()

func _on_btn_load_game_pressed():
	SceneManager.goto_load_game()

func _on_return_pressed():
	# Esto te devolverá al Main Menu de forma segura
	SceneManager.goto_main_menu()
