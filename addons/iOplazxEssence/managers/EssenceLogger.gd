extends Node


var _system_buffer: PackedStringArray = []
var _last_crash_path: String = ""

func _ready():
	_ensure_directories()
	system_info("Sesión de Essence iniciada.")

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
	# Para que el desarrollador guarde sus propios eventos
	var line = "[GAME][%s] %s" % [_get_timestamp(), msg]
	print(line) # Opcional: mantener el print en consola solo para game_log

# ==========================================
# GESTIÓN DE CRASH DUMPS
# ==========================================

func create_crash_report(error_data: Dictionary) -> String:
	var date_str = Time.get_datetime_string_from_system().replace(":", "-")
	var file_path = EssencePaths.DIR_ERRORS + "CRASH_%s.log" % date_str
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_line("=== ESSENCE CRASH REPORT ===")
		file.store_line("Fecha: " + error_data.get("timestamp", "N/A"))
		file.store_line("Título: " + error_data.get("title", "N/A"))
		file.store_line("Mensaje: " + error_data.get("message", "N/A"))
		file.store_line("\n=== STACK TRACE ===")
		
		var stack = error_data.get("stack", [])
		for frame in stack:
			file.store_line("[%s] -> %s() (Línea %d)" % [frame.get("source", ""), frame.get("function", ""), frame.get("line", 0)])
		
		file.store_line("\n=== LOGS DE SISTEMA PREVIOS ===")
		for line in _system_buffer:
			file.store_line(line)
			
		file.close()
		_last_crash_path = file_path
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
