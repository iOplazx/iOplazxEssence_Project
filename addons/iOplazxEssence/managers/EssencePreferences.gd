extends Node

const SETTINGS_FILE = "user://essence_settings.cfg"
var _config: ConfigFile = ConfigFile.new()
var _is_loaded: bool = false 

func _ready():
	_ensure_loaded()
# ==========================================
# CEREBRO CENTRAL (LAZY LOADING)
# ==========================================
func _ensure_loaded():
	if _is_loaded: return 
	
	var err = _config.load(SETTINGS_FILE)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Essence: No se pudo cargar el archivo de preferencias.")
		
	_is_loaded = true 

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
	
func load_from_disk():
	# 1. "Destruimos" la configuración actual en RAM creando una nueva limpia.
	# Esto borra cualquier cambio que el usuario haya hecho pero no haya guardado.
	_config = ConfigFile.new()
	
	# 2. Volvemos a leer el disco duro forzosamente
	var err = _config.load(SETTINGS_FILE)
	
	if err == OK:
		print("Essence: Preferencias recargadas desde el disco (Cambios descartados).")
	elif err == ERR_FILE_NOT_FOUND:
		print("Essence: No hay archivo guardado aún. Se restauró la RAM a valores por defecto.")
	else:
		push_error("Essence: Error crítico al recargar preferencias. Código: " + str(err))
		
	# 3. Volvemos a cerrar el candado de seguridad
	_is_loaded = true
