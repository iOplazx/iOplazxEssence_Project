extends Node

const SETTINGS_FILE = "user://essence_settings.cfg"
var current_window_mode: int = 0

func _ready():
	load_video_settings()

## Cambia el modo y guarda en el archivo
func set_window_mode(mode_index: int):
	current_window_mode = mode_index
	
	if mode_index == 0:
		# Modo Ventana
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif mode_index == 1:
		# Pantalla Completa (Exclusive)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# Forzamos que el V-Sync esté desactivado por defecto para máxima optimización y menor input lag
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	_save_video_settings()

func _save_video_settings():
	var config = ConfigFile.new()
	config.load(SETTINGS_FILE) # Cargamos el existente para no borrar lo de audio
	config.set_value("video", "window_mode", current_window_mode)
	config.save(SETTINGS_FILE)

func load_video_settings():
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		current_window_mode = config.get_value("video", "window_mode", 0)
	
	set_window_mode(current_window_mode)
