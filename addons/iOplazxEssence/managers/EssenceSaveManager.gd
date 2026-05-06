class_name EssenceSaveManager extends Node
const ES_NAME_CLASS = "EssenceSaveManager"

# ==========================================
# CONFIGURACIÓN DINÁMICA DEL FRAMEWORK
# ==========================================
var _save_dir: String = "user://saves/"
var _encryption_key: String = "iOplazx_Default_Insecure_Key_!#"

var intent_is_save_mode: bool = false
const INDEX_FILE = "save_index.json"
const KEY_META = "essence_meta"
var _config: EssenceMasterConfig

var _action_points: int = 0
var _points_to_save: int = 5 # Cuántos puntos detonarán el guardado

# Señales para comunicar al UI o al juego que algo terminó
signal on_save_completed(slot_id: String)
signal on_load_completed(slot_id: String, data: Dictionary)
signal on_save_error(slot_id: String, error_msg: String)

func _ready():
	_verificar_config()
	_cargar_llave_secreta()
	_configurar_directorio_usuario()
	
func _verificar_config():
	# cambio a EssenceMasterConfig
	_config = load(EssencePaths.CARPET_STATIC+"EssenceMasterConfig.tres") as EssenceMasterConfig
	
	if not _config:
		push_warning("iOplazxEssence: No se encontró EssenceMasterConfig.tres. Usando valores por defecto.")

# ==========================================
# INYECCIÓN DE DEPENDENCIAS
# ==========================================

func _cargar_llave_secreta():
	var env_path = "res://.env"
	_encryption_key = "iOplazx_Default_Insecure_Key_!#" # Fallback de seguridad
	
	if FileAccess.file_exists(env_path):
		var file = FileAccess.open(env_path, FileAccess.READ)
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line.begins_with("ENCRYPTION_KEY="):
				_encryption_key = line.split("=", true, 1)[1].strip_edges()
				break
		file.close()

func _configurar_directorio_usuario() -> void:
	# LATE BINDING: Usamos el wrapper en lugar de llamar a Preferences directamente
	var save_location: int = _safe_get_pref("game", "save_location", 0)
	
	# 1. Definimos la ruta principal según la preferencia
	if save_location == 1 and not OS.has_feature("editor"):
		var exe_folder = OS.get_executable_path().get_base_dir()
		_save_dir = exe_folder.path_join("saves/")
	else:
		_save_dir = "user://saves/"
		
	if not DirAccess.dir_exists_absolute(_save_dir):
		DirAccess.make_dir_recursive_absolute(_save_dir)
		_safe_log("[%s/setup] Save folder created at %s" % [ES_NAME_CLASS, _save_dir])

	# 2. SIEMPRE creamos la ruta temporal en local (AppData) 
	var temp_dir = "user://saves/temp/"
	if not DirAccess.dir_exists_absolute(temp_dir):
		DirAccess.make_dir_recursive_absolute(temp_dir)
		
# ==========================================
# RUTAS DINÁMICAS
# ==========================================
# Le agregamos un valor por defecto (false) para no romper el resto de tu código
func get_file_path(slot_id: String, is_temp: bool = false) -> String:
	if is_temp:
		return "user://saves/temp/".path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
	
	# Si no es temporal, respeta la configuración global/remota
	return _save_dir.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)

# ==========================================
# ESCRITURA Y CIFRADO
# ==========================================
func save_game(slot_id: String, save_object: EssenceSaveData, is_temp: bool = false) -> bool:
	var path = get_file_path(slot_id, is_temp)
	
	var save_package = save_object.to_dict() 
	var json_string = JSON.stringify(save_package)
	
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _encryption_key)
	if file == null:
		var err = FileAccess.get_open_error()
		_safe_error(
			"Save Error",
			"Could not create save file. Code: %s" % err, 
			2
		)
		on_save_error.emit(slot_id, "No se pudo escribir en el disco")
		return false
		
	file.store_string(json_string)
	file.close()
	
	# Actualizamos el archivo invisible
	_update_save_index(slot_id, false)
	
	var log_msg = "[%s/commit_save] Game saved successfully at %s" % [ES_NAME_CLASS, path]
	_safe_log(log_msg)
	on_save_completed.emit(slot_id)
	return true
	
