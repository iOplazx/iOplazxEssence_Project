extends MarginContainer

@export_category("Tab: Game")
@export var dpd_difficulty: OptionButton
@export var slider_text_speed: EssenceRowSlider 
@export var dpd_autosave: OptionButton
@export var dpd_save_style: OptionButton

func _ready():
	_setup_game_tab()

func _setup_game_tab():
	# 1. Dificultad
	if dpd_difficulty:
		dpd_difficulty.clear()
		dpd_difficulty.add_item(tr("DIFF_NORMAL"), 0)
		dpd_difficulty.select(Preferences.get_setting("game", "difficulty", 0))
		dpd_difficulty.item_selected.connect(_on_difficulty_selected)

	# 2. Autoguardado
	if dpd_autosave:
		dpd_autosave.clear()
		var autosave_options = ["TIME_NEVER", "TIME_5M", "TIME_15M", "TIME_30M", "TIME_1H", "TIME_2H", "TIME_5H", "TIME_12H", "TIME_1D", "TIME_1W"]
		for i in range(autosave_options.size()):
			dpd_autosave.add_item(tr(autosave_options[i]), i)
		dpd_autosave.select(Preferences.get_setting("game", "autosave_interval", 0))
		dpd_autosave.item_selected.connect(_on_autosave_selected)

	# 3. Estilo de Guardado
	if dpd_save_style:
		dpd_save_style.clear()
		dpd_save_style.add_item(tr("STYLE_GRID"), 0)
		dpd_save_style.add_item(tr("STYLE_LIST"), 1)
		dpd_save_style.select(Preferences.get_setting("game", "save_style", 1)) 
		dpd_save_style.item_selected.connect(_on_save_style_selected)
		
	# 4. Velocidad de Texto
	if slider_text_speed and slider_text_speed.slider:
		slider_text_speed.slider.value = Preferences.get_setting("game", "text_speed", 1.0)
		slider_text_speed.slider.drag_ended.connect(func(_changed): _on_text_speed_changed(slider_text_speed.slider.value))

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
