extends Node
const ES_NAME_CLASS = "EssenceLanguageManager"

# Diccionario maestro para evitar duplicados. 
# Estructura: {"en": {"name": "English", "author": "...", "flag_path": "...", "folder": "en"}}
var _available_languages: Dictionary = {}
var _core_default_locale: String = "en"

var path_addon = ""
var path_game = ""

func _ready():
	pass # Lo inicializaremos desde el BootBase después de los archivos
	
# ==========================================
# 1. ESCÁNER MULTICAPA
# ==========================================
func scan_all_languages():
	_available_languages.clear()
	var log_msg = ""
	
	var config = FileManager.config
	if not config:
		#push_error("Essence: LanguageManager no pudo acceder a la configuración del FileManager.")
		EssenceError.report( 
			"LanguageManager Error Scan All Languages",
			"LanguageManager could not access the FileManager settings.",
			EssenceError.severity.CRITICAL
		)
		return
		
	# --- RUTAS ---
	var path_addon = config.path_static_loc + "languages/"
	var path_persistent = config.path_persistent + "languages/"
	var path_game = FileManager.path_remote_actual + "/languages/"
	
	# 1. CAPA ADDON (El motor base)
	if config.load_framework_loc:
		#print("Essence: Buscando idiomas base en -> ", path_addon)
		log_msg = "[%s/scan_all_languages] Looking for base languages in: %s" % [ES_NAME_CLASS, path_addon]
		EssenceLogger.system_info(log_msg)
		_scan_directory(path_addon, "addon") 
		
	# 2. CAPA PERSISTENT (El Búnker / Seguridad)
	if DirAccess.dir_exists_absolute(path_persistent):
		#print("Essence: Buscando idiomas de seguridad en -> ", path_persistent)
		log_msg = "[%s/scan_all_languages] Looking for backup languages in: %s" % [ES_NAME_CLASS, path_persistent]
		EssenceLogger.system_info(log_msg)
		_scan_directory(path_persistent, "game")

	# 3. CAPA REMOTE (Modificaciones del usuario)
	if not DirAccess.dir_exists_absolute(path_game):
		DirAccess.make_dir_recursive_absolute(path_game)
		
	#print("Essence: Buscando idiomas remotos (usuario) en -> ", path_game)
	log_msg = "[%s/scan_all_languages] Looking for remote user languages in: %s" % [ES_NAME_CLASS, path_game]
	EssenceLogger.system_info(log_msg)
	_scan_directory(path_game, "game") 
	
	print("Essence: Idiomas finales detectados: ", _available_languages.keys())
	log_msg = "[%s/scan_all_languages] Final detected languages: %s" % [ES_NAME_CLASS, _available_languages.keys()]
	EssenceLogger.system_info(log_msg)

# ==========================================
# 2. LECTOR DE CARPETAS Y BANDERAS
# ==========================================
func _scan_directory(base_path: String, scan_type: String): 
	if not base_path.ends_with("/"):
		base_path += "/"
		
	var dir = DirAccess.open(base_path)
	if not dir: 
		#print("Essence WARNING: La carpeta no existe o está vacía: ", base_path)
		EssenceError.report( 
			"LanguageManager Warning Scan Directory",
			"The directory does not exist or is empty: %s" % base_path,
			EssenceError.severity.WARNING
		)
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and folder_name != "." and folder_name != "..":
			var lang_path = base_path + folder_name + "/"
			_parse_language_folder(folder_name, lang_path, scan_type) 
			
		folder_name = dir.get_next()

