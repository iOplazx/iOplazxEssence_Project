extends Node
# Singleton: EssenceSceneManager (Autoload)

enum TransitionType { INSTANT, FADE_BLACK, FADE_WHITE }

var _history: Array[String] = []
var _config: EssenceRouteConfig

# Elementos visuales para la transición
var _curtain_layer: CanvasLayer
var _curtain: ColorRect
var _is_transitioning: bool = false

func _ready():
	# 1. Desactivamos el cierre automático de la ventana
	get_tree().set_auto_accept_quit(false)
	
	# 2. Creamos el "Telón" visual para las transiciones
	_setup_curtain()
	
	# 3. Cargamos la configuración de rutas
	var config_path = "res://_static/RouteConfig.tres"
	if ResourceLoader.exists(config_path):
		_config = load(config_path) as EssenceRouteConfig
		print("iOplazxEssence: RouteConfig cargado exitosamente.")
	else:
		push_error("iOplazxEssence: Falta el archivo RouteConfig.tres en res://_static/")

func _setup_curtain():
	_curtain_layer = CanvasLayer.new()
	_curtain_layer.layer = 128 # Capa súper alta para tapar menús y UI
	
	_curtain = ColorRect.new()
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.color = Color(0, 0, 0, 0) # Totalmente transparente al inicio
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE # Deja pasar los clics
	
	_curtain_layer.add_child(_curtain)
	add_child(_curtain_layer)

# ==========================================
# MÉTODOS DE VIAJE DIRECTO (Rutas Base)
# ==========================================
# Todos tienen FADE_BLACK por defecto, pero puedes pasarle INSTANT si quieres un salto brusco

func goto_main_menu(transition: TransitionType = TransitionType.FADE_BLACK): 
	if _verificar_config(): _navigate(_config.main_menu_scene, transition)

func goto_new_game(transition: TransitionType = TransitionType.FADE_BLACK): 
	if _verificar_config():
		clear_history() 
		_navigate(_config.new_game_scene, transition)
		
func goto_continue_game(transition: TransitionType = TransitionType.FADE_BLACK): 
	if _verificar_config(): _navigate(_config.continue_game_scene, transition)
		
func goto_load_game(transition: TransitionType = TransitionType.FADE_BLACK): 
	if _verificar_config(): _navigate(_config.load_game_scene, transition)

func goto_settings(transition: TransitionType = TransitionType.FADE_BLACK): 
	if _verificar_config(): _navigate(_config.settings_scene, transition)

func goto_credits(transition: TransitionType = TransitionType.FADE_BLACK): 
	if _verificar_config(): _navigate(_config.credits_scene, transition)

func goto_custom(route_name: String, transition: TransitionType = TransitionType.FADE_BLACK):
	if _verificar_config():
		if _config.custom_routes.has(route_name):
			_navigate(_config.custom_routes[route_name], transition)
		else:
			push_error("iOplazxEssence: La ruta custom '" + route_name + "' no existe.")

# ==========================================
# MOTOR INTERNO DE NAVEGACIÓN Y ANIMACIÓN
# ==========================================

func _navigate(path: String, transition: TransitionType) -> void:
	if path == "" or not ResourceLoader.exists(path):
		push_error("iOplazxEssence: Ruta inválida o vacía: " + str(path))
		return
		
	if _is_transitioning:
		print("iOplazxEssence: Ya hay una transición en curso. Ignorando...")
		return
		
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path:
		_history.append(current_scene_path)
		
	if transition == TransitionType.INSTANT:
		print("Viajando a -> ", path)
		get_tree().change_scene_to_file(path)
	else:
		_perform_fade_transition(path, transition)

func _perform_fade_transition(path: String, transition: TransitionType):
	_is_transitioning = true
	
	# NUEVO: Bloqueo absoluto de TODO el input (Mouse, Teclado, Mando)
	get_tree().root.set_disable_input(true)
	
	var target_color = Color.BLACK if transition == TransitionType.FADE_BLACK else Color.WHITE
	_curtain.color = target_color
	_curtain.color.a = 0.0
	
	# NUEVO: .set_pause_mode(...) asegura que la transición funcione aunque el juego esté pausado
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, "color:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	print("Viajando a -> ", path)
	get_tree().change_scene_to_file(path)
	
	tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	# NUEVO: Restauramos el input al terminar
	get_tree().root.set_disable_input(false)
	_is_transitioning = false

func go_back(transition: TransitionType = TransitionType.FADE_BLACK) -> void:
	if _history.is_empty(): 
		print("Historial vacío, no hay a dónde volver.")
		return
		
	if _is_transitioning: return
		
	var previous_scene = _history.pop_back()
	print("Regresando a -> ", previous_scene)
	
	if transition == TransitionType.INSTANT:
		get_tree().change_scene_to_file(previous_scene)
	else:
		_perform_fade_transition(previous_scene, transition)

func clear_history() -> void:
	_history.clear()

func _verificar_config() -> bool:
	if _config == null:
		push_error("iOplazxEssence: No se puede navegar porque RouteConfig.tres no está cargado.")
		return false
	return true

# ==========================================
# GESTIÓN DE SALIDA DEL JUEGO
# ==========================================

func request_quit():
	if get_tree().root.has_node("EssenceConfirmBox") or _is_transitioning: 
		return
	
	var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box) 
	
	box.setup("APP_QUIT_TITLE", "APP_QUIT_MSG", "MENU_YES", "MENU_NO")
	
	box.on_choice.connect(func(accepted):
		if accepted:
			print("iOplazxEssence: Iniciando secuencia de cierre total...")
			box.hide() 
			
			_is_transitioning = true
			
			# NUEVO: Apagamos controles para que no puedan interactuar mientras se cierra
			get_tree().root.set_disable_input(true) 
			
			_curtain.color = Color.BLACK
			_curtain.color.a = 0.0
			
			# NUEVO: Tween blindado contra la pausa
			var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(_curtain, "color:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
			
			await AudioManager.fade_out_and_stop(1.5)
			
			print("iOplazxEssence: Cerrando el motor...")
			get_tree().quit()
	)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()
