extends MarginContainer

@export_category("Tab: Game")
@export var dpd_difficulty: OptionButton
@export var chk_nsfw: CheckButton
@export var slider_text_speed: EssenceRowSlider 

var _pending_changes: bool = false
@export var btn_apply: Button 

func _ready():
	_connect_signals()  # 1. Conectamos los cables
	_setup_texts()      # 2. Ponemos los textos en el idioma correcto
	_sync_values()      # 3. Leemos los valores guardados

# ==========================================
# 1. CONEXIONES ÚNICAS
# ==========================================
func _connect_signals():
	if slider_text_speed and slider_text_speed.slider and not slider_text_speed.slider.drag_ended.is_connected(_on_text_speed_drag_ended):
		slider_text_speed.slider.drag_ended.connect(_on_text_speed_drag_ended)
	
	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)
		
	if dpd_difficulty and not dpd_difficulty.item_selected.is_connected(_on_difficulty_selected):
		dpd_difficulty.item_selected.connect(_on_difficulty_selected)
		
	if chk_nsfw and not chk_nsfw.toggled.is_connected(_on_nsfw_toggled):
		chk_nsfw.toggled.connect(_on_nsfw_toggled)
		
# ==========================================
# 2. ACTUALIZACIÓN DE TEXTOS
# ==========================================
func _setup_texts():
	if dpd_difficulty:
		dpd_difficulty.clear()
		dpd_difficulty.add_item(tr("DIFF_NORMAL"), 0)

	if chk_nsfw:
		chk_nsfw.text = tr("SETTINGS_GAME_NSFW")
		
	if btn_apply:
		btn_apply.text = tr("SETTINGS_VIDEO_SAVE_CHANGE") 
		

# ==========================================
# 3. SINCRONIZACIÓN VISUAL
# ==========================================
func _sync_values():
	# Ahora siempre forzamos a leer de Preferences para que el Reset de Fábrica se vea reflejado
	if dpd_difficulty: dpd_difficulty.select(Preferences.get_setting("game", "difficulty", 0))
	
	if chk_nsfw:
		chk_nsfw.set_pressed_no_signal(Preferences.get_setting("game", "nsfw_enabled", true))
		
	if slider_text_speed and slider_text_speed.slider:
		slider_text_speed.slider.value = Preferences.get_setting("game", "text_speed", 1.0)
	

# ==========================================
# REACCIÓN A EVENTOS GLOBALES
# ==========================================
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_setup_texts()
		_sync_values()
		_pending_changes = false 

# ==========================================
# SEÑALES DE USUARIO
# ==========================================
func _on_difficulty_selected(idx):
	Preferences.set_setting("game", "difficulty", idx)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_text_speed_drag_ended(_changed):
	Preferences.set_setting("game", "text_speed", slider_text_speed.slider.value)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_nsfw_toggled(button_pressed: bool):
	Preferences.set_setting("game", "nsfw_enabled", button_pressed)
	_pending_changes = true 
	AudioManager.play_ui_sfx()
	print("iOplazxEssence: Modo NSFW (Sin censura) = ", button_pressed)
	

func _on_apply_pressed():
	Preferences.save_to_disk()
	_pending_changes = false 
	AudioManager.play_ui_sfx()
	print("iOplazxEssence: Cambios de juego guardados.")

func has_unsaved_changes() -> bool:
	return _pending_changes
