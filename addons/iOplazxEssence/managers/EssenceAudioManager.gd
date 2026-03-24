extends Node

# Reproductores dedicados
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

# Animador para las transiciones suaves
var _fade_tween: Tween

# Nuestra Caja Fuerte para la RAM
var _audio_cache: Dictionary = {}

# Ruta del archivo de guardado
const SETTINGS_FILE = "user://essence_settings.cfg"

func _ready():
	# Creamos los nodos al vuelo (Ahorra tener que hacer un .tscn separado)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music" 
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "UI"
	add_child(ui_player)
	
	# NUEVO: Al arrancar el juego, leemos el archivo y ajustamos el volumen
	load_audio_settings()

# ==========================================
# MÉTODOS PÚBLICOS PARA EL USUARIO
# ==========================================

## Reproduce música con una transición suave (Crossfade) para evitar cortes bruscos
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

## Reproduce un efecto de sonido
func play_sfx(stream: AudioStream):
	sfx_player.stream = stream
	sfx_player.play()

## Reproduce un sonido de interfaz estándar
func play_ui(stream: AudioStream):
	ui_player.stream = stream
	ui_player.play()

## Reproduce un sonido de interfaz con variación de tono (al vuelo)
func play_ui_sfx(stream: AudioStream, pitch: float = 1.0):
	if stream == null: return
	
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	player.stream = stream
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
# CONTROL DE VOLUMEN Y GUARDADO (NUEVO)
# ==========================================

## Ajusta el volumen de cualquier canal (Master, Music, SFX, UI, Voices)
func set_bus_volume(bus_name: String, value: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

## Guarda la configuración en el disco duro
func save_audio_settings(vol_master: float, vol_music: float, vol_sfx: float, vol_ui: float, vol_voices: float):
	var config = ConfigFile.new()
	config.set_value("audio", "Master", vol_master)
	config.set_value("audio", "Music", vol_music)
	config.set_value("audio", "SFX", vol_sfx)
	config.set_value("audio", "UI", vol_ui)
	config.set_value("audio", "Voices", vol_voices)
	
	config.save(SETTINGS_FILE)
	print("iOplazxEssence: Audio Global Guardado.")

## Carga la configuración y la aplica al motor de audio
func load_audio_settings() -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	var vols = {"Master": 1.0, "Music": 1.0, "SFX": 1.0, "UI": 1.0, "Voices": 1.0}
	
	if err == OK:
		vols["Master"] = config.get_value("audio", "Master", 1.0)
		vols["Music"] = config.get_value("audio", "Music", 1.0)
		vols["SFX"] = config.get_value("audio", "SFX", 1.0)
		vols["UI"] = config.get_value("audio", "UI", 1.0)
		vols["Voices"] = config.get_value("audio", "Voices", 1.0)
	
	# Aplica los volúmenes a los canales reales de Godot
	set_bus_volume("Master", vols["Master"])
	set_bus_volume("Music", vols["Music"])
	set_bus_volume("SFX", vols["SFX"])
	set_bus_volume("UI", vols["UI"])
	set_bus_volume("Voices", vols["Voices"])
	
	return vols
