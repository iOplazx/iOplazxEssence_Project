extends Control

const ES_NAME_CLASS = "DemoSandboxSave"

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
		
	# 1. We ALWAYS assign a random color upon entry.
	if test_element:
		test_element.color = Color(randf(), randf(), randf())
		if lbl_output:
			lbl_output.text = "Scene ready.\nNew color generated: #" + test_element.color.to_html(false)
		EssenceLogger.system_info("[%s/_ready] Sandbox initialized with color: #%s" % [ES_NAME_CLASS, test_element.color.to_html(false)])

	# 2. We check if we are coming from the Load Game screen.
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
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		if is_instance_valid(EssenceError) and EssenceError.has_method("report"):
			EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)
		else:
			push_error(msg)

# ==========================================
# BUTTON CONFIGURATION
# ==========================================
func _configure_buttons() -> void:
	# Direct binding with visual error shielding handled upstream.
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
	
	# We force a wait frame BEFORE the capture to clear out visual artifacts.
	await get_tree().process_frame
	await SaveManager.take_temp_screenshot()
	
	# A small extra delay to finish writing the .webp file (I/O optimized)
	await get_tree().create_timer(0.1).timeout
	
	var current_game_data = {
		"box_color": test_element.color.to_html(false) if test_element else "ffffff",
		"player_hp": 100
	}
	
	var current_meta_data = {
		"title": "Save Test",
		"description": "Sandbox Scene - Level 1",
		"play_time": "99:15:20"
	}
	
	EssenceLogger.system_info("[%s/_prepare_menu_data] Caching state in SaveManager." % ES_NAME_CLASS)
	SaveManager.cache_current_state(current_game_data, current_meta_data)

func _restore_loaded_game() -> void:
	EssenceLogger.system_info("[%s/_restore_loaded_game] Restoring loaded data from SaveManager." % ES_NAME_CLASS)
	
	var saved_color_hex = SaveManager.loaded_game_data.get("box_color", "ffffff")
	var saved_hp = SaveManager.loaded_game_data.get("player_hp", 0)
	
	if not saved_color_hex.begins_with("#"):
		saved_color_hex = "#" + saved_color_hex
	
	if test_element:
		test_element.color = Color(saved_color_hex)
	
	if lbl_output:
		var info_text = "GAME LOADED!\n"
		info_text += "Restored color: " + saved_color_hex + "\n"
		info_text += "Player HP: " + str(saved_hp)
		lbl_output.text = info_text
	
	# Clear cache
	SaveManager.loaded_game_data.clear()

## Backup fallback method to prevent the game from freezing if the demo scene fails
func _fallback_to_main_menu() -> void:
	if has_node("/root/SceneManager") or is_instance_valid(SceneManager):
		SceneManager.goto_main_menu()
	else:
		push_error("[%s] SceneManager unavailable for fallback." % ES_NAME_CLASS)

# ==========================================
# EVENT HANDLERS
# ==========================================
func _on_btn_save_game_pressed() -> void:
	await _prepare_menu_data()
	SceneManager.goto_save_game(SceneManager.TransitionType.INSTANT)

func _on_btn_load_game_pressed() -> void:
	await _prepare_menu_data()
	SceneManager.goto_load_game(SceneManager.TransitionType.INSTANT)

func _on_return_pressed() -> void:
	EssenceLogger.system_info("[%s/_on_return] Processing save panel exit..." % ES_NAME_CLASS)
	
	# Specific game keys (declared in MyGameSave or project-level save schemas)
	var game_changes = {
		"habitacion_actual": GameIDs.RoomID.ROOM_1_DOOR,
		"fase_actual": TestMainGame.TestPhase.GAMEPLAY
	}
	
	# Call generic addon method to blend data in the background
	SaveManager.patch_cache_and_prepare_load(game_changes)
	
	# Change scenes using centralized constants
	var target_scene: String = DemoItemsRoute.TESTMAINGAME_SCENE
	if target_scene != "" and ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		push_error("[%s] Error: Main scene not found." % ES_NAME_CLASS)
		_fallback_to_main_menu()

func _on_no_implement_pressed() -> void:
	EssenceError.ExceptionNotImplement("Test")

func _on_print_warning_pressed() -> void:
	EssenceError.report("Hardware Check", "GPU running at high temperature.", EssenceError.Severity.WARNING)
	
