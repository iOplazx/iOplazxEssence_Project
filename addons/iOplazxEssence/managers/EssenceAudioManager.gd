extends Node

# Reproductores dedicados
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

# Animador para las transiciones suaves
var _fade_tween: Tween

# Nuestra Caja Fuerte para la RAM
var _audio_cache: Dictionary = {}

func _ready():
	# Creamos los nodos al vuelo (Ahorra tener que hacer un .tscn separado)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master" # Más adelante puedes crear buses dedicados como "Music" o "SFX"
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "Master"
	add_child(ui_player)

# ==========================================
# MÉTODOS PÚBLICOS PARA EL USUARIO
# ==========================================

## Reproduce música con una transición suave (Crossfade) para evitar cortes bruscos
func play_music(stream: AudioStream, fade_duration: float = 1.0):
	if music_player.stream == stream and music_player.playing:
		return # Si ya está sonando esa misma canción, no hacemos nada
		
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill() # Detenemos cualquier transición anterior
		
	_fade_tween = create_tween()
	
	# Si ya hay música sonando, primero la bajamos a volumen 0
	if music_player.playing:
		# En Godot, el volumen se mide en decibelios (dB). -60.0 dB es silencio absoluto.
		_fade_tween.tween_property(music_player, "volume_db", -60.0, fade_duration / 2.0)
		_fade_tween.tween_callback(func(): _cambiar_pista(stream))
		_fade_tween.tween_property(music_player, "volume_db", 0.0, fade_duration / 2.0)
	else:
		# Si no había música, empezamos desde silencio y subimos
		music_player.volume_db = -60.0
		_cambiar_pista(stream)
		_fade_tween.tween_property(music_player, "volume_db", 0.0, fade_duration)

## Reproduce un efecto de sonido
func play_sfx(stream: AudioStream):
	sfx_player.stream = stream
	sfx_player.play()

## Reproduce un sonido de interfaz (botones, clics)
func play_ui(stream: AudioStream):
	ui_player.stream = stream
	ui_player.play()

## Ajusta el volumen maestro general (Útil para un menú de opciones)
func set_master_volume(volume_percent: float):
	# Convertimos porcentaje (0 a 100) a decibelios (dB)
	var db = linear_to_db(clamp(volume_percent / 100.0, 0.001, 1.0))
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, db)

# ==========================================
# MÉTODOS PRIVADOS
# ==========================================

func _cambiar_pista(stream: AudioStream):
	music_player.stream = stream
	music_player.play()


# ==========================================
# MÉTODOS DE CACHÉ (NUEVO)
# ==========================================

## Guarda un audio en la memoria RAM durante la pantalla de carga
func cache_audio(key: String, path: String):
	if ResourceLoader.exists(path):
		# 'load' es perfecto aquí porque se ejecutará durante un frame de la pantalla de carga
		_audio_cache[key] = load(path) 
	else:
		push_error("AudioManager: No se encontró el audio en " + path)

## Recupera un audio instantáneamente
func get_cached_audio(key: String) -> AudioStream:
	if _audio_cache.has(key):
		return _audio_cache[key]
	return null
