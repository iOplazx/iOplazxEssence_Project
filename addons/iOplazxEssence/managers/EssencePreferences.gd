extends Node

const SETTINGS_FILE = "user://essence_settings.cfg"
const DEFAULT_MOLD = "res://_static/default_settings.cfg"

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
		print("Essence: Primera vez ejecutando o archivo borrado. Creando desde molde...")
		_copy_mold_to_user()
	
	var err = _config.load(SETTINGS_FILE)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Essence: No se pudo cargar el archivo de preferencias.")
		
	_is_loaded = true 

func _copy_mold_to_user():
	# Verificamos que no se te haya olvidado crear el molde en el editor
	if not FileAccess.file_exists(DEFAULT_MOLD):
		push_warning("Essence: No se encontró el molde en " + DEFAULT_MOLD + ". El juego iniciará con valores en blanco.")
		return
		
	# copy_absolute es la forma más directa de cruzar entre res:// y user://
	var err = DirAccess.copy_absolute(DEFAULT_MOLD, SETTINGS_FILE)
	if err == OK:
		print("Essence: Archivo de configuración inicializado con éxito.")
	else:
		push_error("Essence: Error al copiar el molde inicial. Código: " + str(err))

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
	print("Essence: Todas las preferencias guardadas en disco.")
	
func load_from_disk():
	# "Destruimos" la configuración actual en RAM
	_config = ConfigFile.new()
	var err = _config.load(SETTINGS_FILE)
	
	if err == OK:
		print("Essence: Preferencias recargadas desde el disco (Cambios descartados).")
	elif err == ERR_FILE_NOT_FOUND:
		print("Essence: No hay archivo guardado aún. Se restauró la RAM a valores por defecto.")
	else:
		push_error("Essence: Error crítico al recargar preferencias. Código: " + str(err))
		
	_is_loaded = true

# ==========================================
# RESTAURAR DE FÁBRICA
# ==========================================
func restore_defaults():
	print("Essence: Restaurando valores de fábrica...")
	_copy_mold_to_user() # Planchamos el archivo del usuario con el molde
	load_from_disk()     # Refrescamos la RAM
	print("Essence: Valores por defecto aplicados exitosamente.")
