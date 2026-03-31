class_name EssenceSaveManager extends Node

# ==========================================
# CONFIGURACIÓN DINÁMICA DEL FRAMEWORK
# ==========================================
var _save_dir: String = "user://saves/"
var _encryption_key: String = "iOplazx_Default_Insecure_Key_!#"
var _save_extension: String = ".ess" 
var _current_version: int = 1

var intent_is_save_mode: bool = false

const INDEX_FILE = "save_index.json"

# Señales para comunicar al UI o al juego que algo terminó
signal on_save_completed(slot_id: String)
signal on_load_completed(slot_id: String, data: Dictionary)
signal on_save_error(slot_id: String, error_msg: String)

func _ready():
	_cargar_llave_secreta()
	_configurar_directorio_usuario()

# ==========================================
# EL PUENTE: CONFIGURACIÓN DESDE EL JUEGO
# ==========================================
func setup_config(extension: String, version: int):
	_save_extension = extension
	_current_version = version
	print("iOplazxEssence: Configuración de guardado actualizada (", extension, ", v", version, ")")

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

func _configurar_directorio_usuario():
	# 0 = Global (user://), 1 = Remoto (junto al .exe)
	var save_location: int = 0 
	
	# Acceso seguro al Autoload 'Preferences'
	if Engine.has_singleton("Preferences") or get_tree().root.has_node("Preferences"):
		var prefs_node = get_node("/root/Preferences")
		# Pedimos el valor "save_location" de la sección "game", con 0 como respaldo
		save_location = prefs_node.get_setting("game", "save_location", 0)
	else:
		push_warning("iOplazxEssence: Autoload 'Preferences' no detectado. Usando modo de guardado Global (0) por defecto.")
	
	# Lógica de asignación de rutas
	# Solo usamos el modo Remoto si save_location es 1 Y NO estamos dentro del editor de Godot
	if save_location == 1 and not OS.has_feature("editor"):
		var exe_folder = OS.get_executable_path().get_base_dir()
		_save_dir = exe_folder.path_join("saves/")
	else:
		_save_dir = "user://saves/"
		
	# Nos aseguramos de que la carpeta exista físicamente en la ruta elegida
	if not DirAccess.dir_exists_absolute(_save_dir):
		DirAccess.make_dir_absolute(_save_dir)

# ==========================================
# RUTAS DINÁMICAS
# ==========================================
func get_file_path(slot_id: String) -> String:
	return _save_dir + slot_id + _save_extension

# ==========================================
# ESCRITURA Y CIFRADO
# ==========================================
func save_game(slot_id: String, user_data: Dictionary, metadata: Dictionary = {}) -> bool:
	var path = get_file_path(slot_id)
	
	var save_package = {
		"essence_meta": {
			"version": _current_version,
			"timestamp": Time.get_unix_time_from_system(),
			"date_string": Time.get_date_string_from_system().replace("T", " ")
		},
		"game_data": user_data
	}
	
	save_package["essence_meta"].merge(metadata, true)
	
	var json_string = JSON.stringify(save_package)
	
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _encryption_key)
	if file == null:
		var err = FileAccess.get_open_error()
		printerr("iOplazxEssence: Error al crear archivo de guardado -> ", err)
		on_save_error.emit(slot_id, "No se pudo escribir en el disco")
		return false
		
	file.store_string(json_string)
	file.close()
	
	# Actualizamos el archivo invisible
	_update_save_index(slot_id, false)
	
	print("iOplazxEssence: Partida guardada con éxito en ", path)
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
		printerr("iOplazxEssence: Error al abrir archivo. ¿Llave incorrecta o archivo corrupto?")
		return {}
		
	var json_string = file.get_as_text()
	file.close()
	
	var parsed_data = JSON.parse_string(json_string)
	if typeof(parsed_data) != TYPE_DICTIONARY:
		printerr("iOplazxEssence: El archivo no tiene un formato válido.")
		return {}
		
	var final_data = _run_migrations(parsed_data)
	
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
			if not dir.current_is_dir() and file_name.ends_with(_save_extension):
				var slot_id = file_name.replace(_save_extension, "")
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
	
	if file_version < _current_version:
		print("iOplazxEssence: Migrando partida de v", file_version, " a v", _current_version)
		meta["version"] = _current_version 
		
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
			return data
			
	return {"latest_save": "", "used_slots": []}

# Actualiza el archivo invisible después de guardar o borrar
func _update_save_index(slot_id: String, is_deleting: bool = false):
	var index = _get_save_index()
	var path = _save_dir + INDEX_FILE
	
	if is_deleting:
		index["used_slots"].erase(slot_id)
		# Si borramos el más reciente, limpiamos el latest_save (o habría que buscar el anterior)
		if index["latest_save"] == slot_id:
			index["latest_save"] = index["used_slots"].back() if index["used_slots"].size() > 0 else ""
	else:
		if not index["used_slots"].has(slot_id):
			index["used_slots"].append(slot_id)
		index["latest_save"] = slot_id # Este es el último guardado real
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(index))
	file.close()

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
	return _get_save_index().get("latest_save", "")
	
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
		printerr("iOplazxEssence: Error al capturar la pantalla.")
		return
		
	# 3. OPTIMIZACIÓN: Achicamos la imagen para no saturar el disco duro
	# 320x180 mantiene la relación de aspecto 16:9 estándar
	img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	
	# 4. Guardamos como .webp en la misma carpeta que el archivo .ess
	var image_path = _save_dir + slot_id + ".webp"
	var err = img.save_webp(image_path)
	
	if err == OK:
		print("iOplazxEssence: Snapshot guardado exitosamente en ", image_path)
	else:
		printerr("iOplazxEssence: Falló el guardado del snapshot. Código: ", err)

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
		img.save_webp(_save_dir + "temp_snap.webp")

# La UI llama a esto cuando el jugador elige un Slot
func commit_save(slot_id: String) -> bool:
	if _temp_game_data.is_empty():
		push_error("iOplazxEssence: No hay datos en caché para guardar.")
		return false
		
	# Reutilizamos tu función original de guardado
	var success = save_game(slot_id, _temp_game_data, _temp_meta_data)
	
	if success:
		# Renombramos la foto temporal para que pertenezca a este slot
		var dir = DirAccess.open(_save_dir)
		if dir and dir.file_exists("temp_snap.webp"):
			# Si ya existía una foto vieja de este slot, la sobrescribe
			if dir.file_exists(slot_id + ".webp"):
				dir.remove(slot_id + ".webp")
			dir.rename("temp_snap.webp", slot_id + ".webp")
			
	return success
