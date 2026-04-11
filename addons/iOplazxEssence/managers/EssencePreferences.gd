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
func _ensure_loaded():
	if _is_loaded: return 
	
	# Magia nueva: Si no existe el archivo del jugador, le inyectamos el molde
	if not FileAccess.file_exists(SETTINGS_FILE):
		#print("Essence: Primera vez ejecutando o archivo borrado. Creando desde molde...")
		var log_msg = "[%s/_ensure_loaded] First run or settings file missing. Initializing from mold..." % ES_NAME_CLASS
		EssenceLogger.system_info(log_msg)
		_copy_mold_to_user()
	
	var err = _config.load(SETTINGS_FILE)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		#push_error("Essence: No se pudo cargar el archivo de preferencias.")
		EssenceError.report(
			"Failed to Load Preferences",
			"An error occurred while loading the preferences file. Code: %s" % err,
			EssenceError.Severity.CRITICAL
		)
		
	_is_loaded = true 

func _copy_mold_to_user():
	# Verificamos que no se te haya olvidado crear el molde en el editor
	if not FileAccess.file_exists(DEFAULT_MOLD):
		#push_warning("Essence: No se encontró el molde en " + DEFAULT_MOLD + ". El juego iniciará con valores en blanco.")
		EssenceError.report(
			"Mold File Missing",
			"The default mold file was not found at %s. The game will start with blank settings." % DEFAULT_MOLD,
			EssenceError.Severity.WARNING
		)
		return
		
	# copy_absolute es la forma más directa de cruzar entre res:// y user://
	var err = DirAccess.copy_absolute(DEFAULT_MOLD, SETTINGS_FILE)
	if err == OK:
		#print("Essence: Archivo de configuración inicializado con éxito.")
		var log_msg = "[%s/_copy_mold_to_user] Successfully initialized user settings from mold." % ES_NAME_CLASS
		EssenceLogger.system_info(log_msg)
	else:
		#push_error("Essence: Error al copiar el molde inicial. Código: " + str(err))
		EssenceError.report(
			"Failed to Initialize Preferences",
			"An error occurred while copying the mold file to initialize preferences. Code: %s" % err,
			EssenceError.Severity.CRITICAL
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

func save_to_disk():
	_ensure_loaded()
	_config.save(SETTINGS_FILE)
	#print("Essence: Todas las preferencias guardadas en disco.")
	var log_msg = "[%s/save_to_disk] All preferences saved to disk." % ES_NAME_CLASS
	EssenceLogger.system_info(log_msg)

func load_from_disk():
	# "Destruimos" la configuración actual en RAM
	_config = ConfigFile.new()
	var err = _config.load(SETTINGS_FILE)
	
	var log_msg = ""
	if err == OK:
		#print("Essence: Preferencias recargadas desde el disco (Cambios descartados).")
		log_msg = "[%s/load_from_disk] Preferences reloaded from disk (Changes discarded)." % ES_NAME_CLASS
		EssenceLogger.system_info(log_msg)
	elif err == ERR_FILE_NOT_FOUND:
		#print("Essence: No hay archivo guardado aún. Se restauró la RAM a valores por defecto.")
		log_msg = "[%s/load_from_disk] No saved file found. RAM restored to default values." % ES_NAME_CLASS
		EssenceLogger.system_info(log_msg)
	else:
		#push_error("Essence: Error crítico al recargar preferencias. Código: " + str(err))
		EssenceError.report(
			"Failed to Reload Preferences",
			"An error occurred while reloading preferences from disk. Code: %s" % err,
			EssenceError.Severity.CRITICAL
		)
		
	_is_loaded = true

# ==========================================
# RESTAURAR DE FÁBRICA
# ==========================================
func restore_defaults():
	var log_msg ="[%s/restore_defaults] Restoring default settings..." % ES_NAME_CLASS
	EssenceLogger.system_info(log_msg)
	#print("Essence: Restaurando valores de fábrica...")
	_copy_mold_to_user() # Planchamos el archivo del usuario con el molde
	load_from_disk()     # Refrescamos la RAM
	#print("Essence: Valores por defecto aplicados exitosamente.")
	log_msg = "[%s/restore_defaults] Default values applied successfully." % ES_NAME_CLASS
	EssenceLogger.system_info(log_msg)

	settings_restored.emit() # Avisamos a todos los managers