# ==========================================
# 3. EXTRACTOR DE METADATOS (meta.cfg)
# ==========================================
func _parse_language_folder(lang_code: String, folder_path: String, scan_type: String):
	var meta_path = folder_path + "meta.cfg"
	var flag_path = folder_path + "icon_flag.png"
	
	if not _available_languages.has(lang_code):
		_available_languages[lang_code] = {
			"folder": lang_code,
			"name": lang_code,
			"flag_path": "",
			"game_supported": false,
			"addon_supported": false,
			"game_data": {},
			"addon_data": {}
		}
	
	var lang_data = _available_languages[lang_code]
	
	if FileAccess.file_exists(meta_path):
		var config = ConfigFile.new()
		var err = config.load(meta_path)
		
		if err == OK:
			lang_data["name"] = config.get_value("info", "name", lang_data["name"])
			
			if scan_type == "addon" and config.get_value("info", "is_default", false):
				_core_default_locale = lang_code
				
			var specific_data = {
				"author": config.get_value("info", "author", "Unknown"),
				"description": config.get_value("info", "description", ""),
				"is_ai": config.get_value("info", "is_ai", false),
				"version": config.get_value("info", "version", "1.0.0"),
				"target_version": config.get_value("info", "target_version", "1.0.0"),
				"number_target_version": config.get_value("info", "number_target_version", 0)
			}
			
			if scan_type == "addon":
				lang_data["addon_data"] = specific_data
				lang_data["addon_supported"] = true
			else:
				# --- ES EL JUEGO ---
				lang_data["game_data"] = specific_data
				lang_data["game_supported"] = true
				
				# LÓGICA DE FALLBACK (Búsqueda de Addon alternativo)
				# Si el juego no tiene soporte de addon directo, buscamos si pidió uno prestado
				if not lang_data["addon_supported"]:
					var search_1 = config.get_value("info", "addon_search_1", "")
					var search_2 = config.get_value("info", "addon_search_2", "")

					var found = false
					for s in [search_1, search_2]:
						if s != "" and _available_languages.has(s):
							lang_data["addon_data"] = _available_languages[s]["addon_data"]
							lang_data["addon_supported"] = true
							lang_data["addon_is_fallback"] = false # Se encontró lo que pidió
							found = true
							break

					if not found:
						# NO se encontró lo pedido. Usamos el Core (Inglés) pero marcamos la alerta
						lang_data["addon_data"] = _available_languages[_core_default_locale]["addon_data"]
						lang_data["addon_supported"] = true
						lang_data["addon_is_fallback"] = true # <--- ¡ALERTA!

	# PRIORIDAD DE BANDERA (La del juego siempre gana)
	if FileAccess.file_exists(flag_path):
		lang_data["flag_path"] = flag_path

# ==========================================
# 4. API PARA LA INTERFAZ (FILTRADO AVANZADO)
# ==========================================

## Método maestro para obtener idiomas con filtros opcionales.
func get_languages(filters: Dictionary = {}) -> Array:
	var result = []
	
	for lang in _available_languages.values():
		var passes_filters = true
		
		# Filtro 1: Excluir IA del Juego
		if filters.get("exclude_game_ai", false):
			var is_game_ai = lang.get("game_data", {}).get("is_ai", false)
			# Solo ocultamos si existe la data del juego Y además es de IA
			if lang["game_supported"] and is_game_ai:
				passes_filters = false

		# Filtro 2: Excluir IA del Addon/Framework
		if filters.get("exclude_addon_ai", false):
			var is_addon_ai = lang.get("addon_data", {}).get("is_ai", false)
			if lang["addon_supported"] and is_addon_ai:
				passes_filters = false
				
		# Filtro 3: "Exclude All AI" (El modo estricto)
		# Solo oculta el idioma si AMBAS partes son de IA. Si al menos una es humana, se salva.
		if filters.get("exclude_all_ai", false):
			var is_game_ai = lang.get("game_data", {}).get("is_ai", false)
			var is_addon_ai = lang.get("addon_data", {}).get("is_ai", false)
			
			if is_game_ai and is_addon_ai:
				passes_filters = false
				
		# Filtro 4: Solo los que tengan traducción del juego
		if filters.get("only_game", false) and not lang["game_supported"]:
			passes_filters = false
			
		# Filtro 5: Solo los que tengan traducción del framework (addon)
		if filters.get("only_addon", false) and not lang["addon_supported"]:
			passes_filters = false
			
		# Filtro 5: Compatibilidad de versión (number_target_version)
		if filters.has("min_game_version"):
			var current_ver = lang.get("game_data", {}).get("number_target_version", 0)
			if current_ver < filters["min_game_version"]:
				passes_filters = false

		# Si sobrevivió a todos los filtros, lo añadimos a la lista final
		if passes_filters:
			result.append(lang)
			
	return result