# ==========================================
# LECTURA Y DESCIFRADO
# ==========================================
func load_game(slot_id: String) -> Dictionary:
	var path = get_file_path(slot_id)
	
	if not FileAccess.file_exists(path):
		return {} 
		
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, _encryption_key)
	if file == null:
		_safe_error(
			"Load Game Error",
			"Could not open save file. Possible causes: wrong key or corrupt file.", 
			2
		)
		return {}
		
	var json_string = file.get_as_text()
	file.close()
	
	var parsed_data = JSON.parse_string(json_string)
	if typeof(parsed_data) != TYPE_DICTIONARY:
		_safe_error("Load Game Error","The save file is corrupt or not in the correct format.", 1)
		return {}
		
	var final_data = _run_migrations(parsed_data)
	
	_marcar_como_ultimo_jugado(slot_id)
	
	var log_msg = "[%s/load_game] Game loaded successfully from %s" % [ES_NAME_CLASS, path]
	_safe_log(log_msg)
	
	on_load_completed.emit(slot_id, final_data)
	return final_data

# ==========================================
# UTILIDADES DE UI
# ==========================================
func get_all_metadata() -> Dictionary:
	var all_saves = {}
	var dir = DirAccess.open(_save_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(GameConstants.EXTENSION_SAVE_FILE):
				var slot_id = file_name.replace(GameConstants.EXTENSION_SAVE_FILE, "")
				var data = load_game(slot_id)
				if not data.is_empty():
					all_saves[slot_id] = data.get("essence_meta", {})
			file_name = dir.get_next()
			
	return all_saves

# ==========================================
# FACTORY: CONTROL DE VERSIONES
# ==========================================
func _run_migrations(package: Dictionary) -> Dictionary:
	var meta = package.get("essence_meta", {})
	var file_version = meta.get("version", 1)
	var game_data = package.get("game_data", {})
	
	if file_version < GameConstants.CURRENT_SAVE_VERSION:
		var log_msg = "[%s/run_migrations] Migrating save from v%d to v%d" % [ES_NAME_CLASS, file_version, GameConstants.CURRENT_SAVE_VERSION]
		_safe_log(log_msg)
		meta["version"] = GameConstants.CURRENT_SAVE_VERSION
		
	package["game_data"] = game_data
	return package
	
# ==========================================
# LÓGICA DEL ÍNDICE (MANIFEST)
# ==========================================

# Lee el archivo invisible. Si no existe, lo crea.
func _get_save_index() -> Dictionary:
	var path = _save_dir + INDEX_FILE
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			# Parche de seguridad: Si el archivo viejo no tiene la llave, la inyectamos en RAM
			if not data.has("last_export_path"):
				data["last_export_path"] = ""
			return data
			
	# Diccionario base actualizado
	return {"latest_save": "", "last_export_path": "", "used_slots": []}

# Actualiza el archivo invisible después de guardar o borrar
func _update_save_index(slot_id: String, is_deleting: bool = false):
	var index = _get_save_index()
	var path = _save_dir + INDEX_FILE
	
	if is_deleting:
		index["used_slots"].erase(slot_id)
		# Si borramos el más reciente, limpiamos el latest_save (o retrocedemos al anterior)
		if index["latest_save"] == slot_id:
			index["latest_save"] = index["used_slots"].back() if index["used_slots"].size() > 0 else ""
	else:
		if not index["used_slots"].has(slot_id):
			index["used_slots"].append(slot_id)
		index["latest_save"] = slot_id # Este es el último guardado real
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(index))
	file.close()
	
## Verifica de forma ultra-rápida si el archivo físico de un slot existe
func save_exists(slot_id: String) -> bool:
	if slot_id == "": return false
	var path = _save_dir.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
	return FileAccess.file_exists(path)

# ==========================================
# AYUDANTES PARA LA UI MODERNA Y CLÁSICA
# ==========================================

# El modo Moderno llama a esto para saber qué ID usar al crear una NUEVA partida
func get_next_available_slot(slots_per_page: int = 6) -> String:
	var index = _get_save_index()
	# Forzamos a que Godot sepa que esto es un Array para evitar otros warnings
	var used: Array = index.get("used_slots", [])
	
	# Buscamos huecos vacíos desde la página 1, slot 1 en adelante
	var current_page: int = 1
	var current_slot: int = 1
	
	# Límite de seguridad de 99 páginas para evitar que la PC se congele si algo sale mal
	while current_page < 100:
		var test_id = "save_" + str(current_page) + "_" + str(current_slot)
		if not used.has(test_id):
			return test_id # ¡Encontramos el primer hueco vacío!
			
		current_slot += 1
		if current_slot > slots_per_page:
			current_slot = 1
			current_page += 1
			
	# Esta línea nunca debería alcanzarse, pero quita el error del compilador
	return "save_99_99"

