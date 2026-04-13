class_name EssenceSettingsController extends Control

const ES_NAME_CLASS = "EssenceSettingsController"

@export_category("Global Connections")
@export var btn_return: Button
@export var btn_restore: Button 
@export var tab_container: TabContainer 

const PATH = EssencePaths.PATH_UI_SCREEN + "settings/"

# Lazy Loading Mold
var tab_scenes: Dictionary = {
	0: preload(PATH + "EssenceTabGame.tscn"),
	1: preload(PATH + "EssenceTabSave.tscn"),
	2: preload(PATH + "EssenceTabVideo.tscn"),
	3: preload(PATH + "EssenceTabAudio.tscn"),
	4: preload(PATH + "EssenceTabLanguage.tscn"),
}

func _ready() -> void:
	if _validate_requirements():
		_connect_signals()
		
		# Load the first visible tab immediately
		if tab_container:
			_load_tab(tab_container.current_tab)
		
		EssenceLogger.system_info("[%s] Settings controller initialized with Lazy Loading." % ES_NAME_CLASS)

## Inspector validation
func _validate_requirements() -> bool:
	if tab_container == null:
		EssenceError.report("Missing TabContainer", "Settings UI requires a TabContainer to function.", EssenceError.Severity.CRITICAL)
		return false
	
	if btn_return == null or btn_restore == null:
		EssenceError.report("Missing Buttons", "Return or Restore buttons not assigned in %s." % name, EssenceError.Severity.WARNING)
	
	return true

func _connect_signals() -> void:
	if is_instance_valid(btn_return):
		btn_return.pressed.connect(_on_return_pressed)
		
	if is_instance_valid(btn_restore): 
		btn_restore.pressed.connect(_on_restore_pressed)
		
	if is_instance_valid(tab_container):
		tab_container.tab_changed.connect(_on_tab_changed)

# ==========================================
# LAZY LOADING SYSTEM
# ==========================================

func _on_tab_changed(tab_index: int) -> void:
	_load_tab(tab_index)
	AudioManager.play_ui_sfx()

func _load_tab(index: int) -> void:
	if not is_instance_valid(tab_container) or not tab_scenes.has(index):
		return
		
	var placeholder = tab_container.get_child(index)
	
	# If placeholder already has the content, skip
	if placeholder.get_child_count() > 0:
		return
		
	# Instance the heavy scene on the fly
	var scene_res = tab_scenes[index]
	if scene_res:
		var tab_content = scene_res.instantiate()
		tab_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		placeholder.add_child(tab_content)
		
		EssenceLogger.system_info("[%s] Section loaded into memory: Tab %d" % [ES_NAME_CLASS, index])
	else:
		EssenceError.report("Load Error", "Could not load scene for tab index: %d" % index, EssenceError.Severity.WARNING)

# ==========================================
# GLOBAL ACTIONS
# ==========================================

func _on_restore_pressed() -> void:
	AudioManager.play_ui_sfx()
	
	_show_confirm_box(
		"SETTINGS_RESTORE_TITLE", 
		"SETTINGS_RESTORE_MSG",
		func():
			EssenceLogger.system_info("[%s] Applying factory defaults..." % ES_NAME_CLASS)
			Preferences.restore_defaults()
			
			# Notify all nodes to refresh their values and translations
			get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
			
			# Reset dirty flags in all loaded tabs
			for tab in get_tree().get_nodes_in_group("settings_tabs"):
				if "_pending_changes" in tab: tab._pending_changes = false
				if "_unsaved_mode" in tab: tab._unsaved_mode = DisplayManager.current_window_mode
	)

func _on_return_pressed() -> void:
	AudioManager.play_ui_sfx()
	
	# Check for unsaved changes across all active (instantiated) tabs
	var tabs = get_tree().get_nodes_in_group("settings_tabs")
	var changes_detected = false
	
	for tab in tabs:
		if tab.has_method("has_unsaved_changes"):
			if tab.has_unsaved_changes():
				changes_detected = true
				break
	
	if changes_detected:
		_show_confirm_box(
			"SETTINGS_DISCARD_TITLE", 
			"SETTINGS_DISCARD_MSG",
			func():
				# Reload original preferences from disk to discard RAM changes
				if Preferences.has_method("load_from_disk"):
					Preferences.load_from_disk()
				SceneManager.go_back()
		)
	else:
		SceneManager.go_back()

# ==========================================
# PRIVATE HELPERS
# ==========================================

func _show_confirm_box(title_key: String, msg_key: String, on_accept: Callable) -> void:
	if get_tree().root.has_node("EssenceConfirmBox"): return
	
	var box_path = EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn"
	if not ResourceLoader.exists(box_path):
		EssenceError.report("Resource Error", "ConfirmBox not found at: %s" % box_path, EssenceError.Severity.CRITICAL)
		return
		
	var box = load(box_path).instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box)
	
	box.setup(title_key, msg_key, "MENU_YES", "MENU_NO")
	box.on_choice.connect(func(accepted): if accepted: on_accept.call())
