extends Node

const ES_NAME_CLASS = "EssenceDisplayManager"

var current_window_mode: int = 0

func _ready() -> void:
	# Late Binding: Buscamos Preferences de forma segura en la raíz
	var prefs = get_tree().root.get_node_or_null("Preferences")
	
	if is_instance_valid(prefs):
		load_video_settings()
		if prefs.has_signal("settings_restored"):
			prefs.settings_restored.connect(_on_settings_restored)
	else:
		_safe_error(
			"Initialization Error",
			"DisplayManager could not find Preferences node in /root/."
		)

func _on_settings_restored() -> void:
	_safe_log("[%s] Settings restored. Applying factory resolution..." % ES_NAME_CLASS)
	load_video_settings()

## Cambia el modo y guarda en la RAM/Disco
func set_window_mode(mode_index: int) -> void:
	# === PARCHE DE SEGURIDAD: Validación de Rango ===
	if mode_index < 0 or mode_index > 1:
		_safe_error(
			"Invalid Display Mode",
			"Attempted to set window mode index %d. Only 0 (Windowed) and 1 (Fullscreen) are supported." % mode_index
		)
		return # Abortamos para no corromper el guardado con un índice inválido

	current_window_mode = mode_index
	
	# Ejecución de cambios en el motor
	if mode_index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_safe_log("[%s] Switched to Windowed Mode." % ES_NAME_CLASS)
	elif mode_index == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_safe_log("[%s] Switched to Fullscreen Mode." % ES_NAME_CLASS)
	
	# Optimización extrema para tu hardware: V-Sync siempre fuera para ganar FPS
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	_save_video_settings()

func _save_video_settings() -> void:
	_safe_set_pref("video", "window_mode", current_window_mode)
	_safe_save_prefs()

func load_video_settings() -> void:
	# Cargamos con un valor por defecto seguro (0 = Windowed)
	current_window_mode = _safe_get_pref("video", "window_mode", 0)
	
	_safe_log("[%s] Applying video configuration (Mode: %d)." % [ES_NAME_CLASS, current_window_mode])
	
	set_window_mode(current_window_mode)


# ==============================================================================
# WRAPPERS DE SEGURIDAD (Desacoplamiento Total)
# ==============================================================================

func _safe_log(msg: String) -> void:
	var logger = get_tree().root.get_node_or_null("EssenceLogger")
	if is_instance_valid(logger) and logger.has_method("system_info"):
		logger.system_info(msg)
	else:
		print("Fallback Log: ", msg)

func _safe_error(title: String, msg: String) -> void:
	var err_handler = get_tree().root.get_node_or_null("EssenceError")
	if is_instance_valid(err_handler) and err_handler.has_method("report"):
		err_handler.report(title, msg, 1) # 1 = WARNING
	else:
		push_warning("Fallback Error [" + title + "]: " + msg)

func _safe_get_pref(section: String, key: String, default_val: Variant) -> Variant:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("get_setting"):
		return prefs.get_setting(section, key, default_val)
	return default_val

func _safe_set_pref(section: String, key: String, value: Variant) -> void:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("set_setting"):
		prefs.set_setting(section, key, value)

func _safe_save_prefs() -> void:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("save_to_disk"):
		prefs.save_to_disk()