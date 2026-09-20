extends Node
# Autoload: EssenceSceneManager
const ES_NAME_CLASS = "EssenceSceneManager"

enum TransitionType { INSTANT, FADE_BLACK, FADE_WHITE }

var _history: Array[String] = []
var _config: EssenceRouteConfig

# Visual transition elements
var _curtain_layer: CanvasLayer
var _curtain: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
	# 1. Disable automatic window closing
	get_tree().set_auto_accept_quit(false)
	
	# 2. Setup visual curtain overlay for transitions
	_setup_curtain()
	
	# 3. Load route configuration
	var config_path: String = "res://_static/RouteConfig.tres"
	if ResourceLoader.exists(config_path):
		_config = load(config_path) as EssenceRouteConfig
		_safe_log("[%s/_ready] RouteConfig loaded successfully." % ES_NAME_CLASS)
	else:
		EssenceReportUtils.critical(
			"Missing Route Config",
			"RouteConfig.tres could not be found in res://_static/."
		)

func _setup_curtain() -> void:
	_curtain_layer = CanvasLayer.new()
	_curtain_layer.layer = 128 # Ultra-high layer to render above UI and menus
	
	_curtain = ColorRect.new()
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.color = Color(0, 0, 0, 0) # Transparent by default
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE # Pass clicks through
	
	_curtain_layer.add_child(_curtain)
	add_child(_curtain_layer)

# ==========================================
# DIRECT NAVIGATION METHODS (Base Routes)
# ==========================================

func goto_main_menu(transition: TransitionType = TransitionType.FADE_BLACK) -> void: 
	if _verify_config(): _navigate(_config.main_menu_scene, transition)

func goto_new_game(transition: TransitionType = TransitionType.FADE_BLACK) -> void: 
	if _verify_config():
		clear_history() 
		_navigate(_config.new_game_scene, transition)
		
func goto_continue_game(transition: TransitionType = TransitionType.FADE_BLACK) -> void: 
	if _verify_config(): _navigate(_config.continue_game_scene, transition)
		
func goto_load_game(transition: TransitionType = TransitionType.FADE_BLACK) -> void: 
	_safe_set_save_intent(false)
	if _verify_config(): _navigate(_config.load_game_scene, transition)

func goto_save_game(transition: TransitionType = TransitionType.FADE_BLACK) -> void:
	_safe_set_save_intent(true)
	if _verify_config(): _navigate(_config.load_game_scene, transition)

func goto_settings(transition: TransitionType = TransitionType.FADE_BLACK) -> void: 
	if _verify_config(): _navigate(_config.settings_scene, transition)

func goto_credits(transition: TransitionType = TransitionType.FADE_BLACK) -> void: 
	if _verify_config(): _navigate(_config.credits_scene, transition)

func goto_custom(route_name: String, transition: TransitionType = TransitionType.FADE_BLACK) -> void:
	if _verify_config():
		if _config.custom_routes.has(route_name):
			_navigate(_config.custom_routes[route_name], transition)
		else:
			EssenceReportUtils.warning(
				"Invalid Custom Route",
				"Attempted to navigate to a custom route that does not exist: %s" % route_name
			)
			
## Navigates to a loaded level scene and clears history to prevent returning to main menu.
func goto_loaded_game(scene_path: String, transition: TransitionType = TransitionType.FADE_BLACK) -> void:
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		EssenceReportUtils.critical(
			"Invalid Scene Path",
			"Attempted to navigate to an invalid or empty scene path: %s" % scene_path
		)
		return
		
	_safe_log("[%s/goto_loaded_game] Starting loaded game at -> %s" % [ES_NAME_CLASS, scene_path])
	
	_history.clear() 
	_navigate(scene_path, transition)

# ==========================================
# INTERNAL NAVIGATION & ANIMATION ENGINE
# ==========================================

