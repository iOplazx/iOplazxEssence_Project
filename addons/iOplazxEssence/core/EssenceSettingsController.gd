class_name EssenceSettingsController extends Control

@export_category("iOplazx Settings UI")

@export_group("Global Connections")
@export var btn_return: Button

# ==========================================
# PESTAÑA JUEGO
# ==========================================
@export_group("Tab: Game")
@export var dpd_difficulty: OptionButton
@export var slider_text_speed: Control 
@export var dpd_autosave: OptionButton
@export var dpd_save_style: OptionButton

# ==========================================
# PESTAÑA VIDEO
# ==========================================
@export_group("Tab: Video")
@export_subgroup("Display Settings")
@export var dpdMode: OptionButton

# ==========================================
# PESTAÑA AUDIO
# ==========================================
@export_group("Tab: Audio")
@export_subgroup("Volume Sliders")
@export var row_master_volume: EssenceRowSlider 
@export var row_background_music: EssenceRowSlider
@export var row_sfx_volume: EssenceRowSlider
@export var row_ui_volume: EssenceRowSlider
@export var row_voices_volume: EssenceRowSlider

@export_subgroup("Audio Features")
@export var chkMuteFocusLoss: CheckBox

@export_subgroup("UI Theme Preview")
@export var dropdown_ui_theme: OptionButton
@export var btn_preview: TextureButton
@export var preview_player: AudioStreamPlayer

# ==========================================
# PESTAÑA LENGUAJE
# ==========================================
@export_group("Tab: Language")
@export_subgroup("UI Connections")
@export var list_languages: VBoxContainer 
@export var btn_reimport_langs: Button

@export_subgroup("Prefabs")
@export var language_card_prefab: PackedScene
@export var info_panel_prefab: PackedScene

# Variables privadas
var _tex_play: Texture2D
var _tex_pause: Texture2D

func _ready():
	_load_icons()
	_setup_sliders_range()
	_setup_theme_dropdown()
	_setup_extra_settings()
	_setup_game_tab() # Inicializa la pestaña Game
	_connect_signals()
	_sync_with_managers()
	_populate_languages()
	
	if btn_reimport_langs:
		btn_reimport_langs.pressed.connect(_on_reimport_langs_pressed)

func _load_icons():
	_tex_play = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_PLAY)
	_tex_pause = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_PAUSE)

# ==========================================
# SETUP DE UI Y SEÑALES
# ==========================================

func _setup_sliders_range():
	var rows = [row_master_volume, row_background_music, row_sfx_volume, row_ui_volume, row_voices_volume]
	for r in rows:
		if r and r.slider:
			r.slider.min_value = 0.0
			r.slider.max_value = 1.0
			r.slider.step = 0.01

func _connect_signals():
	if btn_return:
		btn_return.pressed.connect(SceneManager.go_back)
		
	_connect_audio_row(row_master_volume, "Master")
	_connect_audio_row(row_background_music, "Music")
	_connect_audio_row(row_sfx_volume, "SFX")
	_connect_audio_row(row_ui_volume, "UI", true)
	_connect_audio_row(row_voices_volume, "Voices")

func _connect_audio_row(row: EssenceRowSlider, bus_name: String, play_test: bool = false):
	if row and row.slider:
		row.slider.value_changed.connect(func(val): AudioManager.set_bus_volume(bus_name, val))
		if play_test:
			row.slider.drag_ended.connect(func(_changed): _save_all_settings(); AudioManager.play_ui_sfx())
		else:
			row.slider.drag_ended.connect(func(_changed): _save_all_settings())

# ==========================================
# SETUP PESTAÑA GAME
# ==========================================
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
		
	# 4. Velocidad de Texto (0.0 a 1.0)
	if slider_text_speed and slider_text_speed.slider:
		slider_text_speed.slider.min_value = 0.0
		slider_text_speed.slider.max_value = 1.0
		slider_text_speed.slider.step = 0.05
		slider_text_speed.slider.value = Preferences.get_setting("game", "text_speed", 0.5)
		
		# Guardamos solo cuando suelta el click para no saturar el disco
		slider_text_speed.slider.drag_ended.connect(func(_changed): _on_text_speed_changed(slider_text_speed.slider.value))

# ==========================================
# LÓGICA DEL TEMA DE INTERFAZ
# ==========================================

func _setup_theme_dropdown():
	if not dropdown_ui_theme or not btn_preview: return
	
	dropdown_ui_theme.clear()
	dropdown_ui_theme.add_item("Sci-Fi (Space)")
	dropdown_ui_theme.add_item("Burbuja (Bubble)")
	dropdown_ui_theme.add_item("Silencio") 
	
	dropdown_ui_theme.item_selected.connect(_on_theme_selected)
	btn_preview.pressed.connect(_on_preview_pressed)
	
	if preview_player:
		preview_player.finished.connect(_on_preview_finished)
		
	btn_preview.texture_normal = _tex_play

func _on_theme_selected(index: int):
	AudioManager.set_ui_theme(index)
	if preview_player and preview_player.playing:
		preview_player.stop()
		_on_preview_finished()
		
	if index != 2: 
		_on_preview_pressed()

