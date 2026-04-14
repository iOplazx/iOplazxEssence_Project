extends Node

const ES_NAME_CLASS = "EssenceLanguageManager"

# Diccionario maestro para evitar duplicados.
var _available_languages: Dictionary = {}
var _core_default_locale: String = "en"

var path_addon = ""
var path_game = ""

func _ready() -> void:
	pass # Lo inicializaremos desde el BootBase después de los archivos
	
# ==========================================
# 1. ESCÁNER MULTICAPA
# ==========================================
func scan_all_languages() -> void:
	_available_languages.clear()
	var log_msg = ""
	
	# LATE BINDING: Obtenemos el config de forma segura
	var config = _safe_get_file_config()
	if not is_instance_valid(config):
		_safe_error( 
			"LanguageManager Error",
			"LanguageManager could not access the FileManager settings.",
			2 # CRITICAL
		)
		return
		
	# --- RUTAS ---
	var path_addon = config.path_static_loc + "languages/"
	var path_persistent = config.path_persistent + "languages/"
	var path_game = _safe_get_remote_path() + "/languages/"
	
	# 1. CAPA ADDON (El motor base)
	if config.load_framework_loc:
		_safe_log("[%s/scan_all_languages] Looking for base languages in: %s" % [ES_NAME_CLASS, path_addon])
		_scan_directory(path_addon, "addon") 
		
	# 2. CAPA PERSISTENT (El Búnker / Seguridad)
	if DirAccess.dir_exists_absolute(path_persistent):
		_safe_log("[%s/scan_all_languages] Looking for backup languages in: %s" % [ES_NAME_CLASS, path_persistent])
		_scan_directory(path_persistent, "game_base") 

	# 3. CAPA REMOTE (Modificaciones del usuario)
	if not DirAccess.dir_exists_absolute(path_game):
		DirAccess.make_dir_recursive_absolute(path_game)
		
	_safe_log("[%s/scan_all_languages] Looking for remote user languages in: %s" % [ES_NAME_CLASS, path_game])
	_scan_directory(path_game, "game_remote") 
	
	_safe_log("[%s/scan_all_languages] Final detected languages: %s" % [ES_NAME_CLASS, _available_languages.keys()])
	