# Retorna cuál fue el último archivo modificado (útil para el botón "Continuar" del Menú Principal)
func get_latest_save_id() -> String:
	var latest_id = _get_save_index().get("latest_save", "")
	
	if latest_id == "":
		return ""
		
	# BLINDAJE: Verificamos físicamente en el disco si el archivo "fantasma" aún existe
	var save_path = "user://saves/".path_join(latest_id + GameConstants.EXTENSION_SAVE_FILE) # Ajusta la ruta a tu constante real
	
	if not FileAccess.file_exists(save_path):
		_safe_log("[%s] Referencia fantasma detectada: El archivo %s ya no existe." % [ES_NAME_CLASS, latest_id])
		# Idealmente, aquí podrías llamar a una función que recalcule el último guardado,
		# pero devolver "" es el parche seguro inmediato.
		return ""
		
	return latest_id
	
# Obtiene la última ruta de exportación guardada
func get_last_export_path() -> String:
	return _get_save_index().get("last_export_path", "")
	
# ==========================================
# SISTEMA DE SCREENSHOTS (SNAPSHOT)
# ==========================================
func take_and_save_screenshot(slot_id: String) -> void:
	# 1. Esperamos al final del frame para que la pantalla esté completamente dibujada
	await RenderingServer.frame_post_draw
	
	# 2. Capturamos la textura del Viewport principal
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	
	if img == null or img.is_empty():
		_safe_error("Snapshot capture error.","Error capturing the screen.", 1)
		return
		
	# 3. OPTIMIZACIÓN: Achicamos la imagen para no saturar el disco duro
	# 320x180 mantiene la relación de aspecto 16:9 estándar
	img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	
	# 4. Guardamos como .webp en la misma carpeta que el archivo .ess
	var image_path =  _save_dir.path_join(slot_id + GameConstants.EXTENSION_IMAGE)
	var err = img.save_webp(image_path)
	
	if err == OK:
		var log_msg = "[%s/take_and_save_screenshot] Snapshot saved successfully at %s" % [ES_NAME_CLASS, image_path]
		_safe_log(log_msg)
	else:
		_safe_error(
			"Snapshot Save Failed",
			"Failed to save the snapshot image. Code: %s" % err, 
			1
		)

# ==========================================
# CACHÉ TEMPORAL (Para transiciones de escena)
# ==========================================
var _temp_game_data: Dictionary = {}
var _temp_meta_data: Dictionary = {}
var loaded_game_data: Dictionary = {} # Para cuando carguemos una partida

# El juego llama a esto ANTES de ir a la pantalla de Guardar
func cache_current_state(game_data: Dictionary, meta_data: Dictionary):
	_temp_game_data = game_data
	_temp_meta_data = meta_data

# Toma la foto y la guarda como archivo temporal
func take_temp_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	if img and not img.is_empty():
		img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
		img.save_webp(_save_dir + "temp_snap" + GameConstants.EXTENSION_IMAGE)

# La UI llama a esto cuando el jugador elige un Slot
func commit_save(slot_id: String, is_temp: bool = false) -> bool:
	# === HOOK DE INTEGRACIÓN ===
	# Le damos al dev una última oportunidad de modificar o inyectar datos 
	# justo antes de que se congelen en el disco (ej: Tiempo de juego exacto).
	_on_before_save_hook(_temp_game_data, _temp_meta_data)
	
	if _temp_game_data.is_empty() and _temp_meta_data.is_empty(): return false
		
	var path = get_file_path(slot_id)
	var save_obj = EssenceSaveFactory.create_save_instance(_config)
	
	# Verificamos la INTENCIÓN (Create vs Overwrite)
	if FileAccess.file_exists(path):
		var old_data = load_game(slot_id)
		# Le decimos al objeto que se fusione con lo viejo
		save_obj.prepare_as_overwrite(old_data, _temp_meta_data, _temp_game_data)
	else:
		# Le decimos al objeto que nazca desde cero
		save_obj.prepare_as_new(_temp_meta_data, _temp_game_data)
		
		# Si es nuevo, sacamos la página y slot del ID
		var parts = slot_id.split("_")
		if parts.size() >= 3:
			save_obj.page = int(parts[1])
			save_obj.slot_number = int(parts[2])
	
	# El Manager solo se encarga de guardar en disco
	var success = save_game(slot_id, save_obj, is_temp)
	
	if success:
		# 1. Definimos las rutas completas para no dejar dudas
		var source_path = _save_dir.path_join("temp_snap" + GameConstants.EXTENSION_IMAGE)
		var target_folder = "user://saves/temp/" if is_temp else _save_dir
		var target_path = target_folder.path_join(slot_id + GameConstants.EXTENSION_IMAGE)

		# 2. Verificamos si la foto temporal realmente existe antes de copiar
		if FileAccess.file_exists(source_path):
			# USAMOS copy_absolute para evitar el Error 7
			var err = DirAccess.copy_absolute(source_path, target_path)
				
			if err == OK:
				var log_msg = "[%s/commit_save] Photo successfully copied to: %s" % [ES_NAME_CLASS, target_path]
				_safe_log(log_msg)
			else:
				_safe_error(
					"Screenshot Failed",
					"Error copying the photo to slot. Code: %s" % err, 
					1
				)
		else:
			# Si llegamos aquí, es que take_temp_screenshot() no ha terminado o no se llamó
			_safe_error(
				"Missing Snapshot",
				"Could not copy the photo because %s does not exist yet." % source_path, 
				1
			)
			
	return success

