extends MarginContainer

@export_category("Tab: Video")
@export_subgroup("Display Settings")
@export var dpd_mode: OptionButton
@export var btn_apply: Button 

# Variable para recordar qué eligió el usuario antes de guardarlo
var _unsaved_mode: int = -1 

func _ready():
	_setup_video_tab()
	_sync_video()
	
	# Conectamos el dropdown (solo cambia la variable temporal)
	if dpd_mode and not dpd_mode.item_selected.is_connected(_on_mode_changed):
		dpd_mode.item_selected.connect(_on_mode_changed)
		
	# Conectamos el nuevo botón de aplicar
	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)
	
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_setup_video_tab()
		_sync_video()

func _setup_video_tab():
	if dpd_mode:
		var current_selection = dpd_mode.selected 
		dpd_mode.clear() 
		dpd_mode.add_item(tr("SETTINGS_VIDEO_WINDOWED"), 0)
		dpd_mode.add_item(tr("SETTINGS_VIDEO_FULLSCREEN"), 1)
		dpd_mode.select(current_selection)
		
	# Traducimos el botón de aplicar
	if btn_apply:
		btn_apply.text = tr("SETTINGS_VIDEO_SAVE_CHANGE")

func _sync_video():
	if dpd_mode:
		dpd_mode.selected = DisplayManager.current_window_mode
		_unsaved_mode = dpd_mode.selected # Sincronizamos la variable temporal

func _on_mode_changed(index: int):
	# Solo guardamos la intención, NO aplicamos el cambio aún
	_unsaved_mode = index
	AudioManager.play_ui_sfx()

func _on_apply_pressed():
	# Si realmente cambió algo, entonces sí ejecutamos el trabajo pesado
	if _unsaved_mode != DisplayManager.current_window_mode:
		DisplayManager.set_window_mode(_unsaved_mode)
		Preferences.set_setting("video", "window_mode", _unsaved_mode)
		Preferences.save_to_disk()
		print("iOplazxEssence: Cambios de video aplicados y guardados.")
		
	AudioManager.play_ui_sfx()

# Le dice al menú si esta pestaña tiene algo pendiente
func has_unsaved_changes() -> bool:
	var is_dirty = (_unsaved_mode != -1 and _unsaved_mode != DisplayManager.current_window_mode)
	print("Video Tab - Unsaved: ", _unsaved_mode, " | Current: ", DisplayManager.current_window_mode, " | Pendiente: ", is_dirty)
	return is_dirty
