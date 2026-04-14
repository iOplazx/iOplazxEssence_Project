extends Node
const ES_NAME_CLASS = "EssencePreferences"

const SETTINGS_FILE = "user://essence_settings.cfg"
const DEFAULT_MOLD = "res://_static/default_settings.cfg"
signal settings_restored

var _config: ConfigFile = ConfigFile.new()
var _is_loaded: bool = false 

func _ready():
	_ensure_loaded()

# ==========================================
# CEREBRO CENTRAL (LAZY LOADING)
# ==========================================
func _ensure_loaded() -> void:
	if _is_loaded: return 
	
	if not FileAccess.file_exists(SETTINGS_FILE):
		var log_msg = "[%s/_ensure_loaded] First run or settings file missing. Initializing from mold..." % ES_NAME_CLASS
		_safe_log(log_msg)
		_copy_mold_to_user()
	
	var err = _config.load(SETTINGS_FILE)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		_safe_error(
			"Failed to Load Preferences",
			"An error occurred while loading the preferences file. Code: %s" % err,
			2 # 2 = CRITICAL
		)
		
	_is_loaded = true 

func _copy_mold_to_user() -> void:
	if not FileAccess.file_exists(DEFAULT_MOLD):
		_safe_error(
			"Mold File Missing",
			"The default mold file was not found at %s. The game will start with blank settings." % DEFAULT_MOLD,
			1 # 1 = WARNING
		)
		return
		
	var err = DirAccess.copy_absolute(DEFAULT_MOLD, SETTINGS_FILE)
	if err == OK:
		var log_msg = "[%s/_copy_mold_to_user] Successfully initialized user settings from mold." % ES_NAME_CLASS
		_safe_log(log_msg)
	else:
		_safe_error(
			"Failed to Initialize Preferences",
			"An error occurred while copying the mold file to initialize preferences. Code: %s" % err,
			2 # 2 = CRITICAL
		)

# ==========================================
# INTERFAZ PARA LOS DEMÁS MÓDULOS
# ==========================================
func get_setting(section: String, key: String, default_value: Variant) -> Variant:
	_ensure_loaded()
	return _config.get_value(section, key, default_value)

func set_setting(section: String, key: String, value: Variant):
	_ensure_loaded()
	_config.set_value(section, key, value)

func save_to_disk() -> void:
	_ensure_loaded()
	_config.save(SETTINGS_FILE)
	var log_msg = "[%s/save_to_disk] All preferences saved to disk." % ES_NAME_CLASS
	_safe_log(log_msg)

func load_from_disk() -> void:
	_config = ConfigFile.new()
	var err = _config.load(SETTINGS_FILE)
	
	var log_msg = ""
	if err == OK:
		log_msg = "[%s/load_from_disk] Preferences reloaded from disk (Changes discarded)." % ES_NAME_CLASS
		_safe_log(log_msg)
	elif err == ERR_FILE_NOT_FOUND:
		log_msg = "[%s/load_from_disk] No saved file found. RAM restored to default values." % ES_NAME_CLASS
		_safe_log(log_msg)
	else:
		_safe_error(
			"Failed to Reload Preferences",
			"An error occurred while reloading preferences from disk. Code: %s" % err,
			2 # 2 = CRITICAL
		)
		
	_is_loaded = true

# ==========================================
# RESTAURAR DE FÁBRICA
# ==========================================
func restore_defaults() -> void:
	var log_msg ="[%s/restore_defaults] Restoring default settings..." % ES_NAME_CLASS
	_safe_log(log_msg)
	
	_copy_mold_to_user() 
	load_from_disk()     
	
	log_msg = "[%s/restore_defaults] Default values applied successfully." % ES_NAME_CLASS
	_safe_log(log_msg)

	settings_restored.emit()

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