func _on_preview_pressed():
	if not preview_player: return
	
	if preview_player.playing:
		preview_player.stop()
		_on_preview_finished()
		return
		
	var current_theme = AudioManager.current_ui_theme
	if current_theme == 2: return 
		
	if current_theme == 0:
		preview_player.stream = AudioManager.get_cached_audio("ui_space")
	elif current_theme == 1:
		preview_player.stream = AudioManager.get_cached_audio("ui_bubble")
		
	btn_preview.texture_normal = _tex_pause
	preview_player.play()

func _on_preview_finished():
	if btn_preview:
		btn_preview.texture_normal = _tex_play

# ==========================================
# LÓGICA DE VIDEO Y AUDIO EXTRA
# ==========================================

func _setup_extra_settings():
	if dpdMode:
		dpdMode.clear()
		dpdMode.add_item("Modo Ventana")
		dpdMode.add_item("Pantalla Completa")
		dpdMode.item_selected.connect(_on_window_mode_selected)
		
	if chkMuteFocusLoss:
		chkMuteFocusLoss.toggled.connect(_on_mute_focus_toggled)

func _on_window_mode_selected(index: int):
	DisplayManager.set_window_mode(index)
	AudioManager.play_ui_sfx() 

func _on_mute_focus_toggled(toggled_on: bool):
	AudioManager.mute_on_focus_loss = toggled_on
	_save_all_settings()
	AudioManager.play_ui_sfx()

# ==========================================
# SINCRONIZACIÓN GLOBAL Y GUARDADO
# ==========================================

func _save_all_settings():
	var vol_master = row_master_volume.slider.value if row_master_volume and row_master_volume.slider else 1.0
	var vol_music = row_background_music.slider.value if row_background_music and row_background_music.slider else 1.0
	var vol_sfx = row_sfx_volume.slider.value if row_sfx_volume and row_sfx_volume.slider else 1.0
	var vol_ui = row_ui_volume.slider.value if row_ui_volume and row_ui_volume.slider else 1.0
	var vol_voices = row_voices_volume.slider.value if row_voices_volume and row_voices_volume.slider else 1.0
	
	AudioManager.save_audio_settings(vol_master, vol_music, vol_sfx, vol_ui, vol_voices)

func _sync_with_managers():
	var saved_vols = AudioManager.load_audio_settings()
	if row_master_volume and row_master_volume.slider: row_master_volume.slider.value = saved_vols["Master"]
	if row_background_music and row_background_music.slider: row_background_music.slider.value = saved_vols["Music"]
	if row_sfx_volume and row_sfx_volume.slider: row_sfx_volume.slider.value = saved_vols["SFX"]
	if row_ui_volume and row_ui_volume.slider: row_ui_volume.slider.value = saved_vols["UI"]
	if row_voices_volume and row_voices_volume.slider: row_voices_volume.slider.value = saved_vols["Voices"]
	
	if dropdown_ui_theme: dropdown_ui_theme.selected = AudioManager.current_ui_theme
	if dpdMode: dpdMode.selected = DisplayManager.current_window_mode
		
	if chkMuteFocusLoss:
		chkMuteFocusLoss.set_block_signals(true)
		chkMuteFocusLoss.button_pressed = AudioManager.mute_on_focus_loss
		chkMuteFocusLoss.set_block_signals(false)

# ==========================================
# LÓGICA DE IDIOMAS Y TARJETAS
# ==========================================

func _populate_languages():
	if not list_languages or not language_card_prefab: return
		
	for child in list_languages.get_children():
		child.queue_free()
		
	var real_data = LanguageManager.get_language_list()
	var current_locale = TranslationServer.get_locale() 
	
	for data in real_data:
		var card: EssenceLanguageCard = language_card_prefab.instantiate()
		list_languages.add_child(card)
		card.setup_card(data, current_locale)
		card.on_apply_requested.connect(_on_language_apply)
		card.on_info_requested.connect(_on_language_info)

func _on_language_apply(folder_code: String):
	TranslationServer.set_locale(folder_code) 
	AudioManager.play_ui_sfx()
	LanguageManager.save_language_preference(folder_code)
	
	var current_locale = TranslationServer.get_locale()
	for card in list_languages.get_children():
		if card.has_method("refresh_state"):
			card.refresh_state(current_locale)

func _on_language_info(data: Dictionary):
	if not info_panel_prefab: return
	var panel = info_panel_prefab.instantiate()
	add_child(panel) 
	if panel.has_method("setup"):
		panel.setup(data)
		
func _on_reimport_langs_pressed():
	AudioManager.play_ui_sfx()
	LanguageManager.scan_all_languages()
	LanguageManager.inject_translations()
	_populate_languages()

# ==========================================
# RECEPTORES DE SEÑALES (PESTAÑA GAME)
# ==========================================

func _on_difficulty_selected(index: int):
	AudioManager.play_ui_sfx()
	Preferences.set_setting("game", "difficulty", index)
	Preferences.save_to_disk()

func _on_autosave_selected(index: int):
	AudioManager.play_ui_sfx()
	Preferences.set_setting("game", "autosave_interval", index)
	Preferences.save_to_disk()

func _on_save_style_selected(index: int):
	AudioManager.play_ui_sfx()
	Preferences.set_setting("game", "save_style", index)
	Preferences.save_to_disk()

func _on_text_speed_changed(value: float):
	Preferences.set_setting("game", "text_speed", value)
	Preferences.save_to_disk()
	AudioManager.play_ui_sfx()