## Método de compatibilidad para devolver la lista completa
func get_language_list() -> Array:
	return get_languages() # Llama al maestro sin filtros()

# ==========================================
# 5. INYECCIÓN DE TRADUCCIONES AL MOTOR
# ==========================================
func inject_translations():
	#print("Essence: Inyectando diccionarios de texto en la memoria...")
	var log_msg = "[%s/inject_translations] Injecting translations into memory..." % ES_NAME_CLASS
	EssenceLogger.system_info(log_msg)
	var config = FileManager.config
	if not config: return
	
	# 1. Inyectamos Addon
	if config.load_framework_loc:
		_scan_and_inject_folders(config.path_static_loc + "languages/")
		
	# 2. Inyectamos Persistent (Búnker)
	_scan_and_inject_folders(config.path_persistent + "languages/")
	
	# 3. Inyectamos Remote (Usuario)
	_scan_and_inject_folders(FileManager.path_remote_actual + "/languages/")
	
func _scan_and_inject_folders(base_path: String):
	var dir = DirAccess.open(base_path)
	if not dir: return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		# Si es una carpeta de idioma (ej. "en", "es"), entramos a buscar traducciones
		if dir.current_is_dir() and folder_name != "." and folder_name != "..":
			var lang_folder_path = base_path + folder_name + "/"
			_load_translations_from_dir(lang_folder_path)
			
		folder_name = dir.get_next()

func _load_translations_from_dir(path: String):
	var dir = DirAccess.open(path)
	if not dir: return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".translation"):
			var full_path = path + "/" + file_name
			var trans = load(full_path)
			
			if trans is Translation:
				TranslationServer.add_translation(trans)
				#print(" -> Inyectado con éxito: ", file_name)
				var log_msg = "[%s/_load_translations_from_dir] Successfully injected: %s" % [ES_NAME_CLASS, file_name]
				EssenceLogger.system_info(log_msg)
				
		file_name = dir.get_next()

# ==========================================
# 6. ARRANQUE INICIAL DEL IDIOMA
# ==========================================
func apply_initial_language():
	#print("Essence: Determinando idioma inicial...")
	var log_msg = "[%s/apply_initial_language] Determining initial language..." % ES_NAME_CLASS
	EssenceLogger.system_info(log_msg)
	
	# Usamos el cerebro centralizado para pedir el idioma
	var saved_language = Preferences.get_setting("language", "locale", "") 
	
	if saved_language != "":
		log_msg = "[%s/apply_initial_language] Loaded language from preferences: %s" % [ES_NAME_CLASS, saved_language]
		#print(" -> Idioma cargado desde preferencias: ", saved_language)
		EssenceLogger.system_info(log_msg)
		TranslationServer.set_locale(saved_language)
	else:
		#print(" -> Primera vez jugando. Forzando idioma por defecto del Core: ", _core_default_locale)
		log_msg = "[%s/apply_initial_language] First time playing. Forcing core default language: %s" % [ES_NAME_CLASS, _core_default_locale]
		EssenceLogger.system_info(log_msg)
		TranslationServer.set_locale(_core_default_locale)
		
# ==========================================
# 7. GUARDADO Y CARGA DE PREFERENCIAS
# ==========================================
func save_language_preference(lang_code: String):
	# Delegamos todo el trabajo pesado al Autoload central
	Preferences.set_setting("language", "locale", lang_code)
	Preferences.save_to_disk()
	
	#print("Essence: Idioma guardado en disco -> ", lang_code)
	var log_msg = "[%s/save_language_preference] Language saved to disk: %s" % [ES_NAME_CLASS, lang_code]
	EssenceLogger.system_info(log_msg)
