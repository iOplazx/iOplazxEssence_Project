class_name EssenceTabAudio extends MarginContainer

const ES_NAME_CLASS = "EssenceTabAudio"

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

func _ready() -> void:
	if _validate_requirements():
		_tex_play = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_PLAY)
		_tex_pause = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_PAUSE)
		
		_connect_signals() 
		_setup_audio_tab() 
		_sync_audio()
		EssenceLogger.system_info("[%s] Audio Tab initialized and synced." % ES_NAME_CLASS)

## Check for missing nodes in the Inspector
func _validate_requirements() -> bool:
	var essential_rows = [row_master, row_music, row_sfx, row_ui, row_voices]
	for row in essential_rows:
		if row == null:
			EssenceError.report(
				"Missing Audio Row",
				"One or more EssenceRowSliders are not assigned in %s." % name,
				EssenceError.Severity.CRITICAL
			)
			return false
			
	if not is_instance_valid(AudioManager):
		EssenceError.report("Missing Autoload", "AudioManager not found in SceneTree.", EssenceError.Severity.CRITICAL)
		return false
		
	return true

func _setup_audio_tab() -> void:
	if dpd_theme:
		var current = dpd_theme.selected
		dpd_theme.clear()
		
		# These could be moved to your CSV as UI_THEME_0, etc.
		dpd_theme.add_item("Sci-Fi (Space)") 
		dpd_theme.add_item("Bubble Effect")
		dpd_theme.add_item("Silent / Off")
		
		if current != -1: 
			dpd_theme.select(current)
			
	if btn_preview:
		btn_preview.texture_normal = _tex_play

func _connect_row(row: EssenceRowSlider, bus_name: String, test: bool = false) -> void:
	if is_instance_valid(row):
		# Manejar el cambio de volumen
		if is_instance_valid(row.slider):
			row.slider.value_changed.connect(func(v): AudioManager.set_bus_volume(bus_name, v))
			row.slider.drag_ended.connect(func(_c): 
				_save_audio()
				if test: AudioManager.play_ui_sfx()
			)
		
		# ¡NUEVO!: Manejar el click en el CheckButton de mute
		# Asumiendo que tu checkButton en RowSlider es accesible (ej: row.check_mute)
		if row.has_signal("mute_toggled"):
			row.mute_toggled.connect(func(is_muted):
				AudioManager.set_bus_mute(bus_name, is_muted) # Usa el mute nativo de Godot
				_save_audio() # Ahora sí guardamos al hacer clic
			)
		else:
			EssenceError.report(
				"mute_toggled not found",
				"The 'mute_toggled' method was not found in the EssenceRowSlidder; perhaps the method name has been changed.",
				EssenceError.Severity.WARNING)

func _on_mute_focus_toggled(on: bool) -> void:
	AudioManager.mute_on_focus_loss = on
	_save_audio()
	AudioManager.play_ui_sfx()

func _save_audio() -> void:
	if not is_instance_valid(row_master): return
	
	var focus_mute = chk_mute_focus.button_pressed if chk_mute_focus else false
	
	AudioManager.save_audio_settings(
		row_master.slider.value, 
		row_music.slider.value, 
		row_sfx.slider.value, 
		row_ui.slider.value, 
		row_voices.slider.value,
		row_master.btn_mute.button_pressed, 
		row_music.btn_mute.button_pressed, 
		row_sfx.btn_mute.button_pressed, 
		row_ui.btn_mute.button_pressed, 
		row_voices.btn_mute.button_pressed,
		focus_mute
	)
	EssenceLogger.system_info("[%s] Audio settings saved to disk (including mutes)." % ES_NAME_CLASS)
	
func _sync_audio() -> void:
	var v = AudioManager.load_audio_settings()
	
	var mapping = {
		"Master": row_master,
		"Music": row_music,
		"SFX": row_sfx,
		"UI": row_ui,
		"Voices": row_voices
	}
	
	for bus in mapping:
		var row = mapping[bus]
		if is_instance_valid(row):
			# Sincronizamos el Slider
			if is_instance_valid(row.slider):
				row.slider.value = v.get(bus, 80.0)
			
			# Sincronizamos el CheckButton (Mute)
			if is_instance_valid(row.btn_mute): 
				row.btn_mute.set_block_signals(true) 
				row.btn_mute.button_pressed = v.get(bus + "_mute", false) 
				row.btn_mute.set_block_signals(false) 
				
				# Aplicamos el mute nativo al cargar la pestaña
				AudioManager.set_bus_mute(bus, row.btn_mute.button_pressed)
	
	if dpd_theme: dpd_theme.selected = AudioManager.current_ui_theme
	
	if chk_mute_focus:
		chk_mute_focus.set_block_signals(true)
		chk_mute_focus.button_pressed = AudioManager.mute_on_focus_loss
		chk_mute_focus.set_block_signals(false)

func _on_theme_selected(idx: int) -> void:
	AudioManager.set_ui_theme(idx)
	if is_instance_valid(preview_player) and preview_player.playing: 
		preview_player.stop()

func _on_preview_pressed() -> void:
	if not is_instance_valid(preview_player): return
	
	if preview_player.playing:
		preview_player.stop()
		btn_preview.texture_normal = _tex_play
		return
		
	var theme = AudioManager.current_ui_theme
	if theme == 2: return # Theme 'Silent'
	
	preview_player.stream = AudioManager.get_cached_audio("ui_space" if theme == 0 else "ui_bubble")
	
	if preview_player.stream:
		btn_preview.texture_normal = _tex_pause
		preview_player.play()
	else:
		EssenceError.report("Audio Preview Error", "Audio stream for theme %d not found." % theme, EssenceError.Severity.WARNING)

# ==========================================
# CONEXIONES ÚNICAS
# ==========================================
func _connect_signals() -> void:
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
	
	if is_instance_valid(preview_player):
		if not preview_player.finished.is_connected(self._on_preview_finished):
			preview_player.finished.connect(self._on_preview_finished)

func _on_preview_finished() -> void:
	if btn_preview: btn_preview.texture_normal = _tex_play

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_setup_audio_tab()
		_sync_audio()
