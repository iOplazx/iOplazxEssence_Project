extends Node

var _game_buffer: PackedStringArray = []
var _system_buffer: PackedStringArray = []
var _last_crash_path: String = ""

func _ready():
	_ensure_directories()
	system_info("Essence session started.")
	# Limpiamos el log de la sesión anterior para que no crezca infinitamente
	var file_path = EssencePaths.DIR_SYSTEM + "session.log"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.close() # Abrir en modo WRITE sin escribir nada vacía el archivo

func _ensure_directories():
	for path in [EssencePaths.DIR_SYSTEM, EssencePaths.DIR_ERRORS, EssencePaths.DIR_GAME]:
		if not DirAccess.dir_exists_absolute(path):
			DirAccess.make_dir_recursive_absolute(path)

# ==========================================
# MÉTODOS DE LOGGING
# ==========================================

func system_info(msg: String):
	var line = "[SYSTEM][%s] %s" % [_get_timestamp(), msg]
	_system_buffer.append(line)
	# Si el buffer crece mucho, volcamos a un archivo temporal para liberar RAM
	if _system_buffer.size() > 50:
		flush_system_logs()

func game_log(msg: String):
	var line = "[GAME][%s] %s" % [_get_timestamp(), msg]
	print(line) # Mantenemos el print para que lo veas en la consola de Godot
	_game_buffer.append(line)
	
	if _game_buffer.size() > 50:
		flush_game_logs()
		
func flush_game_logs():
	var file_path = EssencePaths.DIR_GAME + "game_events.log"
	var file = FileAccess.open(file_path, FileAccess.WRITE if not FileAccess.file_exists(file_path) else FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		for line in _game_buffer:
			file.store_line(line)
		file.close()
		_game_buffer.clear()

# ==========================================
# GESTIÓN DE CRASH DUMPS
# ==========================================

func create_crash_report(error_data: Dictionary) -> String:
	var date_str = Time.get_datetime_string_from_system().replace(":", "-")
	var file_path = EssencePaths.DIR_ERRORS + "CRASH_%s.log" % date_str
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_line("=== ESSENCE CRASH REPORT ===")
		file.store_line("Date: " + error_data.get("timestamp", "N/A"))
		file.store_line("Title: " + error_data.get("title", "N/A"))
		file.store_line("Message: " + error_data.get("message", "N/A"))
		file.store_line("\n=== STACK TRACE ===")
		
		var stack = error_data.get("stack", [])
		for frame in stack:
			# Cambiamos "Línea" por "Line"
			file.store_line("[%s] -> %s() (Line %d)" % [frame.get("source", ""), frame.get("function", ""), frame.get("line", 0)])
		
		# Agregamos también lo que estaba haciendo el jugador antes del crash
		file.store_line("\n=== PREVIOUS GAME LOGS ===")
		for line in _game_buffer:
			file.store_line(line)
		
		file.store_line("\n=== PREVIOUS SYSTEM LOGS ===")
		for line in _system_buffer:
			file.store_line(line)
			
		file.close()
		_last_crash_path = file_path
		
		# volcamos a los archivos normales y limpiamos la RAM
		flush_system_logs()
		flush_game_logs()
		
		return file_path
	return ""

func get_last_crash_path() -> String:
	return _last_crash_path

# ==========================================
# UTILIDADES
# ==========================================

func _get_timestamp() -> String:
	return Time.get_time_string_from_system()

func flush_system_logs():
	# Escribe el buffer actual en un archivo de sesión y limpia la memoria
	var file_path = EssencePaths.DIR_SYSTEM + "session.log"
	var file = FileAccess.open(file_path, FileAccess.WRITE if not FileAccess.file_exists(file_path) else FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		for line in _system_buffer:
			file.store_line(line)
		file.close()
		_system_buffer.clear()

func _notification(what):
	# Al cerrar el juego de forma normal, guardamos lo que quede en memoria
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_system_logs()
		flush_game_logs()
