extends Node

# Diccionario maestro para evitar duplicados. 
# Estructura: {"en": {"name": "English", "author": "...", "flag_path": "...", "folder": "en"}}
var _available_languages: Dictionary = {}
var _core_default_locale: String = "en"

func _ready():
	pass # Lo inicializaremos desde el BootBase después de los archivos

# ==========================================
# 1. ESCÁNER MULTICAPA
# ==========================================
func scan_all_languages():
	_available_languages.clear()
	
	var config = FileManager.config
	if not config:
		push_error("Essence: LanguageManager no pudo acceder a la configuración del FileManager.")
		return
	
	# 1. Core (El motor base)
	if config.load_framework_loc:
		print("Essence: Buscando idiomas base en -> ", config.path_static_loc)
		_scan_directory(config.path_static_loc)
	
	# 2. Remote (Los mods/archivos del usuario final)
	var path_remote = FileManager.path_remote_actual + "/languages/"
	
	# --- PARCHE DE SEGURIDAD ---
	# Si la carpeta languages no existe junto al .exe, la creamos vacía para evitar el warning
	if not DirAccess.dir_exists_absolute(path_remote):
		DirAccess.make_dir_recursive_absolute(path_remote)
	# ---------------------------
		
	print("Essence: Buscando idiomas remotos en -> ", path_remote)
	_scan_directory(path_remote)
	
	print("Essence: Idiomas únicos detectados: ", _available_languages.keys())

# ==========================================
# 2. LECTOR DE CARPETAS Y BANDERAS
# ==========================================
func _scan_directory(base_path: String):
	# Nos aseguramos de que la ruta termine en "/" para evitar errores de concatenación
	if not base_path.ends_with("/"):
		base_path += "/"
		
	var dir = DirAccess.open(base_path)
	if not dir: 
		print("Essence WARNING: La carpeta no existe o está vacía: ", base_path)
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and folder_name != "." and folder_name != "..":
			var lang_path = base_path + folder_name + "/"
			_parse_language_folder(folder_name, lang_path)
			
		folder_name = dir.get_next()

# ==========================================
# 3. EXTRACTOR DE METADATOS (meta.cfg)
# ==========================================
func _parse_language_folder(lang_code: String, folder_path: String):
	var meta_path = folder_path + "meta.cfg"
	var flag_path = folder_path + "icon_flag.png"
	
	# Si ya existe en el diccionario, lo recuperamos para actualizarlo; si no, creamos uno nuevo
	var lang_data = _available_languages.get(lang_code, {"folder": lang_code})
	
	# Leemos el meta.cfg si existe usando la clase nativa ConfigFile
	if FileAccess.file_exists(meta_path):
		var config = ConfigFile.new()
		var err = config.load(meta_path)
		if err == OK:
			lang_data["name"] = config.get_value("info", "name", lang_code)
			lang_data["author"] = config.get_value("info", "author", "Unknown")
			lang_data["is_ai"] = config.get_value("info", "is_ai", false)
			
			#Si es la carpeta interna del motor y dice ser el default, lo guardamos
			if "static_loc" in folder_path and config.get_value("info", "is_default", false):
				_core_default_locale = lang_code
	
	# Buscamos la bandera
	if FileAccess.file_exists(flag_path):
		lang_data["flag_path"] = flag_path
		
	# Guardamos de vuelta en el diccionario
	_available_languages[lang_code] = lang_data

# ==========================================
# 4. API PARA LA INTERFAZ
# ==========================================
## Devuelve un Array limpio con los diccionarios de cada idioma para que el menú cree las tarjetas
func get_language_list() -> Array:
	return _available_languages.values()
	

# ==========================================
# 5. INYECCIÓN DE TRADUCCIONES AL MOTOR
# ==========================================
func inject_translations():
	print("Essence: Inyectando diccionarios de texto en la memoria...")
	var config = FileManager.config
	if not config: return
	
	# 1. Cargamos los diccionarios del motor (.translation generados del CSV)
	if config.load_framework_loc:
		_load_translations_from_dir(config.path_static_loc)
		
	# 2. Cargamos los diccionarios remotos (Si el usuario hizo mods)
	var path_remote = FileManager.path_remote_actual + "/languages/"
	_load_translations_from_dir(path_remote)

func _load_translations_from_dir(path: String):
	var dir = DirAccess.open(path)
	if not dir: return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Godot 4 usa la terminación .translation para archivos pre-compilados
		if not dir.current_is_dir() and file_name.ends_with(".translation"):
			var full_path = path + "/" + file_name
			var trans = load(full_path)
			
			if trans is Translation:
				TranslationServer.add_translation(trans)
				print(" -> Inyectado con éxito: ", file_name)
				
		file_name = dir.get_next()

func apply_initial_language():
	print("Essence: Determinando idioma inicial...")
	
	# TODO: Aquí leeremos el archivo de guardado (Ej. EssenceSaveManager.get_setting("language"))
	var saved_language = "" 
	
	if saved_language != "":
		print(" -> Idioma cargado desde preferencias: ", saved_language)
		TranslationServer.set_locale(saved_language)
	else:
		print(" -> Primera vez jugando. Forzando idioma por defecto del Core: ", _core_default_locale)
		TranslationServer.set_locale(_core_default_locale)
