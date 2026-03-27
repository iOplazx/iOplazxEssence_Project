extends Node

# Reproductores dedicados
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

# Animador para las transiciones suaves
var _fade_tween: Tween

# Nuestra Caja Fuerte para la RAM
var _audio_cache: Dictionary = {}

# Precargamos usando las constantes de tu nueva biblioteca
var ui_sound_space = preload(EssencePaths.AUDIO_UI_SPACE)
var ui_sound_bubble = preload(EssencePaths.AUDIO_UI_BUBBLE)

# 0 = Space, 1 = Bubble, 2 = Silencio
var current_ui_theme: int = 0

# Configuración extra
var mute_on_focus_loss: bool = false
var _was_muted_manually: bool = false # Para recordar si el jugador ya lo tenía en silencio

func _ready():
	# Creamos los nodos al vuelo
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music" 
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "UI"
	add_child(ui_player)
	
	# Leemos los ajustes usando el nuevo sistema centralizado
	load_audio_settings()

# ==========================================
# MÉTODOS PÚBLICOS PARA EL USUARIO
# ==========================================

func play_music(stream: AudioStream, fade_duration: float = 1.0):
	if music_player.stream == stream and music_player.playing:
		return 
		
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill() 
		
	_fade_tween = create_tween()
	
	if music_player.playing:
		_fade_tween.tween_property(music_player, "volume_db", -60.0, fade_duration / 2.0)
		_fade_tween.tween_callback(func(): _cambiar_pista(stream))
		_fade_tween.tween_property(music_player, "volume_db", 0.0, fade_duration / 2.0)
	else:
		music_player.volume_db = -60.0
		_cambiar_pista(stream)
		_fade_tween.tween_property(music_player, "volume_db", 0.0, fade_duration)

func play_sfx(stream: AudioStream):
	sfx_player.stream = stream
	sfx_player.play()

func play_ui(stream: AudioStream):
	ui_player.stream = stream
	ui_player.play()

func play_ui_sfx(stream: AudioStream = null, pitch: float = 1.0):
	if current_ui_theme == 2:
		return
		
	var stream_to_play: AudioStream
	
	if stream != null:
		stream_to_play = stream
	else:
		if current_ui_theme == 0:
			stream_to_play = ui_sound_space
		elif current_ui_theme == 1:
			stream_to_play = ui_sound_bubble
			
	if stream_to_play == null: 
		return
		
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	player.stream = stream_to_play
	player.pitch_scale = pitch
	player.bus = "UI" 
	
	player.play()
	player.finished.connect(player.queue_free)

# ==========================================
# MÉTODOS PRIVADOS
# ==========================================

func _cambiar_pista(stream: AudioStream):
	music_player.stream = stream
	music_player.play()

# ==========================================
# MÉTODOS DE CACHÉ
# ==========================================

func cache_audio(key: String, path: String):
	if ResourceLoader.exists(path):
		_audio_cache[key] = load(path) 
	else:
		push_error("AudioManager: No se encontró el audio en " + path)

func get_cached_audio(key: String) -> AudioStream:
	if _audio_cache.has(key):
		return _audio_cache[key]
	return null

# ==========================================
# CONTROL DE VOLUMEN Y GUARDADO (OPTIMIZADO)
# ==========================================

func set_bus_volume(bus_name: String, value: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

## Guarda la configuración en la RAM y al disco duro mediante el Preferences
func save_audio_settings(vol_master: float, vol_music: float, vol_sfx: float, vol_ui: float, vol_voices: float):
	Preferences.set_setting("audio", "Master", vol_master)
	Preferences.set_setting("audio", "Music", vol_music)
	Preferences.set_setting("audio", "SFX", vol_sfx)
	Preferences.set_setting("audio", "UI", vol_ui)
	Preferences.set_setting("audio", "Voices", vol_voices)
	Preferences.set_setting("audio", "mute_on_focus", mute_on_focus_loss)
	
	# Disparamos el guardado al disco (puedes quitar esta línea si prefieres
	# que el Menú de Ajustes se encargue de llamar a save_to_disk() al salir)
	Preferences.save_to_disk()

## Carga la configuración desde el Preferences
func load_audio_settings() -> Dictionary:
	var vols = {
		"Master": Preferences.get_setting("audio", "Master", 1.0),
		"Music": Preferences.get_setting("audio", "Music", 1.0),
		"SFX": Preferences.get_setting("audio", "SFX", 1.0),
		"UI": Preferences.get_setting("audio", "UI", 1.0),
		"Voices": Preferences.get_setting("audio", "Voices", 1.0)
	}
	
	current_ui_theme = Preferences.get_setting("audio", "ui_theme", 0)
	mute_on_focus_loss = Preferences.get_setting("audio", "mute_on_focus", false)
	
	set_bus_volume("Master", vols["Master"])
	set_bus_volume("Music", vols["Music"])
	set_bus_volume("SFX", vols["SFX"])
	set_bus_volume("UI", vols["UI"])
	set_bus_volume("Voices", vols["Voices"])
	
	return vols
	
func set_ui_theme(theme_index: int):
	current_ui_theme = theme_index
	Preferences.set_setting("audio", "ui_theme", current_ui_theme)
	Preferences.save_to_disk()

# ==========================================
# MÉTODOS NATIVO
# ==========================================

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if mute_on_focus_loss:
			var master_idx = AudioServer.get_bus_index("Master")
			_was_muted_manually = AudioServer.is_bus_mute(master_idx)
			AudioServer.set_bus_mute(master_idx, true) 
			
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if mute_on_focus_loss:
			var master_idx = AudioServer.get_bus_index("Master")
			AudioServer.set_bus_mute(master_idx, _was_muted_manually)
