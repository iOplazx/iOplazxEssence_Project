extends Node
const ES_NAME_CLASS = "EssenceDisplayManager"

var current_window_mode: int = 0

func _ready():
	# Verificamos si Preferences está listo antes de cargar
	if is_instance_valid(Preferences):
		load_video_settings()
		Preferences.settings_restored.connect(_on_settings_restored)
	else:
		EssenceError.report(
			"Initialization Error",
			"DisplayManager could not find Preferences Autoload.",
			EssenceError.Severity.CRITICAL
		)

func _on_settings_restored():
	var log_msg = "[%s/_on_settings_restored] Settings restored. Applying factory resolution..." % ES_NAME_CLASS
	EssenceLogger.system_info(log_msg)
	load_video_settings()

## Cambia el modo y guarda en la RAM/Disco
func set_window_mode(mode_index: int):
	# === PARCHE DE SEGURIDAD: Validación de Rango ===
	if mode_index < 0 or mode_index > 1:
		EssenceError.report(
			"Invalid Display Mode",
			"Attempted to set window mode index %d. Only 0 (Windowed) and 1 (Fullscreen) are supported." % mode_index,
			EssenceError.Severity.WARNING
		)
		return # Abortamos para no corromper el guardado con un índice inválido

	current_window_mode = mode_index
	
	# Ejecución de cambios en el motor
	if mode_index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		EssenceLogger.system_info("[%s/set_window_mode] Switched to Windowed Mode." % ES_NAME_CLASS)
	elif mode_index == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		EssenceLogger.system_info("[%s/set_window_mode] Switched to Fullscreen Mode." % ES_NAME_CLASS)
	
	# Optimización extrema para tu hardware: V-Sync siempre fuera para ganar FPS
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	_save_video_settings()

func _save_video_settings():
	if is_instance_valid(Preferences):
		Preferences.set_setting("video", "window_mode", current_window_mode)
		Preferences.save_to_disk()
	else:
		# Si llegamos aquí sin Preferences, es un error grave de flujo
		EssenceLogger.system_info("[%s/_save_video_settings] FAILED: Preferences not available." % ES_NAME_CLASS)

func load_video_settings():
	# Cargamos con un valor por defecto seguro (0 = Windowed)
	current_window_mode = Preferences.get_setting("video", "window_mode", 0)
	
	var log_msg = "[%s/load_video_settings] Applying video configuration (Mode: %d)." % [ES_NAME_CLASS, current_window_mode]
	EssenceLogger.system_info(log_msg)
	
	set_window_mode(current_window_mode)