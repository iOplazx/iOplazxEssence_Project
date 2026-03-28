extends MarginContainer

@export_category("Tab: Game")
@export var dpd_difficulty: OptionButton
@export var chk_nsfw: CheckButton
@export var slider_text_speed: EssenceRowSlider 
@export var dpd_autosave: OptionButton
@export var dpd_save_style: OptionButton

var _pending_changes: bool = false
@export var btn_apply: Button # Agrega este botón a tu UI

func _ready():
	# Conectamos el slider una sola vez aquí para que sea eficiente
	if slider_text_speed and slider_text_speed.slider:
		slider_text_speed.slider.drag_ended.connect(func(_changed): _on_text_speed_changed(slider_text_speed.slider.value))
	
	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)
	
	_setup_game_tab()
	_setup_nsfw_toggle()

func _setup_game_tab():
	# 1. Dificultad
	if dpd_difficulty:
		var current = dpd_difficulty.selected
		dpd_difficulty.clear()
		dpd_difficulty.add_item(tr("DIFF_NORMAL"), 0)
		dpd_difficulty.select(current if current != -1 else Preferences.get_setting("game", "difficulty", 0))
		# Solo conectamos la señal si no está conectada (para no duplicar clics)
		if not dpd_difficulty.item_selected.is_connected(_on_difficulty_selected):
			dpd_difficulty.item_selected.connect(_on_difficulty_selected)

	# 2. Autoguardado
	if dpd_autosave:
		var current = dpd_autosave.selected
		dpd_autosave.clear()
		var autosave_options = ["TIME_NEVER", "TIME_5M", "TIME_15M", "TIME_30M", "TIME_1H", "TIME_2H", "TIME_5H", "TIME_12H", "TIME_1D", "TIME_1W"]
		for i in range(autosave_options.size()):
			dpd_autosave.add_item(tr(autosave_options[i]), i)
		dpd_autosave.select(current if current != -1 else Preferences.get_setting("game", "autosave_interval", 0))
		if not dpd_autosave.item_selected.is_connected(_on_autosave_selected):
			dpd_autosave.item_selected.connect(_on_autosave_selected)

	# 3. Estilo de Guardado
	if dpd_save_style:
		var current = dpd_save_style.selected
		dpd_save_style.clear()
		
		# Agregamos los ítems con traducción fresca
		dpd_save_style.add_item(tr("STYLE_GRID"), 0)
		dpd_save_style.add_item(tr("STYLE_LIST"), 1)
		
		# Si ya había algo seleccionado, lo mantenemos. Si no, cargamos de Preferences.
		if current != -1:
			dpd_save_style.select(current)
		else:
			dpd_save_style.select(Preferences.get_setting("game", "save_style", 1)) # 1 = List por defecto
		
		# Evitamos duplicar la conexión de la señal
		if not dpd_save_style.item_selected.is_connected(_on_save_style_selected):
			dpd_save_style.item_selected.connect(_on_save_style_selected)
		
	# 4. Velocidad de Texto (Solo actualizamos el valor visual)
	if slider_text_speed and slider_text_speed.slider:
		# Solo actualizamos el valor, la señal ya está conectada en _ready
		slider_text_speed.slider.value = Preferences.get_setting("game", "text_speed", 1.0)

func _setup_nsfw_toggle():
	if chk_nsfw:
		chk_nsfw.text = tr("SETTINGS_GAME_NSFW")
		
		# Cargamos la preferencia. Por defecto lo pondremos en 'true' (Sin censura)
		# Usamos set_pressed_no_signal para que no dispare el sonido al cargar el menú
		var is_nsfw_enabled = Preferences.get_setting("game", "nsfw_enabled", true)
		chk_nsfw.set_pressed_no_signal(is_nsfw_enabled)
		
		# Conectamos la señal de "toggled" (cuando se activa o desactiva)
		if not chk_nsfw.toggled.is_connected(_on_nsfw_toggled):
			chk_nsfw.toggled.connect(_on_nsfw_toggled)

func _on_nsfw_toggled(button_pressed: bool):
	Preferences.set_setting("game", "nsfw_enabled", button_pressed)
	_pending_changes = true # Levantamos la bandera sucia
	AudioManager.play_ui_sfx()
	
	print("iOplazxEssence: Modo NSFW (Sin censura) = ", button_pressed)

func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_setup_game_tab()
		_setup_nsfw_toggle()

func _on_difficulty_selected(idx):
	Preferences.set_setting("game", "difficulty", idx)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_autosave_selected(idx):
	Preferences.set_setting("game", "autosave_interval", idx)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_save_style_selected(idx):
	Preferences.set_setting("game", "save_style", idx)
	_pending_changes = true
	AudioManager.play_ui_sfx()

func _on_text_speed_changed(val):
	Preferences.set_setting("game", "text_speed", val)
	_pending_changes = true
	AudioManager.play_ui_sfx()
	
func _on_apply_pressed():
	Preferences.save_to_disk()
	_pending_changes = false # Bajamos la bandera
	AudioManager.play_ui_sfx()
	print("iOplazxEssence: Cambios de juego guardados.")

# La función estandarizada para el controlador
func has_unsaved_changes() -> bool:
	return _pending_changes
