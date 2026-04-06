extends EssenceMenuController

# Preload the song (assuming the cache system is being used)
# Note: If Boot already loaded it into RAM, you only need to call it, not preload it here.

func _ready():
	super._ready() 
	
	print("Demo: Welcome to the Main Menu!")
	
	# Fetch the song from the cache and play it smoothly
	var menu_song = AudioManager.get_cached_audio("menu_theme")
	if menu_song:
		AudioManager.play_music(menu_song, 2.0)

# ==============================================================================
# INTEGRATION HOOKS (GAME LOGIC OVERRIDES)
# ==============================================================================

func _on_new_game_hook():
	# OVERRIDE: This is where you reset global variables for a fresh playthrough.
	# Example: PlayerStats.hp = 100, GameRuntime.current_chapter = 1
	# This runs safely after the framework clears the RAM, but before scene change.
	
	print("Demo: New Game Hook triggered. Initializing fresh game state...")
	pass

func _on_continue_hook(_save_data: Dictionary):
	# OVERRIDE: This is where you can react to the loaded data before the scene starts.
	# The core data is already injected into SaveManager.loaded_game_data.
	# You can use '_save_data' here if you need to read metadata like playtime or timestamps.
	
	print("Demo: Continue Hook triggered. Preparing to resume the adventure...")
	pass
