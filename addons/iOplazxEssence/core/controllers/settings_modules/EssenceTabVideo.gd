extends MarginContainer

@export_category("Tab: Video")
@export_subgroup("Display Settings")
@export var dpd_mode: OptionButton

func _ready():
	_setup_video_tab()
	_sync_video()

func _setup_video_tab():
	if dpd_mode:
		dpd_mode.clear()
		# Usamos tr() por si luego quieres traducir "Windowed" y "Fullscreen"
		dpd_mode.add_item(tr("VIDEO_WINDOWED"), 0)
		dpd_mode.add_item(tr("VIDEO_FULLSCREEN"), 1)
		
		dpd_mode.item_selected.connect(_on_window_mode_selected)

func _sync_video():
	if dpd_mode:
		# Le pedimos al DisplayManager que nos diga qué modo tiene activo
		dpd_mode.selected = DisplayManager.current_window_mode

func _on_window_mode_selected(index: int):
	# Ejecutamos el cambio real a través del manager
	DisplayManager.set_window_mode(index)
	
	# Guardamos la preferencia en el archivo global
	Preferences.set_setting("video", "window_mode", index)
	Preferences.save_to_disk()
	
	# Feedback sonoro
	AudioManager.play_ui_sfx()
