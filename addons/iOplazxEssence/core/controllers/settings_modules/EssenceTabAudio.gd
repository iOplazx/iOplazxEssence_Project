extends MarginContainer

@export_category("Tab: Audio")
@export_subgroup("Volume Sliders")
@export var row_master: EssenceRowSlider 
@export var row_music: EssenceRowSlider
@export var row_sfx: EssenceRowSlider
@export var row_ui: EssenceRowSlider
@export var row_voices: EssenceRowSlider

@export_subgroup("Audio Features")
@export var chk_mute_focus: CheckBox

@export_subgroup("UI Theme Preview")
@export var dpd_theme: OptionButton
@export var btn_preview: TextureButton
@export var preview_player: AudioStreamPlayer

var _tex_play: Texture2D
var _tex_pause: Texture2D

func _ready():
	_tex_play = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_PLAY)
	_tex_pause = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_PAUSE)
	
	_connect_signals() # <--- 1. Conectamos los cables una sola vez
	_setup_audio_tab() # <--- 2. Llenamos los textos
	_sync_audio()      # <--- 3. Ajustamos las posiciones visuales

func _setup_audio_tab():
	if dpd_theme:
		var current = dpd_theme.selected
		dpd_theme.clear()
		# Opcional: Si en el futuro agregas esto al CSV, puedes poner tr("THEME_SPACE")
		dpd_theme.add_item("Sci-Fi (Space)") 
		dpd_theme.add_item("Bubble Effect")
		dpd_theme.add_item("Silencio")
		
		# Restauramos lo que estaba seleccionado para que no se regrese al índice 0
		if current != -1: 
			dpd_theme.select(current)
			
	if btn_preview:
		btn_preview.texture_normal = _tex_play

func _connect_row(row, bus_name, test = false):
	if row and row.slider:
		row.slider.value_changed.connect(func(v): AudioManager.set_bus_volume(bus_name, v))
		row.slider.drag_ended.connect(func(_c): _save_audio(); if test: AudioManager.play_ui_sfx())

func _on_mute_focus_toggled(on):
	AudioManager.mute_on_focus_loss = on
	_save_audio()
	AudioManager.play_ui_sfx()

func _save_audio():
	AudioManager.save_audio_settings(
		row_master.slider.value, row_music.slider.value, 
		row_sfx.slider.value, row_ui.slider.value, row_voices.slider.value
	)

func _sync_audio():
	var v = AudioManager.load_audio_settings()
	row_master.slider.value = v["Master"]
	row_music.slider.value = v["Music"]
	row_sfx.slider.value = v["SFX"]
	row_ui.slider.value = v["UI"]
	row_voices.slider.value = v["Voices"]
	
	if dpd_theme: dpd_theme.selected = AudioManager.current_ui_theme
	if chk_mute_focus:
		chk_mute_focus.set_block_signals(true)
		chk_mute_focus.button_pressed = AudioManager.mute_on_focus_loss
		chk_mute_focus.set_block_signals(false)

func _on_theme_selected(idx):
	AudioManager.set_ui_theme(idx)
	if preview_player.playing: preview_player.stop()

func _on_preview_pressed():
	if preview_player.playing:
		preview_player.stop()
		btn_preview.texture_normal = _tex_play
		return
		
	var theme = AudioManager.current_ui_theme
	if theme == 2: return
	
	preview_player.stream = AudioManager.get_cached_audio("ui_space" if theme == 0 else "ui_bubble")
	btn_preview.texture_normal = _tex_pause
	preview_player.play()
	
# ==========================================
# CONEXIONES ÚNICAS (Anti-Fugas de Memoria)
# ==========================================
func _connect_signals():
	# Conectamos las filas (sus lambdas solo se crearán 1 vez)
	_connect_row(row_master, "Master")
	_connect_row(row_music, "Music")
	_connect_row(row_sfx, "SFX")
	_connect_row(row_ui, "UI", true)
	_connect_row(row_voices, "Voices")
	
	if chk_mute_focus and not chk_mute_focus.toggled.is_connected(_on_mute_focus_toggled):
		chk_mute_focus.toggled.connect(_on_mute_focus_toggled)
		
	if dpd_theme and not dpd_theme.item_selected.is_connected(_on_theme_selected):
		dpd_theme.item_selected.connect(_on_theme_selected)
		
	if btn_preview and not btn_preview.pressed.is_connected(_on_preview_pressed):
		btn_preview.pressed.connect(_on_preview_pressed)
	
	# Revisamos que el lambda no se haya conectado antes
	if preview_player and preview_player.finished.get_connections().size() == 0:
		preview_player.finished.connect(func(): btn_preview.texture_normal = _tex_play)

func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_setup_audio_tab()
		_sync_audio()
