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

func _ready() -> void:
	_check_security_nodes()
	_configure_buttons()
	
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig
		
	# 1. ALWAYS assign a random color upon entry
	if test_element:
		test_element.color = Color(randf(), randf(), randf())
		if lbl_output:
			lbl_output.text = "Scene ready.\nNew color generated: #" + test_element.color.to_html(false)
		EssenceLogger.system_info("[%s/_ready] Sandbox initialized with color: #%s" % [ES_NAME_CLASS, test_element.color.to_html(false)])

	# 2. Check if returning from Load Game screen
	if is_instance_valid(SaveManager) and not SaveManager.loaded_game_data.is_empty():
		_restore_loaded_game()

# ==========================================
# SECURITY ARMORING
# ==========================================
func _check_security_nodes() -> void:
	var missing: Array[String] = []
	if not btn_save: missing.append("btn_save")
	if not btn_load: missing.append("btn_load")
	if not btn_return: missing.append("btn_return")
	if not lbl_output: missing.append("lbl_output")
	if not test_element: missing.append("test_element")
	if not btn_no_implement: missing.append("btn_no_implement")
	if not btn_warning: missing.append("btn_warning")
	
	if missing.size() > 0:
		var msg: String = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		EssenceReportUtils.warning("UI Setup Warning", msg)

# ==========================================
# BUTTON CONFIGURATION
# ==========================================
func _configure_buttons() -> void:
	if btn_save: btn_save.pressed.connect(func(): _play_sfx(); _on_btn_save_game_pressed())
	if btn_load: btn_load.pressed.connect(func(): _play_sfx(); _on_btn_load_game_pressed())
	if btn_return: btn_return.pressed.connect(func(): _play_sfx(); _on_return_pressed())
	if btn_no_implement: btn_no_implement.pressed.connect(func(): _play_sfx(); _on_no_implement_pressed())
	if btn_warning: btn_warning.pressed.connect(func(): _play_sfx(); _on_print_warning_pressed())

func _play_sfx() -> void:
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()

# ==========================================
# SAVE / LOAD LOGIC
# ==========================================
func _prepare_menu_data() -> void:
	if lbl_output: 
		lbl_output.text = "Capturing screen..."
	EssenceLogger.system_info("[%s/_prepare_menu_data] Taking temporary screenshot..." % ES_NAME_CLASS)
	
	# Force a wait frame BEFORE capture to clear visual artifacts
	await get_tree().process_frame
	if is_instance_valid(SaveManager) and SaveManager.has_method("take_temp_screenshot"):
		await SaveManager.take_temp_screenshot()
	
	# Extra delay for I/O file writing
	await get_tree().create_timer(0.1).timeout
	
	var current_playtime: float = EssenceTimeUtils.get_playtime_seconds()
	
	# Basic game data for sandbox testing
	var current_game_data: Dictionary = {
		"box_color": test_element.color.to_html(false) if test_element else "ffffff",
		"player_hp": 100,
		GameSaveKeys.PLAYTIME_SECONDS: current_playtime
	}
	
	# Metadata using framework standard keys
	var current_meta_data: Dictionary = {
		"title": "Save Test",
		"description": "Sandbox Scene - Level 1",
		GameSaveKeys.META_PLAYTIME: EssenceTimeUtils.format_seconds(current_playtime)
	}
	
	EssenceLogger.system_info("[%s/_prepare_menu_data] Caching state in SaveManager." % ES_NAME_CLASS)
	if is_instance_valid(SaveManager) and SaveManager.has_method("cache_current_state"):
		SaveManager.cache_current_state(current_game_data, current_meta_data)


func _restore_loaded_game() -> void:
	EssenceLogger.system_info("[%s/_restore_loaded_game] Restoring loaded data from SaveManager." % ES_NAME_CLASS)
	
	var saved_color_hex: String = SaveManager.loaded_game_data.get("box_color", "ffffff")
	var saved_hp: int = int(SaveManager.loaded_game_data.get("player_hp", 0))
	var restored_seconds: float = float(SaveManager.loaded_game_data.get(GameSaveKeys.PLAYTIME_SECONDS, 0.0))
	
	# Restore clock time if TimeManager is present
	var main_loop: SceneTree = Engine.get_main_loop() as SceneTree
	if is_instance_valid(main_loop) and main_loop.root.has_node("TimeManager"):
		var tm: Node = main_loop.root.get_node("TimeManager")
		if tm.has_method("set_playtime"):
			tm.set_playtime(restored_seconds)
			tm.start_clock()
	
	if not saved_color_hex.begins_with("#"):
		saved_color_hex = "#" + saved_color_hex
	
	if test_element:
		test_element.color = Color(saved_color_hex)
	
	if lbl_output:
		var info_text: String = "GAME LOADED!\n"
		info_text += "Restored color: " + saved_color_hex + "\n"
		info_text += "Player HP: " + str(saved_hp) + "\n"
		info_text += "Playtime: " + EssenceTimeUtils.format_seconds(restored_seconds)
		lbl_output.text = info_text
	
	# Clear cache
	SaveManager.loaded_game_data.clear()

## Fallback method to prevent freeze if SceneManager fails
func _fallback_to_main_menu() -> void:
	if is_instance_valid(SceneManager) and SceneManager.has_method("goto_main_menu"):
		SceneManager.goto_main_menu()
	else:
		EssenceReportUtils.critical("Fallback Error", "SceneManager unavailable for fallback.")

# ==========================================
# EVENT HANDLERS
# ==========================================
func _on_btn_save_game_pressed() -> void:
	await _prepare_menu_data()
	if is_instance_valid(SceneManager) and SceneManager.has_method("goto_save_game"):
		SceneManager.goto_save_game(SceneManager.TransitionType.INSTANT)

func _on_btn_load_game_pressed() -> void:
	await _prepare_menu_data()
	if is_instance_valid(SceneManager) and SceneManager.has_method("goto_load_game"):
		SceneManager.goto_load_game(SceneManager.TransitionType.INSTANT)

func _on_return_pressed() -> void:
	EssenceLogger.system_info("[%s/_on_return] Returning to main menu..." % ES_NAME_CLASS)
	if is_instance_valid(SceneManager) and SceneManager.has_method("goto_main_menu"):
		SceneManager.goto_main_menu()
	else:
		_fallback_to_main_menu()

func _on_no_implement_pressed() -> void:
	if is_instance_valid(EssenceError) and EssenceError.has_method("ExceptionNotImplement"):
		EssenceError.ExceptionNotImplement("Test")

func _on_print_warning_pressed() -> void:
	EssenceReportUtils.warning("Hardware Check", "GPU running at high temperature.")
