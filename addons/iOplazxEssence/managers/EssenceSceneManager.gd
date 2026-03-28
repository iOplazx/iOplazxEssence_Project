extends Node
# Singleton: EssenceSceneManager (Autoload)

var _history: Array[String] = []
var _config: EssenceRouteConfig

func _ready():
	# 1. Desactivamos el cierre automático de la ventana (para atrapar la "X")
	get_tree().set_auto_accept_quit(false)
	
	# El framework busca automáticamente la configuración del usuario en _static/
	var config_path = "res://_static/RouteConfig.tres"
	if ResourceLoader.exists(config_path):
		_config = load(config_path) as EssenceRouteConfig
		print("iOplazxEssence: RouteConfig cargado exitosamente.")
	else:
		# Aviso en rojo en la consola si el archivo no existe
		push_error("iOplazxEssence: Falta el archivo RouteConfig.tres en res://_static/")

# ==========================================
# MÉTODOS DE VIAJE DIRECTO (Rutas Base)
# ==========================================

func goto_main_menu(): 
	if _verificar_config(): _navigate(_config.main_menu_scene)

func goto_new_game(): 
	if _verificar_config():
		clear_history() 
		_navigate(_config.new_game_scene)
func goto_continue_game(): 
	if _verificar_config(): _navigate(_config.continue_game_scene)
		
func goto_load_game(): 
	if _verificar_config(): _navigate(_config.load_game_scene)

func goto_settings(): 
	if _verificar_config(): _navigate(_config.settings_scene)

func goto_credits(): 
	if _verificar_config(): _navigate(_config.credits_scene)

# ==========================================
# MÉTODOS DE VIAJE CUSTOM (Rutas del Usuario)
# ==========================================

func goto_custom(route_name: String):
	if _verificar_config():
		if _config.custom_routes.has(route_name):
			_navigate(_config.custom_routes[route_name])
		else:
			push_error("iOplazxEssence: La ruta custom '" + route_name + "' no existe en RouteConfig.tres")

# ==========================================
# MOTOR INTERNO DE NAVEGACIÓN
# ==========================================

func _navigate(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		push_error("iOplazxEssence: Ruta inválida o vacía: " + str(path))
		return
		
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path:
		_history.append(current_scene_path)
		
	print("Viajando a -> ", path)
	get_tree().change_scene_to_file(path)

func go_back() -> void:
	if _history.is_empty(): 
		print("Historial vacío, no hay a dónde volver.")
		return
	var previous_scene = _history.pop_back()
	print("Regresando a -> ", previous_scene)
	get_tree().change_scene_to_file(previous_scene)

func clear_history() -> void:
	_history.clear()

# Función auxiliar de seguridad
func _verificar_config() -> bool:
	if _config == null:
		push_error("iOplazxEssence: No se puede navegar porque RouteConfig.tres no está cargado.")
		return false
	return true

# ==========================================
# GESTIÓN DE SALIDA DEL JUEGO
# ==========================================

func request_quit():
	# Evitamos abrir la caja 2 veces si el usuario hace spam de clics
	if get_tree().root.has_node("EssenceConfirmBox"): 
		return
	
	# Instanciamos la caja genérica usando tu ruta de Constants
	var box = load(EssencePaths.PATH_UI + "EssenceConfirmBox.tscn").instantiate()
	box.name = "EssenceConfirmBox"
	
	# Lo añadimos al 'root' para que esté por encima de todo
	get_tree().root.add_child(box) 
	
	# Configuramos los textos
	box.setup("APP_QUIT_TITLE", "APP_QUIT_MSG", "MENU_YES", "MENU_NO")
	
	# Escuchamos la decisión del jugador
	box.on_choice.connect(func(accepted):
		if accepted:
			print("iOplazxEssence: Cerrando el motor...")
			get_tree().quit()
	)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()
