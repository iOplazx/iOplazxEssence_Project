extends Node

const SETTINGS_FILE = "user://essence_settings.cfg"
var _config: ConfigFile = ConfigFile.new()
var _is_loaded: bool = false # Nuestro candado de seguridad

func _ready():
	_ensure_loaded()
# ==========================================
# CEREBRO CENTRAL (LAZY LOADING)
# ==========================================
func _ensure_loaded():
	if _is_loaded: return # Si ya lo leímos, no hacemos nada (Cero coste de CPU)
	
	var err = _config.load(SETTINGS_FILE)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Essence: No se pudo cargar el archivo de preferencias.")
		
	_is_loaded = true # Cerramos el candado

# ==========================================
# INTERFAZ PARA LOS DEMÁS MÓDULOS
# ==========================================
func get_setting(section: String, key: String, default_value: Variant) -> Variant:
	_ensure_loaded() # Verificamos antes de entregar datos
	return _config.get_value(section, key, default_value)

func set_setting(section: String, key: String, value: Variant):
	_ensure_loaded() # Verificamos antes de escribir en RAM
	_config.set_value(section, key, value)

func save_to_disk():
	_ensure_loaded()
	_config.save(SETTINGS_FILE)
	print("Essence: Todas las preferencias guardadas en disco.")