func _navigate(path: String, transition: TransitionType) -> void:
	if path == "" or not ResourceLoader.exists(path):
		EssenceReportUtils.critical(
			"Invalid Scene Path",
			"Attempted to navigate to an invalid or empty scene path: %s" % path
		)
		return
		
	if _is_transitioning:
		_safe_log("[%s/_navigate] Already transitioning. Ignoring navigation to -> %s" % [ES_NAME_CLASS, path])
		return
		
	if get_tree().current_scene:
		var current_scene_path: String = get_tree().current_scene.scene_file_path
		if current_scene_path != "":
			_history.append(current_scene_path)
		
	if transition == TransitionType.INSTANT:
		_safe_log("[%s/_navigate] Traveling to -> %s" % [ES_NAME_CLASS, path])
		get_tree().change_scene_to_file(path)
	else:
		_perform_fade_transition(path, transition)

func _perform_fade_transition(path: String, transition: TransitionType) -> void:
	_is_transitioning = true
	
	# Block all user input (Mouse, Keyboard, Controller)
	get_tree().root.set_disable_input(true)
	
	var target_color: Color = Color.BLACK if transition == TransitionType.FADE_BLACK else Color.WHITE
	_curtain.color = target_color
	_curtain.color.a = 0.0
	
	var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, "color:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	_safe_log("[%s/_perform_fade_transition] Traveling to -> %s" % [ES_NAME_CLASS, path])
	get_tree().change_scene_to_file(path)
	
	tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	get_tree().root.set_disable_input(false)
	_is_transitioning = false

func go_back(transition: TransitionType = TransitionType.FADE_BLACK) -> void:
	if _history.is_empty(): 
		_safe_log("[%s/go_back] History is empty, no scene to return to." % ES_NAME_CLASS)
		return
		
	if _is_transitioning: return
		
	var previous_scene: String = _history.pop_back()
	_safe_log("[%s/go_back] Returning to -> %s" % [ES_NAME_CLASS, previous_scene])
	
	if transition == TransitionType.INSTANT:
		get_tree().change_scene_to_file(previous_scene)
	else:
		_perform_fade_transition(previous_scene, transition)

func clear_history() -> void:
	_history.clear()

func _verify_config() -> bool:
	if _config == null:
		EssenceReportUtils.critical(
			"Route Config Missing",
			"Cannot navigate because RouteConfig.tres is not loaded."
		)
		return false
	return true

# ==========================================
# APPLICATION SHUTDOWN MANAGEMENT
# ==========================================

func request_quit() -> void:
	if get_tree().root.has_node("EssenceConfirmBox") or _is_transitioning: 
		return
	
	var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box) 
	
	box.setup("APP_QUIT_TITLE", "APP_QUIT_MSG", "MENU_YES", "MENU_NO")
	
	box.on_choice.connect(func(accepted: bool):
		if accepted:
			_safe_log("[%s/request_quit] Initiating shutdown sequence..." % ES_NAME_CLASS)
			box.hide() 
			
			_is_transitioning = true
			get_tree().root.set_disable_input(true) 
			
			_curtain.color = Color.BLACK
			_curtain.color.a = 0.0
			
			var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(_curtain, "color:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
			
			_safe_audio_fade_out(1.5)
			
			await get_tree().create_timer(1.5).timeout
			
			_safe_log("SceneManager: Closing engine...")
			_safe_flush_logs()
			get_tree().quit()
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()

# ==============================================================================
# SAFETY WRAPPERS (Decoupled Helpers)
# ==============================================================================

func _safe_log(msg: String) -> void:
	var logger = get_tree().root.get_node_or_null("EssenceLogger")
	if is_instance_valid(logger) and logger.has_method("system_info"):
		logger.system_info(msg)
	else:
		print("Fallback Log: ", msg)

## Safely forwards reporting calls to EssenceReportUtils without direct Autoload or scene tree coupling.
func _safe_error(title: String, msg: String, severity: Variant = "WARNING") -> void:
	EssenceReportUtils.report(title, msg, severity)

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
