extends MarginContainer

@export_category("Tab: Game")
@export var dpd_autosave: OptionButton
@export var dpd_save_style: OptionButton
@export var dpd_save_location: OptionButton

@export_category("Confirmaciones")
@export var chk_confirm_save: CheckButton
@export var chk_confirm_load: CheckButton
@export var chk_confirm_delete: CheckButton

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
	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)
		
	if dpd_autosave and not dpd_autosave.item_selected.is_connected(_on_autosave_selected):
		dpd_autosave.item_selected.connect(_on_autosave_selected)
		
	if dpd_save_style and not dpd_save_style.item_selected.is_connected(_on_save_style_selected):
		dpd_save_style.item_selected.connect(_on_save_style_selected)
		
	if dpd_save_location and not dpd_save_location.item_selected.is_connected(_on_save_location_selected):
		dpd_save_location.item_selected.connect(_on_save_location_selected)
		
	if chk_confirm_save and not chk_confirm_save.toggled.is_connected(_on_confirm_save_toggled):
		chk_confirm_save.toggled.connect(_on_confirm_save_toggled)
		
	if chk_confirm_load and not chk_confirm_load.toggled.is_connected(_on_confirm_load_toggled):
		chk_confirm_load.toggled.connect(_on_confirm_load_toggled)
		
	if chk_confirm_delete and not chk_confirm_delete.toggled.is_connected(_on_confirm_delete_toggled):
		chk_confirm_delete.toggled.connect(_on_confirm_delete_toggled)

# ==========================================
# 2. ACTUALIZACIÓN DE TEXTOS
# ==========================================
func _setup_texts():
	if dpd_autosave:
		dpd_autosave.clear()
		var autosave_options = ["TIME_NEVER", "TIME_5M", "TIME_15M", "TIME_30M", "TIME_1H", "TIME_2H", "TIME_5H", "TIME_12H", "TIME_1D", "TIME_1W"]
		for i in range(autosave_options.size()):
			dpd_autosave.add_item(tr(autosave_options[i]), i)

	if dpd_save_style:
		dpd_save_style.clear()
		dpd_save_style.add_item(tr("STYLE_GRID"), 0)
		dpd_save_style.add_item(tr("STYLE_LIST"), 1)
		
	if btn_apply:
		btn_apply.text = tr("SETTINGS_VIDEO_SAVE_CHANGE") 
		
	if dpd_save_location:
		dpd_save_location.clear()
		dpd_save_location.add_item(tr("SETTINGS_SAVE_LOC_GLOBAL"), 0)
		dpd_save_location.add_item(tr("SETTINGS_SAVE_LOC_VERSION"), 1)
		
	if chk_confirm_save: chk_confirm_save.text = tr("SETTINGS_CONFIRM_SAVE")
	if chk_confirm_load: chk_confirm_load.text = tr("SETTINGS_CONFIRM_LOAD")
	if chk_confirm_delete: chk_confirm_delete.text = tr("SETTINGS_CONFIRM_DELETE")

# ==========================================
# 3. SINCRONIZACIÓN VISUAL
# ==========================================
func _sync_values():
	if dpd_autosave: dpd_autosave.select(Preferences.get_setting("game", "autosave_interval", 0))
	if dpd_save_style: dpd_save_style.select(Preferences.get_setting("game", "save_style", 1))
	
	if dpd_save_location:
		dpd_save_location.select(Preferences.get_setting("game", "save_location", 0))
	
	if chk_confirm_save:
		chk_confirm_save.set_pressed_no_signal(Preferences.get_setting("game", "confirm_save", true))
	if chk_confirm_load:
		chk_confirm_load.set_pressed_no_signal(Preferences.get_setting("game", "confirm_load", true))
	if chk_confirm_delete:
		chk_confirm_delete.set_pressed_no_signal(Preferences.get_setting("game", "confirm_delete", true))


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

func _on_autosave_selected(idx):
	Preferences.set_setting("game", "autosave_interval", idx)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_save_style_selected(idx):
	Preferences.set_setting("game", "save_style", idx)
	_pending_changes = true
	AudioManager.play_ui_sfx()
	
func _on_save_location_selected(idx):
	Preferences.set_setting("game", "save_location", idx)
	_pending_changes = true
	AudioManager.play_ui_sfx()
	
func _on_confirm_save_toggled(button_pressed: bool):
	Preferences.set_setting("game", "confirm_save", button_pressed)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_confirm_load_toggled(button_pressed: bool):
	Preferences.set_setting("game", "confirm_load", button_pressed)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_confirm_delete_toggled(button_pressed: bool):
	Preferences.set_setting("game", "confirm_delete", button_pressed)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_apply_pressed():
	Preferences.save_to_disk()
	_pending_changes = false 
	AudioManager.play_ui_sfx()
	print("iOplazxEssence: Cambios de juego guardados.")

func has_unsaved_changes() -> bool:
	return _pending_changes
