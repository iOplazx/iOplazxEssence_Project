extends MarginContainer

@export_category("Tab: Game")
@export var dpd_difficulty: OptionButton
@export var slider_text_speed: EssenceRowSlider 
@export var dpd_autosave: OptionButton
@export var dpd_save_style: OptionButton

func _ready():
	# Conectamos el slider una sola vez aquí para que sea eficiente
	if slider_text_speed and slider_text_speed.slider:
		slider_text_speed.slider.drag_ended.connect(func(_changed): _on_text_speed_changed(slider_text_speed.slider.value))

	_setup_game_tab()

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

func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		# Al llamar a esta función, los 4 elementos (Dificultad, Autosave, Style y Slider)
		# se redibujarán con el nuevo idioma sin perder la posición del usuario.
		_setup_game_tab()

func _on_difficulty_selected(idx):
	Preferences.set_setting("game", "difficulty", idx)
	Preferences.save_to_disk()
	AudioManager.play_ui_sfx()

func _on_autosave_selected(idx):
	Preferences.set_setting("game", "autosave_interval", idx)
	Preferences.save_to_disk()
	AudioManager.play_ui_sfx()

func _on_save_style_selected(idx):
	Preferences.set_setting("game", "save_style", idx)
	Preferences.save_to_disk()
	AudioManager.play_ui_sfx()

func _on_text_speed_changed(val):
	Preferences.set_setting("game", "text_speed", val)
	Preferences.save_to_disk()
	AudioManager.play_ui_sfx()