# Borra el archivo .ess, su foto y lo quita del index
func delete_save(slot_id: String):
	var dir = DirAccess.open(_save_dir)
	if dir:
		if dir.file_exists(slot_id + GameConstants.EXTENSION_SAVE_FILE):
			dir.remove(slot_id + GameConstants.EXTENSION_SAVE_FILE)
		if dir.file_exists(slot_id + GameConstants.EXTENSION_IMAGE):
			dir.remove(slot_id + GameConstants.EXTENSION_IMAGE)
			
	_update_save_index(slot_id, true) # true = está borrando
	var log_msg = "[%s/delete_save] Game successfully deleted -> %s" % [ES_NAME_CLASS, slot_id]
	_safe_log(log_msg)

# Actualiza solo el título en la metadata sin afectar los datos del juego
func update_save_title(slot_id: String, new_title: String):
	# Usamos tu propia función get_file_path para asegurar la extensión correcta
	var path = get_file_path(slot_id) 
	
	if FileAccess.file_exists(path):
		# 1. ABRIR CON CONTRASEÑA (Igual que en load_game)
		var file_read = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, _encryption_key)
		if file_read == null: 
			_safe_error(
				"Title Update Failed",
				"Could not open save file to edit title. Possible cause: wrong key.", 
				1
			)
			return
			
		var json_string = file_read.get_as_text()
		file_read.close()
		
		# 2. PARSEAR EL JSON DESENCRIPTADO
		var save_data = JSON.parse_string(json_string)
		
		# 3. MODIFICAR EL DICCIONARIO USANDO LA CONSTANTE
		if typeof(save_data) == TYPE_DICTIONARY:
			if save_data.has(KEY_META):
				save_data[KEY_META]["title"] = new_title
			else:
				save_data["title"] = new_title # Fallback por si la estructura cambia
				
			# 4. VOLVER A GUARDAR ENCRIPTADO (Igual que en save_game)
			var file_write = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _encryption_key)
			if file_write:
				file_write.store_string(JSON.stringify(save_data))
				file_write.close()
				var log_msg = "[%s/update_save_title] Success. Title on disk changed to '%s'" % [ES_NAME_CLASS, new_title]
				_safe_log(log_msg)
			else:
				_safe_error(
					"Title Update Failed",
					"Error rewriting encrypted file after title change.", 
					1
				)
				
## Retorna true si hay datos de una partida en vivo listos para procesarse
func has_live_session() -> bool:
	return not _temp_game_data.is_empty()
	
## Busca el primer slot disponible en el índice
func get_next_free_slot(current_meta: Dictionary) -> String:
	var max_pages = 50 
	var max_slots_per_page = 10 
	
	for page in range(1, max_pages + 1):
		for slot in range(1, max_slots_per_page + 1):
			var test_id = "save_" + str(page) + "_" + str(slot)
			
			if not current_meta.has(test_id):
				return test_id
				
	push_error("iOplazxEssence: No hay slots libres disponibles.")
	return ""

## Ejecuta la copia física pura y dura (sin UI)
func import_physical_file(source_ess: String, source_webp: String, target_slot_id: String) -> bool:
	var target_ess = _save_dir.path_join(target_slot_id + GameConstants.EXTENSION_SAVE_FILE)
	var target_webp = _save_dir.path_join(target_slot_id + GameConstants.EXTENSION_IMAGE)
	
	var success = false
	if FileAccess.file_exists(source_ess):
		DirAccess.copy_absolute(source_ess, target_ess)
		success = true
		
	if FileAccess.file_exists(source_webp):
		DirAccess.copy_absolute(source_webp, target_webp)
		
	return success
	
## Actualiza exclusivamente la ruta de exportación en el índice
func update_last_export_path(dir_path: String):
	var index = _get_save_index()
	index["last_export_path"] = dir_path
	
	var path = _save_dir + INDEX_FILE
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(index))
	file.close()
	
