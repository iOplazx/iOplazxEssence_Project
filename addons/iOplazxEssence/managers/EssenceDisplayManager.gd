extends Node

var current_window_mode: int = 0

func _ready():
	load_video_settings()
	
	# --- NUEVO: Conectamos la oreja del DisplayManager ---
	Preferences.settings_restored.connect(_on_settings_restored)

# --- NUEVO: La función que reacciona al grito de Preferences ---
func _on_settings_restored():
	print("DisplayManager: Ajustes restaurados. Aplicando resolución de fábrica...")
	load_video_settings() # Re-ejecuta la carga para volver a Fullscreen

## Cambia el modo y guarda en la RAM/Disco
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
	# Usamos el cerebro centralizado
	Preferences.set_setting("video", "window_mode", current_window_mode)
	Preferences.save_to_disk()

func load_video_settings():
	# Pedimos la configuración a la RAM de forma instantánea
	current_window_mode = Preferences.get_setting("video", "window_mode", 0)
	
	set_window_mode(current_window_mode)
