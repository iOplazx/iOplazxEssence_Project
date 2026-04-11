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
		EssenceError.report( 
			"LanguageManager Error Scan All Languages",
			"LanguageManager could not access the FileManager settings.",
			EssenceError.Severity.CRITICAL
		)
		return
		
	# --- RUTAS ---
	var path_addon = config.path_static_loc + "languages/"
	var path_persistent = config.path_persistent + "languages/"
	var path_game = FileManager.path_remote_actual + "/languages/"
	
	# 1. CAPA ADDON (El motor base)
	if config.load_framework_loc:
		log_msg = "[%s/scan_all_languages] Looking for base languages in: %s" % [ES_NAME_CLASS, path_addon]
		EssenceLogger.system_info(log_msg)
		_scan_directory(path_addon, "addon") 
		
	# 2. CAPA PERSISTENT (El Búnker / Seguridad)
	if DirAccess.dir_exists_absolute(path_persistent):
		log_msg = "[%s/scan_all_languages] Looking for backup languages in: %s" % [ES_NAME_CLASS, path_persistent]
		EssenceLogger.system_info(log_msg)
		_scan_directory(path_persistent, "game_base") # <-- CAMBIO A game_base

	# 3. CAPA REMOTE (Modificaciones del usuario)
	if not DirAccess.dir_exists_absolute(path_game):
		DirAccess.make_dir_recursive_absolute(path_game)
		
	log_msg = "[%s/scan_all_languages] Looking for remote user languages in: %s" % [ES_NAME_CLASS, path_game]
	EssenceLogger.system_info(log_msg)
	_scan_directory(path_game, "game_remote") # <-- CAMBIO A game_remote
	
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
			EssenceError.Severity.WARNING
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
			
			# BLINDAJE DE SEGURIDAD: Solo archivos oficiales pueden definir el idioma default.
			if (scan_type == "addon" or scan_type == "game_base") and config.get_value("info", "is_default", false):
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
				# --- ES EL JUEGO (Aplica tanto para game_base como game_remote) ---
				lang_data["game_data"] = specific_data
				lang_data["game_supported"] = true
				
				# LÓGICA DE FALLBACK (Búsqueda de Addon alternativo)
				if not lang_data["addon_supported"]:
					var search_1 = config.get_value("info", "addon_search_1", "")
					var search_2 = config.get_value("info", "addon_search_2", "")

					var found = false
					for s in [search_1, search_2]:
						if s != "" and _available_languages.has(s):
							lang_data["addon_data"] = _available_languages[s]["addon_data"]
							lang_data["addon_supported"] = true
							lang_data["addon_is_fallback"] = false 
							found = true
							break

					if not found:
						lang_data["addon_data"] = _available_languages[_core_default_locale]["addon_data"]
						lang_data["addon_supported"] = true
						lang_data["addon_is_fallback"] = true 

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
	var log_msg = "[%s/apply_initial_language] Determining initial language..." % ES_NAME_CLASS
	EssenceLogger.system_info(log_msg)
	
	# 1. PRIORIDAD MÁXIMA: La elección previa del usuario (Persistencia)
	var pref_lang = Preferences.get_setting("game", "language", "")
	if pref_lang != "" and _available_languages.has(pref_lang):
		TranslationServer.set_locale(pref_lang)
		EssenceLogger.system_info("[%s/apply_initial_language] Loaded language from preferences: %s" % [ES_NAME_CLASS, pref_lang])
		return
	
	# 2. SEGUNDA PRIORIDAD: El idioma "is_default" de tu Framework/Búnker (Ignora el OS y Mods)
	if _available_languages.has(_core_default_locale):
		TranslationServer.set_locale(_core_default_locale)
		EssenceLogger.system_info("[%s/apply_initial_language] Defaulting to core language: %s" % [ES_NAME_CLASS, _core_default_locale])
		return

	# 3. ÚLTIMO RECURSO: Idioma del Sistema
	var os_lang = OS.get_locale_language()
	if _available_languages.has(os_lang):
		TranslationServer.set_locale(os_lang)
		EssenceLogger.system_info("[%s/apply_initial_language] Auto-detected OS language: %s" % [ES_NAME_CLASS, os_lang])

func save_language_preference(code: String):
	Preferences.set_setting("game", "language", code)

# ==========================================
# 7. RESTAURACIÓN DE ARCHIVOS OFICIALES
# ==========================================

func restore_official_languages():
	var config = FileManager.config 
	if not config: return
	
	var path_remote = FileManager.path_remote_actual + "/languages/"
	EssenceLogger.system_info("[%s/restore] Starting factory reset of official languages..." % ES_NAME_CLASS)
	
	# Lista de los "Búnkeres" que vamos a restaurar
	var bunkers = []
	
	# 1. Búnker del Framework (Donde probablemente está tu 'es' base)
	if config.load_framework_loc:
		bunkers.append(config.path_static_loc + "languages/")
		
	# 2. Búnker del Juego (Donde está tu 'en')
	bunkers.append(config.path_persistent + "languages/")
	
	# Recorremos cada búnker y copiamos su contenido
	for bunker_path in bunkers:
		if not DirAccess.dir_exists_absolute(bunker_path): 
			continue
			
		var dir = DirAccess.open(bunker_path)
		if dir:
			dir.list_dir_begin()
			var folder_name = dir.get_next()
			while folder_name != "":
				if dir.current_is_dir() and not folder_name.begins_with("."):
					var src_path = bunker_path + folder_name
					var dest_path = path_remote + folder_name
					
					_copy_folder_recursive(src_path, dest_path)
					EssenceLogger.system_info("[%s] Restored official folder: %s from %s" % [ES_NAME_CLASS, folder_name, bunker_path])
					
				folder_name = dir.get_next()
			dir.list_dir_end()
			
	# Después de restaurar los archivos físicos, forzamos recarga
	scan_all_languages()
	inject_translations()

# Función ultra-rápida y blindada para copiar carpetas
func _copy_folder_recursive(from_path: String, to_path: String):
	# 1. Aseguramos que la carpeta de destino exista
	if not DirAccess.dir_exists_absolute(to_path):
		var err_dir = DirAccess.make_dir_recursive_absolute(to_path)
		if err_dir != OK:
			var log_msg = "[%s/CRITICAL] Could not create directory %s. Code: %s" % [ES_NAME_CLASS, to_path, err_dir]
			EssenceLogger.system_info(log_msg)
			return
		
	var dir = DirAccess.open(from_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.begins_with("."):
				var src = from_path + "/" + file_name
				var dest = to_path + "/" + file_name
				
				if dir.current_is_dir():
					# Si es carpeta, entramos recursivamente
					_copy_folder_recursive(src, dest)
				else:
					# ES UN ARCHIVO: Procedemos a copiar
					
					# TRUCO PRO: Si el archivo ya existe en _remote, lo borramos primero 
					# para evitar conflictos de bloqueo de Windows.
					if FileAccess.file_exists(dest):
						DirAccess.remove_absolute(dest)
					
					# Copiamos de res:// al disco duro
					var err = DirAccess.copy_absolute(src, dest)
					
					if err == OK:
						EssenceLogger.system_info("[%s] Copied file: %s" % [ES_NAME_CLASS, file_name])
					else:
						# Si falla, esto nos dirá exactamente por qué
						EssenceLogger.system_info("[%s/FAILED] FAILED to copy %s. Code: %s" % [ES_NAME_CLASS, file_name, err])
					
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		EssenceLogger.system_info("[%s/FAILED] FAILED to open source directory: %s" % [ES_NAME_CLASS, from_path])
