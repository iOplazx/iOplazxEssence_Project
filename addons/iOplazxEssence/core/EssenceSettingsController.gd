class_name EssenceSettingsController extends Control

@export_category("iOplazx Settings UI")

@export_group("Global Connections")
@export var btn_return: Button

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
## El VBoxContainer donde se apilarán las tarjetas
@export var list_languages: VBoxContainer 

@export_subgroup("Prefabs")
## Arrastra aquí tu escena EssenceLanguageCard.tscn
@export var language_card_prefab: PackedScene

var _tex_play: Texture2D
var _tex_pause: Texture2D

func _ready():
	_load_icons() # Cargamos las imágenes en RAM primero
	_setup_sliders_range()
	_setup_theme_dropdown()
	_setup_extra_settings()
	_connect_signals()
	_sync_with_managers() # Sincronizamos la UI con los Autoloads
	_populate_languages()

func _load_icons():
	# Usamos tu arquitectura global para cargar los iconos a prueba de fallos
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
# LÓGICA DEL TEMA DE INTERFAZ (COMBOBOX)
# ==========================================

func _setup_theme_dropdown():
	if not dropdown_ui_theme or not btn_preview: return
	
	dropdown_ui_theme.clear()
	dropdown_ui_theme.add_item("Sci-Fi (Space)") # Índice 0
	dropdown_ui_theme.add_item("Burbuja (Bubble)") # Índice 1
	dropdown_ui_theme.add_item("Silencio")       # Índice 2
	
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
	_save_all_settings() # Mucho más limpio, reutilizamos la función de abajo
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
	# 1. Sincronizar Sliders de Audio
	var saved_vols = AudioManager.load_audio_settings()
	if row_master_volume and row_master_volume.slider: row_master_volume.slider.value = saved_vols["Master"]
	if row_background_music and row_background_music.slider: row_background_music.slider.value = saved_vols["Music"]
	if row_sfx_volume and row_sfx_volume.slider: row_sfx_volume.slider.value = saved_vols["SFX"]
	if row_ui_volume and row_ui_volume.slider: row_ui_volume.slider.value = saved_vols["UI"]
	if row_voices_volume and row_voices_volume.slider: row_voices_volume.slider.value = saved_vols["Voices"]
	
	# 2. Sincronizar Tema de UI
	if dropdown_ui_theme: 
		dropdown_ui_theme.selected = AudioManager.current_ui_theme
			
	# 3. Sincronizar Modo de Ventana
	if dpdMode:
		dpdMode.selected = DisplayManager.current_window_mode
		
	# 4. Sincronizar Check de Silencio (bloqueamos señales para no disparar el guardado por accidente al cargar)
	if chkMuteFocusLoss:
		chkMuteFocusLoss.set_block_signals(true)
		chkMuteFocusLoss.button_pressed = AudioManager.mute_on_focus_loss
		chkMuteFocusLoss.set_block_signals(false)


##### METODOS ####
func _populate_languages():
	if not list_languages or not language_card_prefab:
		return
		
	# 1. Limpiamos la lista para evitar duplicados si el jugador entra y sale del menú
	for child in list_languages.get_children():
		child.queue_free()
		
	# 2. Le pedimos al Manager la lista REAL de idiomas detectados
	var real_data = LanguageManager.get_language_list()
	
	# 3. Instanciamos las tarjetas
	for data in real_data:
		var card: EssenceLanguageCard = language_card_prefab.instantiate()
		list_languages.add_child(card)
		
		# Inyectamos los datos reales (nombre, autor, ruta de bandera)
		card.setup_card(data)
		
		# Conectamos las señales
		card.on_apply_requested.connect(_on_language_apply)
		card.on_info_requested.connect(_on_language_info)

# Funciones receptoras de las señales
func _on_language_apply(folder_code: String):
	print("Essence: Aplicando idioma -> ", folder_code)
	
	# Le decimos al motor de Godot que cambie el idioma globalmente
	TranslationServer.set_locale(folder_code)
	
	# Reproducimos sonido de éxito
	AudioManager.play_ui_sfx()
	
	# Opcional: Aquí podrías guardar la preferencia en el archivo de guardado del usuario
	# EssenceSaveManager.save_setting("language", folder_code)

func _on_language_info(data: Dictionary):
	print("Mostrando créditos de: ", data.get("name", "Unknown"))
	# Aquí abriremos la ventana emergente después
