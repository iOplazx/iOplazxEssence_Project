extends Node
# Singleton: EssenceSceneManager (Autoload)
const ES_NAME_CLASS = "EssenceSceneManager"

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
		
		# Éxito: Lo mandamos al diario en silencio
		var log_msg = "[%s/_ready] RouteConfig loaded successfully." % ES_NAME_CLASS 
		_safe_log(log_msg)
	else:
		# Fallo Crítico: Si no hay rutas, el juego no puede navegar. Disparamos la pantalla roja.
		_safe_error(
			"Missing Route Config",
			"RouteConfig.tres could not be found in res://_static/",
			2
		)

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
	_safe_set_save_intent(false)
	if _verificar_config(): _navigate(_config.load_game_scene, transition)

func goto_save_game(transition: TransitionType = TransitionType.FADE_BLACK):
	_safe_set_save_intent(true)
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
			#push_error("iOplazxEssence: La ruta custom '" + route_name + "' no existe.")
			_safe_error(
				"Invalid Custom Route",
				"Attempted to navigate to a custom route that does not exist: %s" % route_name,
				1
			)
			
## Viaja a un nivel cargado y limpia el historial para evitar regresar al menú
func goto_loaded_game(scene_path: String, transition: TransitionType = TransitionType.FADE_BLACK):
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		#push_error("iOplazxEssence: No se pudo viajar. La escena cargada no existe: " + scene_path)
		_safe_error(
			"Invalid Scene Path",
			"Attempted to navigate to an invalid or empty scene path: %s" % scene_path,
			2
		)
		return
		
	var log_msg = "[%s/goto_loaded_game] Starting loaded game at -> %s" % [ES_NAME_CLASS, scene_path]
	_safe_log(log_msg)
	
	# Limpiamos el historial para que el botón "Atrás" empiece desde cero en este nivel
	_history.clear() 
	
	# Usamos tu método privado seguro
	_navigate(scene_path, transition)

# ==========================================
# MOTOR INTERNO DE NAVEGACIÓN Y ANIMACIÓN
# ==========================================

func _navigate(path: String, transition: TransitionType) -> void:
	if path == "" or not ResourceLoader.exists(path):
		#push_error("iOplazxEssence: Ruta inválida o vacía: " + str(path))
		_safe_error(
			"Invalid Scene Path",
			"Attempted to navigate to an invalid or empty scene path: %s" % path,
			2
		)
		return
		
	if _is_transitioning:
		var log_msg ="[%s/_navigate] Already transitioning. Ignoring navigation to -> %s" % [ES_NAME_CLASS, path]
		_safe_log(log_msg)
		return
		
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path:
		_history.append(current_scene_path)
		
	if transition == TransitionType.INSTANT:
		var log_msg = "[%s/_navigate] Traveling to -> %s" % [ES_NAME_CLASS, path]
		_safe_log(log_msg)
		get_tree().change_scene_to_file(path)
	else:
		_perform_fade_transition(path, transition)

func _perform_fade_transition(path: String, transition: TransitionType):
	_is_transitioning = true
	
	# Bloqueo absoluto de TO-DO el input (Mouse, Teclado, Mando)
	get_tree().root.set_disable_input(true)
	
	var target_color = Color.BLACK if transition == TransitionType.FADE_BLACK else Color.WHITE
	_curtain.color = target_color
	_curtain.color.a = 0.0
	
	# .set_pause_mode(...) asegura que la transición funcione aunque el juego esté pausado
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, "color:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	var log_msg = "[%s/_perform_fade_transition] Traveling to -> %s" % [ES_NAME_CLASS, path]
	_safe_log(log_msg)
	get_tree().change_scene_to_file(path)
	
	tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	#Restauramos el input al terminar
	get_tree().root.set_disable_input(false)
	_is_transitioning = false

func go_back(transition: TransitionType = TransitionType.FADE_BLACK) -> void:
	var log_msg = ""
	if _history.is_empty(): 
		log_msg = "[%s/go_back] History is empty, no scene to return to." % ES_NAME_CLASS
		_safe_log(log_msg)
		return
		
	if _is_transitioning: return
		
	var previous_scene = _history.pop_back()
	log_msg = "[%s/go_back] Returning to -> %s" % [ES_NAME_CLASS, previous_scene]
	_safe_log(log_msg)
	
	if transition == TransitionType.INSTANT:
		get_tree().change_scene_to_file(previous_scene)
	else:
		_perform_fade_transition(previous_scene, transition)

func clear_history() -> void:
	_history.clear()

func _verificar_config() -> bool:
	if _config == null:
		#push_error("iOplazxEssence: No se puede navegar porque RouteConfig.tres no está cargado.")
		_safe_error(
			"Route Config Missing",
			"Cannot navigate because RouteConfig.tres is not loaded.",
			2
		)
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
			_safe_log("[%s/request_quit] Initiating shutdown sequence..." % ES_NAME_CLASS)
			box.hide() 
			
			_is_transitioning = true
			get_tree().root.set_disable_input(true) 
			
			_curtain.color = Color.BLACK
			_curtain.color.a = 0.0
			
			# Animamos el telón negro y bajamos la música de forma segura
			var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(_curtain, "color:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
			
			_safe_audio_fade_out(1.5)
			
			# Esperamos 1.5s nativamente sin depender de otro Autoload
			await get_tree().create_timer(1.5).timeout
			
			_safe_log("SceneManager: Closing engine...")
			_safe_flush_logs()
			get_tree().quit()
	)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()

# ==============================================================================
# WRAPPERS DE SEGURIDAD (Desacoplamiento Total)
# ==============================================================================

func _safe_log(msg: String) -> void:
	var logger = get_tree().root.get_node_or_null("EssenceLogger")
	if is_instance_valid(logger) and logger.has_method("system_info"):
		logger.system_info(msg)
	else:
		print("Fallback Log: ", msg)

func _safe_error(title: String, msg: String, severity: int = 1) -> void:
	var err_handler = get_tree().root.get_node_or_null("EssenceError")
	if is_instance_valid(err_handler) and err_handler.has_method("report"):
		err_handler.report(title, msg, severity) 
	else:
		push_warning("Fallback Error [" + title + "]: " + msg)

func _safe_set_save_intent(is_save_mode: bool) -> void:
	var save_mgr = get_tree().root.get_node_or_null("SaveManager")
	if is_instance_valid(save_mgr) and "intent_is_save_mode" in save_mgr:
		save_mgr.intent_is_save_mode = is_save_mode

func _safe_audio_fade_out(duration: float) -> void:
	var audio_mgr = get_tree().root.get_node_or_null("AudioManager")
	if is_instance_valid(audio_mgr) and audio_mgr.has_method("fade_out_and_stop"):
		audio_mgr.fade_out_and_stop(duration)

func _safe_flush_logs() -> void:
	var logger = get_tree().root.get_node_or_null("EssenceLogger")
	if is_instance_valid(logger):
		if logger.has_method("flush_system_logs"): logger.flush_system_logs()
		if logger.has_method("flush_game_logs"): logger.flush_game_logs()