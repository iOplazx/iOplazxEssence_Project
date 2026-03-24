class_name EssenceSettingsController extends Control

@export_category("UI Connections")
@export var btn_return: Button

@export_group("Audio Rows")
@export var row_master_volume: EssenceRowSlider 
@export var row_background_music: EssenceRowSlider
@export var row_sfx_volume: EssenceRowSlider
@export var row_ui_volume: EssenceRowSlider
@export var row_voices_volume: EssenceRowSlider

func _ready():
	_setup_sliders_range()
	_connect_signals()
	_sync_with_audio_manager() # En lugar de cargar archivos, le preguntamos al AudioManager

func _setup_sliders_range():
	# Arreglado: Eliminamos el duplicado y accedemos a ".slider"
	var rows = [row_master_volume, row_background_music, row_sfx_volume, row_ui_volume, row_voices_volume]
	for r in rows:
		if r and r.slider:
			r.slider.min_value = 0.0
			r.slider.max_value = 1.0
			r.slider.step = 0.01

func _connect_signals():
	if btn_return:
		btn_return.pressed.connect(SceneManager.go_back)
		
	# Conectamos las barras indicando el nombre exacto del Bus
	_connect_audio_row(row_master_volume, "Master")
	_connect_audio_row(row_background_music, "Music")
	_connect_audio_row(row_sfx_volume, "SFX")
	_connect_audio_row(row_ui_volume, "UI", true) # true para que suene el test de UI
	_connect_audio_row(row_voices_volume, "Voices")

func _connect_audio_row(row: EssenceRowSlider, bus_name: String, play_test: bool = false):
	if row and row.slider:
		# Al mover la barra, le manda la orden al AudioManager en tiempo real
		row.slider.value_changed.connect(func(val): AudioManager.set_bus_volume(bus_name, val))
		
		# Al soltar el clic, mandamos a guardar todo. Y si es UI, suena el test.
		if play_test:
			row.slider.drag_ended.connect(func(_changed): _save_all_settings(); _play_test_sound())
		else:
			row.slider.drag_ended.connect(func(_changed): _save_all_settings())

func _play_test_sound():
	# Aquí llamas al sonido que acabamos de configurar
	# AudioManager.play_ui_sfx(tu_sonido_precargado)
	pass

# ==========================================
# SINCRONIZACIÓN GLOBAL
# ==========================================

func _save_all_settings():
	# Recolectamos el valor de los 5 sliders asegurándonos de que no sean nulos
	var vol_master = row_master_volume.slider.value if row_master_volume and row_master_volume.slider else 1.0
	var vol_music = row_background_music.slider.value if row_background_music and row_background_music.slider else 1.0
	var vol_sfx = row_sfx_volume.slider.value if row_sfx_volume and row_sfx_volume.slider else 1.0
	var vol_ui = row_ui_volume.slider.value if row_ui_volume and row_ui_volume.slider else 1.0
	var vol_voices = row_voices_volume.slider.value if row_voices_volume and row_voices_volume.slider else 1.0
	
	# Delegamos el guardado al AudioManager
	AudioManager.save_audio_settings(vol_master, vol_music, vol_sfx, vol_ui, vol_voices)

func _sync_with_audio_manager():
	# Pedimos los datos al AudioManager y acomodamos los sliders para que coincidan
	var saved_vols = AudioManager.load_audio_settings()
	
	if row_master_volume and row_master_volume.slider: row_master_volume.slider.value = saved_vols["Master"]
	if row_background_music and row_background_music.slider: row_background_music.slider.value = saved_vols["Music"]
	if row_sfx_volume and row_sfx_volume.slider: row_sfx_volume.slider.value = saved_vols["SFX"]
	if row_ui_volume and row_ui_volume.slider: row_ui_volume.slider.value = saved_vols["UI"]
	if row_voices_volume and row_voices_volume.slider: row_voices_volume.slider.value = saved_vols["Voices"]
