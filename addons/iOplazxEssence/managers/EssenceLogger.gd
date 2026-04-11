extends Node

var _game_buffer: PackedStringArray = []
var _system_buffer: PackedStringArray = []
var _last_crash_path: String = ""

func _ready():
	_ensure_directories()
	
	# Clear previous session logs to prevent infinite file growth
	_clear_file(EssencePaths.DIR_SYSTEM + "session.log")
	_clear_file(EssencePaths.DIR_GAME + "game_events.log")
	
	system_info("Essence session started.")

func _clear_file(file_path: String):
	# Opening in WRITE mode without storing anything truncates/empties the file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.close()

func _ensure_directories():
	for path in [EssencePaths.DIR_SYSTEM, EssencePaths.DIR_ERRORS, EssencePaths.DIR_GAME]:
		if not DirAccess.dir_exists_absolute(path):
			DirAccess.make_dir_recursive_absolute(path)

# ==========================================
# LOGGING METHODS
# ==========================================

func system_info(msg: String):
	var line = "[SYSTEM][%s] %s" % [_get_timestamp(), msg]
	_system_buffer.append(line)
	
	# If the buffer grows too much, flush to disk to free RAM
	if _system_buffer.size() > 50:
		flush_system_logs()

func game_log(msg: String):
	var line = "[GAME][%s] %s" % [_get_timestamp(), msg]
	print(line) # Keep print for real-time Editor debugging
	_game_buffer.append(line)
	
	if _game_buffer.size() > 50:
		flush_game_logs()

# ==========================================
# DISK WRITING (FLUSH)
# ==========================================
		
func flush_system_logs():
	if _system_buffer.is_empty(): return
	var file_path = EssencePaths.DIR_SYSTEM + "session.log"
	_safe_append(file_path, _system_buffer)

func flush_game_logs():
	if _game_buffer.is_empty(): return
	var file_path = EssencePaths.DIR_GAME + "game_events.log"
	_safe_append(file_path, _game_buffer)

# Método blindado contra el bug de los 0 bytes de Godot
func _safe_append(path: String, buffer: PackedStringArray):
	var previous_content = ""
	
	# 1. Leemos el texto anterior (si existe y no está vacío)
	if FileAccess.file_exists(path):
		var reader = FileAccess.open(path, FileAccess.READ)
		if reader:
			previous_content = reader.get_as_text()
			reader.close()
			
	# 2. Abrimos en modo WRITE (Esto es 100% seguro y nunca falla)
	var writer = FileAccess.open(path, FileAccess.WRITE)
	if writer:
		# Si ya había texto, lo volvemos a poner primero
		if previous_content != "":
			writer.store_string(previous_content)
			# Nos aseguramos de que haya un salto de línea antes de meter lo nuevo
			if not previous_content.ends_with("\n"):
				writer.store_string("\n")
		
		# Escribimos todo lo que estaba atrapado en la RAM
		for line in buffer:
			writer.store_line(line)
			
		writer.close()
		
	# 3. Limpiamos la RAM
	buffer.clear()

# ==========================================
# CRASH DUMPS MANAGEMENT
# ==========================================

func create_crash_report(error_data: Dictionary) -> String:
	var date_str = Time.get_datetime_string_from_system().replace(":", "-")
	var file_path = EssencePaths.DIR_ERRORS + "CRASH_%s.log" % date_str
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_line("=== ESSENCE CRASH REPORT ===")
		file.store_line("Date: %s" % error_data.get("timestamp", "N/A"))
		file.store_line("Title: %s" % error_data.get("title", "N/A"))
		file.store_line("Message: %s" % error_data.get("message", "N/A"))
		file.store_line("\n=== STACK TRACE ===")
		
		var stack = error_data.get("stack", [])
		for frame in stack:
			file.store_line("[%s] -> %s() (Line %d)" % [frame.get("source", ""), frame.get("function", ""), frame.get("line", 0)])
		
		file.store_line("\n=== PREVIOUS GAME LOGS ===")
		for line in _game_buffer:
			file.store_line(line)
		
		file.store_line("\n=== PREVIOUS SYSTEM LOGS ===")
		for line in _system_buffer:
			file.store_line(line)
			
		file.close()
		_last_crash_path = file_path
		
		# Flush to normal files and clean RAM
		flush_system_logs()
		flush_game_logs()
		
		return file_path
	return ""

func get_last_crash_path() -> String:
	return _last_crash_path

# ==========================================
# UTILITIES & ENGINE HOOKS
# ==========================================

func _get_timestamp() -> String:
	return Time.get_time_string_from_system()

func _notification(what):
	# Hook into OS close request to save remaining buffer
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_system_logs()
		flush_game_logs()
