extends EssenceMenuController

func _ready() -> void:
	# ALWAYS call super._ready() so that the framework builds the UI
	super._ready() 
	
	EssenceLogger.system_info("[DemoMainMenu] Welcome to the Main Menu!")
	
	# We request the song from the cache (previously loaded in Boot.gd)
	# The '2.0' indicates a smooth 2-second fade-in.
	var menu_song = AudioManager.get_cached_audio("menu_theme")
	if menu_song:
		AudioManager.play_music(menu_song, 2.0)
	else:
		EssenceLogger.system_info("[DemoMainMenu] Warning: 'menu_theme' not found in cache.")

# ==============================================================================
# INTEGRATION HOOKS (GAME LOGIC OVERRIDES)
# ==============================================================================

func _on_new_game_hook() -> void:
	# OVERRIDE: here is where you reset global variables for a new game.
	# Example: PlayerStats.hp = 100, GameRuntime.current_chapter = 1
	# This runs safely AFTER the framework clears RAM, but BEFORE changing scenes.
	# but before changing scenes.
	
	EssenceLogger.system_info("[DemoMainMenu] New Game Hook triggered. Initializing fresh game state...")

func _on_continue_hook(_save_data: Dictionary) -> void:
	# OVERRIDE: Here you react to the loaded data before the scene starts.
	# The base data has already been injected into 'SaveManager.loaded_game_data'.
	# Use '_save_data' if you need to read metadata (e.g., playtime, date).
	
	EssenceLogger.system_info("[DemoMainMenu] Continue Hook triggered. Preparing to resume the adventure...")
