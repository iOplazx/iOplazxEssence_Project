extends Node

const ES_NAME_CLASS = "EssenceAudioManager"

# Reproductores dedicados
var music_player_1: AudioStreamPlayer
var music_player_2: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

# Animador para las transiciones suaves
var _fade_tween: Tween

# Nuestra Caja Fuerte para la RAM
var _audio_cache: Dictionary = {}

# Precargamos usando las constantes (EssencePaths no es Autoload, es seguro)
var ui_sound_space = preload(EssencePaths.AUDIO_UI_SPACE)
var ui_sound_bubble = preload(EssencePaths.AUDIO_UI_BUBBLE)

# 0 = Space, 1 = Bubble, 2 = Silencio
var current_ui_theme: int = 0

# Configuración extra
var mute_on_focus_loss: bool = false
var _was_muted_manually: bool = false 

signal fade_completed

func _ready() -> void:
	# Creamos los nodos al vuelo
	music_player_1 = AudioStreamPlayer.new()
	music_player_1.bus = "Music" 
	add_child(music_player_1)
	
	music_player_2 = AudioStreamPlayer.new()
	music_player_2.bus = "Music" 
	add_child(music_player_2)
	
	_active_music_player = music_player_1
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "UI"
	add_child(ui_player)
	
	load_audio_settings()
	
	# Conexión segura a Preferences usando Late Binding
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_signal("settings_restored"):
		prefs.settings_restored.connect(_on_settings_restored)

# ==========================================
# MÉTODOS PÚBLICOS PARA EL USUARIO
# ==========================================

func play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func play_ui(stream: AudioStream) -> void:
	if stream:
		ui_player.stream = stream
		ui_player.play()

func play_ui_sfx(stream: AudioStream = null, pitch: float = 1.0) -> void:
	if current_ui_theme == 2:
		return
		
	var stream_to_play: AudioStream = stream
	
	if stream_to_play == null:
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
	
func fade_out_and_stop(duration: float = 1.0) -> void:
	if not _active_music_player.playing:
		fade_completed.emit()
		return
		
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(_active_music_player, "volume_db", -60.0, duration)
	
	await _fade_tween.finished
	_active_music_player.stop()
	fade_completed.emit()

func play_music(stream: AudioStream, crossfade_duration: float = 1.0) -> void:
	if _active_music_player.stream == stream and _active_music_player.playing:
		return 
		
	var old_player = _active_music_player 
	var next_player = music_player_2 if _active_music_player == music_player_1 else music_player_1
	
	next_player.stream = stream
	next_player.volume_db = -60.0
	next_player.play()
	
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
		
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true) 
	
	if old_player.playing:
		_fade_tween.tween_property(old_player, "volume_db", -60.0, crossfade_duration)
	
	_fade_tween.tween_property(next_player, "volume_db", 0.0, crossfade_duration)
	
	_fade_tween.chain().tween_callback(func(): old_player.stop())
	_active_music_player = next_player

# ==========================================
# MÉTODOS PRIVADOS Y DE CACHÉ
# ==========================================

func _on_settings_restored() -> void:
	_safe_log("[%s] Settings restored. Recalculating volumes..." % ES_NAME_CLASS)
	load_audio_settings() 

func _on_quit_pressed() -> void:
	play_ui_sfx() # Llamada directa, sin usar el nombre global "AudioManager"
	fade_out_and_stop(1.5)
	await self.fade_completed
	get_tree().quit()

func cache_audio(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_audio_cache[key] = load(path) 
	else:
		_safe_error("Audio Not Found", "The specified audio file was not found at %s." % path)

func get_cached_audio(key: String) -> AudioStream:
	if _audio_cache.has(key):
		return _audio_cache[key]
	return null

# ==========================================
# CONTROL DE VOLUMEN (TOTALMENTE DESACOPLADO)
# ==========================================

func set_bus_volume(bus_name: String, value: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func save_audio_settings(vol_master: float, vol_music: float, vol_sfx: float, vol_ui: float, vol_voices: float) -> void:
	_safe_set_pref("audio", "Master", vol_master)
	_safe_set_pref("audio", "Music", vol_music)
	_safe_set_pref("audio", "SFX", vol_sfx)
	_safe_set_pref("audio", "UI", vol_ui)
	_safe_set_pref("audio", "Voices", vol_voices)
	_safe_set_pref("audio", "mute_on_focus", mute_on_focus_loss)
	
	# Disparamos el guardado al disco
	_safe_save_prefs()

func load_audio_settings() -> Dictionary:
	var vols = {
		"Master": _safe_get_pref("audio", "Master", 1.0),
		"Music": _safe_get_pref("audio", "Music", 1.0),
		"SFX": _safe_get_pref("audio", "SFX", 1.0),
		"UI": _safe_get_pref("audio", "UI", 1.0),
		"Voices": _safe_get_pref("audio", "Voices", 1.0)
	}
	
	current_ui_theme = _safe_get_pref("audio", "ui_theme", 0)
	mute_on_focus_loss = _safe_get_pref("audio", "mute_on_focus", false)
	
	set_bus_volume("Master", vols["Master"])
	set_bus_volume("Music", vols["Music"])
	set_bus_volume("SFX", vols["SFX"])
	set_bus_volume("UI", vols["UI"])
	set_bus_volume("Voices", vols["Voices"])
	
	return vols
	
func set_ui_theme(theme_index: int) -> void:
	current_ui_theme = theme_index
	_safe_set_pref("audio", "ui_theme", current_ui_theme)
	_safe_save_prefs()

# ==========================================
# EVENTOS DEL SISTEMA
# ==========================================

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if mute_on_focus_loss:
			var master_idx = AudioServer.get_bus_index("Master")
			_was_muted_manually = AudioServer.is_bus_mute(master_idx)
			AudioServer.set_bus_mute(master_idx, true) 
			_safe_log("[%s] Focus lost - Muting audio." % ES_NAME_CLASS)
			
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if mute_on_focus_loss:
			var master_idx = AudioServer.get_bus_index("Master")
			AudioServer.set_bus_mute(master_idx, _was_muted_manually)
			_safe_log("[%s] Focus regained - Restoring audio." % ES_NAME_CLASS)


# ==============================================================================
# WRAPPERS DE SEGURIDAD (Para no depender estrictamente de los otros Autoloads)
# ==============================================================================

func _safe_log(msg: String) -> void:
	var logger = get_tree().root.get_node_or_null("EssenceLogger")
	if is_instance_valid(logger) and logger.has_method("system_info"):
		logger.system_info(msg)
	else:
		print("Fallback Log: ", msg)

func _safe_error(title: String, msg: String) -> void:
	var err_handler = get_tree().root.get_node_or_null("EssenceError")
	if is_instance_valid(err_handler) and err_handler.has_method("report"):
		err_handler.report(title, msg, 1) # 1 = WARNING
	else:
		push_warning("Fallback Error [" + title + "]: " + msg)

func _safe_get_pref(section: String, key: String, default_val: Variant) -> Variant:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("get_setting"):
		return prefs.get_setting(section, key, default_val)
	return default_val

func _safe_set_pref(section: String, key: String, value: Variant) -> void:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("set_setting"):
		prefs.set_setting(section, key, value)

func _safe_save_prefs() -> void:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("save_to_disk"):
		prefs.save_to_disk()