class_name EssenceTabGame extends MarginContainer

const ES_NAME_CLASS = "EssenceTabGame"

@export_category("Tab: Game")
@export var dpd_difficulty: OptionButton
@export var chk_nsfw: CheckButton
@export var slider_text_speed: EssenceRowSlider 

@export_category("Global Action")
@export var btn_apply: Button 

var _pending_changes: bool = false

func _ready() -> void:
	if _validate_requirements():
		_connect_signals() 
		_setup_texts() 
		_sync_values()
		EssenceLogger.system_info("[%s] Game settings tab initialized." % ES_NAME_CLASS)

## Inspector validation
func _validate_requirements() -> bool:
	# Verificamos los nodos críticos
	var nodes = {
		"Difficulty Dropdown": dpd_difficulty,
		"NSFW Toggle": chk_nsfw,
		"Text Speed Slider": slider_text_speed,
		"Apply Button": btn_apply
	}
	
	for node_name in nodes:
		if nodes[node_name] == null:
			EssenceError.report(
				"Missing UI Reference",
				"Node '%s' is not assigned in the Inspector for %s." % [node_name, name],
				EssenceError.Severity.CRITICAL
			)
			return false
			
	# Verificación del Autoload de Preferencias
	if not is_instance_valid(Preferences):
		EssenceError.report("Missing Autoload", "Preferences manager not found in SceneTree.", EssenceError.Severity.CRITICAL)
		return false
		
	return true

# ==========================================
# 1. CONEXIONES ÚNICAS
# ==========================================
func _connect_signals() -> void:
	# Text Speed
	if slider_text_speed and slider_text_speed.slider:
		if not slider_text_speed.slider.drag_ended.is_connected(_on_text_speed_drag_ended):
			slider_text_speed.slider.drag_ended.connect(_on_text_speed_drag_ended)
	
	# Botón Aplicar
	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)
		
	# Dificultad
	if dpd_difficulty and not dpd_difficulty.item_selected.is_connected(_on_difficulty_selected):
		dpd_difficulty.item_selected.connect(_on_difficulty_selected)
		
	# NSFW Check
	if chk_nsfw and not chk_nsfw.toggled.is_connected(_on_nsfw_toggled):
		chk_nsfw.toggled.connect(_on_nsfw_toggled)

# ==========================================
# 2. ACTUALIZACIÓN DE TEXTOS
# ==========================================
func _setup_texts() -> void:
	if dpd_difficulty:
		var current = dpd_difficulty.selected
		dpd_difficulty.clear()
		# Sugerencia: Puedes expandir esto con más dificultades en tu CSV
		dpd_difficulty.add_item(tr("DIFF_NORMAL"), 0)
		if current != -1: dpd_difficulty.select(current)

	if chk_nsfw:
		chk_nsfw.text = tr("SETTINGS_GAME_NSFW")
		
	if btn_apply:
		btn_apply.text = tr("SETTINGS_VIDEO_SAVE_CHANGE") 

# ==========================================
# 3. SINCRONIZACIÓN VISUAL
# ==========================================
func _sync_values() -> void:
	# Sincronizamos desde el Autoload Preferences (Caché en RAM)
	if dpd_difficulty: 
		dpd_difficulty.select(Preferences.get_setting("game", "difficulty", 0))
	
	if chk_nsfw:
		chk_nsfw.set_pressed_no_signal(Preferences.get_setting("game", "nsfw_enabled", true))
		
	if slider_text_speed and slider_text_speed.slider:
		slider_text_speed.slider.value = Preferences.get_setting("game", "text_speed", 1.0)
	
	_pending_changes = false

# ==========================================
# REACCIÓN A EVENTOS GLOBALES
# ==========================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_setup_texts()
		_sync_values()

# ==========================================
# SEÑALES DE USUARIO
# ==========================================
func _on_difficulty_selected(idx: int) -> void:
	Preferences.set_setting("game", "difficulty", idx)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_text_speed_drag_ended(_changed: bool) -> void:
	Preferences.set_setting("game", "text_speed", slider_text_speed.slider.value)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_nsfw_toggled(button_pressed: bool) -> void:
	Preferences.set_setting("game", "nsfw_enabled", button_pressed)
	_pending_changes = true 
	AudioManager.play_ui_sfx()
	EssenceLogger.system_info("[%s] NSFW Mode toggled: %s" % [ES_NAME_CLASS, str(button_pressed)])

func _on_apply_pressed() -> void:
	Preferences.save_to_disk()
	_pending_changes = false 
	AudioManager.play_ui_sfx()
	EssenceLogger.system_info("[%s] Game preferences committed to disk." % ES_NAME_CLASS)

func has_unsaved_changes() -> bool:
	return _pending_changes