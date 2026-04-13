class_name EssenceTabVideo extends MarginContainer

const ES_NAME_CLASS = "EssenceTabVideo"

@export_category("Tab: Video")
@export_subgroup("Display Settings")
@export var dpd_mode: OptionButton
@export var btn_apply: Button 

# Variable to track the user's intent before committing changes
var _unsaved_mode: int = -1 

func _ready() -> void:
	if _validate_requirements():
		_setup_video_tab()
		_sync_video()
		_connect_signals()
		EssenceLogger.system_info("[%s] Video settings tab initialized." % ES_NAME_CLASS)

## Inspector and dependency validation
func _validate_requirements() -> bool:
	if dpd_mode == null or btn_apply == null:
		EssenceError.report(
			"Missing UI Reference",
			"Display dropdown or Apply button not assigned in %s." % name,
			EssenceError.Severity.CRITICAL
		)
		return false
		
	if not is_instance_valid(DisplayManager):
		EssenceError.report("Missing Autoload", "DisplayManager not found in SceneTree.", EssenceError.Severity.CRITICAL)
		return false
		
	return true

# ==========================================
# 1. CONNECTIONS
# ==========================================
func _connect_signals() -> void:
	if dpd_mode and not dpd_mode.item_selected.is_connected(_on_mode_changed):
		dpd_mode.item_selected.connect(_on_mode_changed)
		
	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)

# ==========================================
# 2. UI SETUP & TRANSLATION
# ==========================================
func _setup_video_tab() -> void:
	if dpd_mode:
		var current_selection = dpd_mode.selected 
		dpd_mode.clear() 
		# Option 0: Windowed, Option 1: Fullscreen
		dpd_mode.add_item(tr("SETTINGS_VIDEO_WINDOWED"), 0)
		dpd_mode.add_item(tr("SETTINGS_VIDEO_FULLSCREEN"), 1)
		
		if current_selection != -1:
			dpd_mode.select(current_selection)
		
	if btn_apply:
		btn_apply.text = tr("SETTINGS_VIDEO_SAVE_CHANGE")

# ==========================================
# 3. SYNCHRONIZATION
# ==========================================
func _sync_video() -> void:
	if dpd_mode and is_instance_valid(DisplayManager):
		dpd_mode.selected = DisplayManager.current_window_mode
		_unsaved_mode = dpd_mode.selected

# ==========================================
# REACTION TO GLOBAL EVENTS
# ==========================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_setup_video_tab()
		_sync_video()

# ==========================================
# USER SIGNALS
# ==========================================
func _on_mode_changed(index: int) -> void:
	_unsaved_mode = index
	AudioManager.play_ui_sfx()

func _on_apply_pressed() -> void:
	# Only execute heavy work if there's an actual change
	if _unsaved_mode != -1 and _unsaved_mode != DisplayManager.current_window_mode:
		DisplayManager.set_window_mode(_unsaved_mode)
		
		if is_instance_valid(Preferences):
			Preferences.set_setting("video", "window_mode", _unsaved_mode)
			Preferences.save_to_disk()
			EssenceLogger.system_info("[%s] Video changes applied and saved to disk. Mode: %d" % [ES_NAME_CLASS, _unsaved_mode])
		else:
			EssenceError.report("Preferences Error", "Could not save video settings: Preferences Autoload missing.", EssenceError.Severity.WARNING)
	
	AudioManager.play_ui_sfx()

## Tells the Global Controller if this tab has pending work
func has_unsaved_changes() -> bool:
	return _unsaved_mode != -1 and _unsaved_mode != DisplayManager.current_window_mode