func mark_save_as_latest_played(slot_id: String):
	var index = _get_save_index()
	# Solo actualizamos si realmente hay un cambio, para ahorrar escrituras en disco
	if index["latest_save"] != slot_id:
		index["latest_save"] = slot_id
		
		var path = _save_dir + INDEX_FILE
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(index))
		file.close()

# ==========================================
# LIMPIEZA DE MEMORIA
# ==========================================
func delete_temp_screenshot():
	var dir = DirAccess.open(_save_dir)
	if dir and dir.file_exists("temp_snap" + GameConstants.EXTENSION_IMAGE):
		dir.remove("temp_snap" + GameConstants.EXTENSION_IMAGE)
		var log_msg = "[%s/delete_temp_screenshot] Temporary photo deleted." % ES_NAME_CLASS
		_safe_log(log_msg)

func clear_temp_data():
	_temp_game_data.clear()
	_temp_meta_data.clear()
	var log_msg = "[%s/clear_temp_data] Cache dictionaries cleared." % ES_NAME_CLASS
	_safe_log(log_msg)

func clear_all_temp():
	delete_temp_screenshot()
	clear_temp_data()

# ==========================================
# CHECKPOINTS INVISIBLES (BACKGROUND SAVING)
# ==========================================
var _action_threshold: int = 5 # Puntos para detonar guardado
const SLOT_CP_ACTION = "checkpoint_action"
const SLOT_CP_SCENE = "checkpoint_scene"

# 1. Guardado por acciones (Ej: moverse 5 veces en el MoveMapControl)
func save_action_checkpoint(weight: int = 1):
	_action_points += weight
	
	if _action_points >= _action_threshold:
		_action_points = 0 # Reiniciamos el contador
		_create_checkpoint(SLOT_CP_ACTION, "Punto de Control (Acción)")
		var log_msg = "[%s/save_action_checkpoint] Action checkpoint generated." % ES_NAME_CLASS
		_safe_log(log_msg)

# 2. Guardado por cambio de escena (Se llamará desde tu futuro SceneManager)
func save_scene_checkpoint():
	_create_checkpoint(SLOT_CP_SCENE, "Punto de Control (Escena)")

func _create_checkpoint(slot_id: String, cp_title: String):
	var temp_meta = {
		"title": cp_title,
		"description": "Auto-save de seguridad",
		"is_auto": true,
		"is_checkpoint": true
	}
	var temp_game = {}
	
	_on_before_save_hook(temp_game, temp_meta) 
	
	var save_obj = EssenceSaveFactory.create_save_instance(_config)
	save_obj.prepare_as_new(temp_meta, temp_game)
	save_obj.slot_number = 0
	
	save_game(slot_id, save_obj, false)
	

# ==========================================
# Metodo Auxiliar
# ==========================================
# Actualiza únicamente el puntero de "Continuar" sin alterar las fechas de las partidas
func _marcar_como_ultimo_jugado(slot_id: String):
	var index = _get_save_index()
	
	# Solo actualizamos si realmente es diferente, para ahorrar escrituras en disco
	if index.get("latest_save", "") != slot_id:
		index["latest_save"] = slot_id
		
		# Guardamos el índice modificado en el disco
		var file = FileAccess.open("user://saves/save_index.json", FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(index))
			file.close()
			_safe_log("[%s] El puntero de 'Continue' ahora apunta a: %s" % [ES_NAME_CLASS, slot_id])
			

# ==========================================
# MÉTODOS PARA LA PANTALLA DE ERROR (BACK)
# ==========================================

func has_action_checkpoint() -> bool:
	return save_exists(SLOT_CP_ACTION)

func load_action_checkpoint() -> Dictionary:
	return load_game(SLOT_CP_ACTION)

func has_scene_checkpoint() -> bool:
	return save_exists(SLOT_CP_SCENE)

func load_scene_checkpoint() -> Dictionary:
	return load_game(SLOT_CP_SCENE)

# ==============================================================================
# HOOKS DE INTEGRACIÓN (PARA EL DESARROLLADOR)
# ==============================================================================

## El framework usará este método para recolectar datos en segundo plano
func gather_all_game_data() -> Dictionary:
	var collected_data = {}
	# Aquí es donde pedirás al SceneTree que te dé los datos.
	# Ejemplo: get_tree().call_group("Persist", "save_data", collected_data)
	return collected_data

## Se ejecuta un milisegundo antes de que los datos temporales se escriban en el archivo .ess.
func _on_before_save_hook(game_data: Dictionary, meta_data: Dictionary):
	pass

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
