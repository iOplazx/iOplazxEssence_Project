extends EssenceSaveManager
const GAME_NAME_CLASS = "GameSaveManager-USER"

# ==============================================================================
# GAME SAVE MANAGER (AUTOLOAD)
# ==============================================================================

func _ready():
	super._ready()
	# This is where the addon confirms it is ready to receive save data
	print("GameSaveManager: Persistence system ready for the Demo.")
	var log_msg = "[%s/_ready] GameSaveManager initialized, wrapping EssenceSaveManager." % GAME_NAME_CLASS
	EssenceLogger.system_info(log_msg)

# ==============================================================================
# INTEGRATION HOOKS
# ============================================================================== 

func _on_before_save_hook(game_data: Dictionary, meta_data: Dictionary):
	# This method is triggered for both manual saves and checkpoints.
	# It is the ideal place to "package" the game state.
	
	# Example metadata to make the load menu look professional:
	meta_data["location"] = "Main Menu"
	meta_data["playtime"] = "00:00:00" # Replace with actual playtime
	meta_data["player_level"] = 1
	
	# Example game data (simulated for the demo):
	game_data["demo_progress"] = "Viewed main menu"
	game_data["unlocked_gallery"] = false
	
	# If there were gameplay elements, you would collect persistent groups here:
	# var persist_nodes = get_tree().get_nodes_in_group("Persist")
	# ... collection logic ...

func _on_after_load_hook(game_data: Dictionary):
	# This method runs after the physical save data is read from disk.
	# It is the place to "unpack" and apply loaded data to the game.
	
	if game_data.has("demo_progress"):
		#print("Load complete: Detected progress is: ", game_data["demo_progress"])
		var log_msg = "[%s/_on_after_load_hook] Load complete: Detected progress is: %s" % [GAME_NAME_CLASS, game_data["demo_progress"]]
		EssenceLogger.system_info(log_msg)
	else:
		var log_msg = "[%s/_on_after_load_hook] Load complete: No previous progress detected. Starting fresh." % GAME_NAME_CLASS
		EssenceLogger.system_info(log_msg)
	
	# If a checkpoint or continue load is performed, restore here:
	# 1. Player position
	# 2. Story state
	# 3. Inventory
	
	# Emit a signal to notify the rest of the game that loading is complete
