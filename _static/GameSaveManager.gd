extends EssenceSaveManager
const GAME_NAME_CLASS = "GameSaveManager-USER"

# ==============================================================================
# GAME SAVE MANAGER (AUTOLOAD)
# ==============================================================================

func _ready():
	super._ready()
	# This is where the addon confirms it is ready to receive save data
	var log_msg = "[%s/_ready] GameSaveManager initialized, wrapping EssenceSaveManager." % GAME_NAME_CLASS
	_safe_log(log_msg)

# ==============================================================================
# INTEGRATION HOOKS
# ============================================================================== 

func _on_before_save_hook(game_data: Dictionary, meta_data: Dictionary):
	# This method is triggered for both manual saves and checkpoints.
	# It is the ideal place to "package" the game state.
	
	# 1. Get the exact number of seconds elapsed in this session
	var current_playtime: float = EssenceTimeUtils.get_playtime_seconds()
	
	# 2. Inject metadata so that the UI cards (Load Screen) display the formatted time.
	meta_data[GameSaveKeys.META_LOCATION] = "Main Menu"
	meta_data[GameSaveKeys.META_PLAYTIME] = EssenceTimeUtils.format_seconds(current_playtime)
	meta_data[GameSaveKeys.META_PLAYER_LEVEL] = 1
	
	# 3. Save the exact floating-point value within the game's persistent data.
	game_data[GameSaveKeys.PLAYTIME_SECONDS] = current_playtime
	game_data[GameSaveKeys.DEMO_PROGRESS] = "Viewed main menu"
	game_data[GameSaveKeys.UNLOCKED_GALLERY] = false
	
	# If there were gameplay elements, you would collect persistent groups here:
	# var persist_nodes = get_tree().get_nodes_in_group("Persist")
	# ... collection logic ...

func _on_after_load_hook(game_data: Dictionary):
	# This method runs after the physical save data is read from disk.
	# It is the place to "unpack" and apply loaded data to the game.
	
	# 1. Extract the recovered seconds from the .ess file
	var restored_seconds: float = float(game_data.get(GameSaveKeys.PLAYTIME_SECONDS, 0.0))
	
	# 2. Restore the accumulator in TimeManager and resume counting.
	var main_loop: SceneTree = Engine.get_main_loop() as SceneTree
	if is_instance_valid(main_loop) and main_loop.root.has_node("TimeManager"):
		var tm: Node = main_loop.root.get_node("TimeManager")
		if tm.has_method("set_playtime"):
			tm.set_playtime(restored_seconds)
			tm.start_clock()
	
	var log_msg: String = ""
	if game_data.has(GameSaveKeys.DEMO_PROGRESS):
		log_msg = "[%s/_on_after_load_hook] Load complete: Detected progress is: %s (Playtime: %s)" % [
			GAME_NAME_CLASS, 
			game_data["demo_progress"],
			EssenceTimeUtils.format_seconds(restored_seconds)
		]
	else:
		log_msg = "[%s/_on_after_load_hook] Load complete: No previous progress detected. Starting fresh." % GAME_NAME_CLASS
		
	_safe_log(log_msg)
	
	# If a checkpoint or continue load is performed, restore here:
	# 1. Player position
	# 2. Story state
	# 3. Inventory
	
	# Emit a signal to notify the rest of the game that loading is complete