# ==========================================
# 2. LECTOR DE CARPETAS Y BANDERAS
# ==========================================
func _scan_directory(base_path: String, scan_type: String) -> void: 
	if not base_path.ends_with("/"):
		base_path += "/"
		
	var dir = DirAccess.open(base_path)
	if not dir: 
		_safe_error( 
			"LanguageManager Warning",
			"The directory does not exist or is empty: %s" % base_path,
			1 # WARNING
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
func _parse_language_folder(lang_code: String, folder_path: String, scan_type: String) -> void:
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
				
				# LÓGICA DE FALLBACK
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

					if not found and _available_languages.has(_core_default_locale):
						lang_data["addon_data"] = _available_languages[_core_default_locale]["addon_data"]
						lang_data["addon_supported"] = true
						lang_data["addon_is_fallback"] = true 

	# PRIORIDAD DE BANDERA (La del juego siempre gana)
	if FileAccess.file_exists(flag_path):
		lang_data["flag_path"] = flag_path

# ==========================================
# 4. API PARA LA INTERFAZ (FILTRADO AVANZADO)
# ==========================================

func get_languages(filters: Dictionary = {}) -> Array:
	var result = []
	for lang in _available_languages.values():
		var passes_filters = true
		
		if filters.get("exclude_game_ai", false):
			var is_game_ai = lang.get("game_data", {}).get("is_ai", false)
			if lang["game_supported"] and is_game_ai:
				passes_filters = false

		if filters.get("exclude_addon_ai", false):
			var is_addon_ai = lang.get("addon_data", {}).get("is_ai", false)
			if lang["addon_supported"] and is_addon_ai:
				passes_filters = false
				
		if filters.get("exclude_all_ai", false):
			var is_game_ai = lang.get("game_data", {}).get("is_ai", false)
			var is_addon_ai = lang.get("addon_data", {}).get("is_ai", false)
			if is_game_ai and is_addon_ai:
				passes_filters = false
				
		if filters.get("only_game", false) and not lang["game_supported"]:
			passes_filters = false
			
		if filters.get("only_addon", false) and not lang["addon_supported"]:
			passes_filters = false
			
		if filters.has("min_game_version"):
			var current_ver = lang.get("game_data", {}).get("number_target_version", 0)
			if current_ver < filters["min_game_version"]:
				passes_filters = false

		if passes_filters:
			result.append(lang)
			
	return result

func get_language_list() -> Array:
	return get_languages() 

# ==========================================
# 5. INYECCIÓN DE TRADUCCIONES AL MOTOR
# ==========================================
func inject_translations() -> void:
	_safe_log("[%s/inject_translations] Injecting translations into memory..." % ES_NAME_CLASS)
	
	var config = _safe_get_file_config()
	if not is_instance_valid(config): return
	
	if config.load_framework_loc:
		_scan_and_inject_folders(config.path_static_loc + "languages/")
		
	_scan_and_inject_folders(config.path_persistent + "languages/")
	_scan_and_inject_folders(_safe_get_remote_path() + "/languages/")
	
func _scan_and_inject_folders(base_path: String) -> void:
	var dir = DirAccess.open(base_path)
	if not dir: return
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and folder_name != "." and folder_name != "..":
			var lang_folder_path = base_path + folder_name + "/"
			_load_translations_from_dir(lang_folder_path)
		folder_name = dir.get_next()

func _load_translations_from_dir(path: String) -> void:
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
			_safe_log("[%s/_load_translations_from_dir] Successfully injected: %s" % [ES_NAME_CLASS, file_name])
		file_name = dir.get_next()

# ==========================================
# 6. ARRANQUE INICIAL DEL IDIOMA
# ==========================================
func apply_initial_language() -> void:
	_safe_log("[%s/apply_initial_language] Determining initial language..." % ES_NAME_CLASS)
	
	var pref_lang = _safe_get_pref("game", "language", "")
	if pref_lang != "" and _available_languages.has(pref_lang):
		TranslationServer.set_locale(pref_lang)
		_safe_log("[%s/apply_initial_language] Loaded language from preferences: %s" % [ES_NAME_CLASS, pref_lang])
		return
	
	if _available_languages.has(_core_default_locale):
		TranslationServer.set_locale(_core_default_locale)
		_safe_log("[%s/apply_initial_language] Defaulting to core language: %s" % [ES_NAME_CLASS, _core_default_locale])
		return

	var os_lang = OS.get_locale_language()
	if _available_languages.has(os_lang):
		TranslationServer.set_locale(os_lang)
		_safe_log("[%s/apply_initial_language] Auto-detected OS language: %s" % [ES_NAME_CLASS, os_lang])

func save_language_preference(code: String) -> void:
	_safe_set_pref("game", "language", code)

# ==========================================
# 7. RESTAURACIÓN DE ARCHIVOS OFICIALES
# ==========================================

func restore_official_languages() -> void:
	var config = _safe_get_file_config()
	if not is_instance_valid(config): return
	
	var path_remote = _safe_get_remote_path() + "/languages/"
	_safe_log("[%s/restore] Starting factory reset of official languages..." % ES_NAME_CLASS)
	
	var bunkers = []
	if config.load_framework_loc:
		bunkers.append(config.path_static_loc + "languages/")
		
	bunkers.append(config.path_persistent + "languages/")
	
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
					_safe_log("[%s] Restored official folder: %s from %s" % [ES_NAME_CLASS, folder_name, bunker_path])
					
				folder_name = dir.get_next()
			dir.list_dir_end()
			
	scan_all_languages()
	inject_translations()

func _copy_folder_recursive(from_path: String, to_path: String) -> void:
	if not DirAccess.dir_exists_absolute(to_path):
		var err_dir = DirAccess.make_dir_recursive_absolute(to_path)
		if err_dir != OK:
			_safe_log("[%s/CRITICAL] Could not create directory %s. Code: %s" % [ES_NAME_CLASS, to_path, err_dir])
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
					_copy_folder_recursive(src, dest)
				else:
					if FileAccess.file_exists(dest):
						DirAccess.remove_absolute(dest)
					
					var err = DirAccess.copy_absolute(src, dest)
					if err == OK:
						_safe_log("[%s] Copied file: %s" % [ES_NAME_CLASS, file_name])
					else:
						_safe_log("[%s/FAILED] FAILED to copy %s. Code: %s" % [ES_NAME_CLASS, file_name, err])
					
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		_safe_log("[%s/FAILED] FAILED to open source directory: %s" % [ES_NAME_CLASS, from_path])

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

func _safe_get_pref(section: String, key: String, default_val: Variant) -> Variant:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("get_setting"):
		return prefs.get_setting(section, key, default_val)
	return default_val

func _safe_set_pref(section: String, key: String, value: Variant) -> void:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("set_setting"):
		prefs.set_setting(section, key, value)

func _safe_get_file_config() -> Resource:
	var fm = get_tree().root.get_node_or_null("FileManager")
	if is_instance_valid(fm) and "config" in fm:
		return fm.config
	return null

func _safe_get_remote_path() -> String:
	var fm = get_tree().root.get_node_or_null("FileManager")
	if is_instance_valid(fm) and "path_remote_actual" in fm:
		return fm.path_remote_actual
	return "user://"