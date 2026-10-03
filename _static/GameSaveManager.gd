extends EssenceSaveManager

const GAME_NAME_CLASS = "GameSaveManager-USER"

# ==============================================================================
# GAME SAVE MANAGER (AUTOLOAD / USER SPACE)
# This script extends the core iOplazxEssence framework's EssenceSaveManager.
# It acts as the central bridge for packaging live game data, stamping metadata,
# and invoking the migration factory when loading older save files.
# ==============================================================================

func _ready() -> void:
	super._ready()
	var log_msg: String = "[%s/_ready] GameSaveManager initialized, wrapping EssenceSaveManager." % GAME_NAME_CLASS
	_safe_log(log_msg)


# ==============================================================================
# INTEGRATION HOOKS (GAME LOGIC OVERRIDES)
# ==============================================================================

func _on_before_save_hook(game_data: Dictionary, meta_data: Dictionary) -> void:
	# OVERRIDE: Triggered exactly one frame before temporary dictionaries 
	# are serialized and written to the physical .ess file.
	
	# --------------------------------------------------------------------------
	# 1. PLAYTIME ACCUMULATOR
	# Retrieve total active playtime seconds from TimeManager.
	# --------------------------------------------------------------------------
	var current_playtime: float = EssenceTimeUtils.get_playtime_seconds()
	
	# --------------------------------------------------------------------------
	# 2. SAVE SCHEMA VERSION STAMP
	# Stamp current schema version on both game data and metadata.
	# Required by GameSaveMigrator to track version differences during load.
	# --------------------------------------------------------------------------
	game_data["save_version"] = GameConstants.CURRENT_SAVE_VERSION
	meta_data["save_version"] = GameConstants.CURRENT_SAVE_VERSION
	
	# --------------------------------------------------------------------------
	# 3. DISPLAY METADATA INJECTION
	# Metadata is used by the Save/Load UI cards to display slot summaries.
	# --------------------------------------------------------------------------
	meta_data[GameSaveKeys.META_LOCATION] = "Main Menu"
	meta_data[GameSaveKeys.META_PLAYTIME] = EssenceTimeUtils.format_seconds(current_playtime)
	meta_data[GameSaveKeys.META_PLAYER_LEVEL] = 1
	
	# --------------------------------------------------------------------------
	# 4. PERSISTENT GAME DATA INJECTION
	# Core variables stored inside the encrypted/binary save payload.
	# --------------------------------------------------------------------------
	game_data[GameSaveKeys.PLAYTIME_SECONDS] = current_playtime
	game_data[GameSaveKeys.DEMO_PROGRESS] = "Viewed main menu"
	game_data[GameSaveKeys.UNLOCKED_GALLERY] = false
	
	var log_msg: String = "[%s/_on_before_save_hook] Save payload successfully packaged (Schema v%d)." % [
		GAME_NAME_CLASS, 
		GameConstants.CURRENT_SAVE_VERSION
	]
	_safe_log(log_msg)


func _on_after_load_hook(game_data: Dictionary) -> void:
	# OVERRIDE: Triggered immediately after physical save data is read from disk,
	# BEFORE any scene manager or gameplay controller receives the state.
	
	# --------------------------------------------------------------------------
	# 1. SAVE FILE SCHEMA MIGRATION PIPELINE
	# Instantiate migration factory to validate and convert legacy save keys.
	# --------------------------------------------------------------------------
	var migrator: GameSaveMigrator = GameSaveMigrator.new()
	var migration_result: EssenceSaveMigrator.MigrationResult = migrator.process_migration(
		game_data, 
		SaveManager.loaded_meta_data
	)
	
	# --------------------------------------------------------------------------
	# 2. INCOMPATIBLE VERSION GUARD
	# Reject save files that are older than MIN_SUPPORTED_SAVE_VERSION.
	# --------------------------------------------------------------------------
	if migration_result == EssenceSaveMigrator.MigrationResult.INCOMPATIBLE:
		var err_msg: String = "[%s/_on_after_load_hook] Loaded save file version is incompatible with this build." % GAME_NAME_CLASS
		_safe_log(err_msg)
		game_data.clear()
		return
	
	# --------------------------------------------------------------------------
	# 3. CLOCK PLAYTIME RESTORATION
	# Inject restored seconds back into TimeManager and resume counting.
	# --------------------------------------------------------------------------
	var restored_seconds: float = float(game_data.get(GameSaveKeys.PLAYTIME_SECONDS, 0.0))
	
	var main_loop: SceneTree = Engine.get_main_loop() as SceneTree
	if is_instance_valid(main_loop) and main_loop.root.has_node("TimeManager"):
		var tm: Node = main_loop.root.get_node("TimeManager")
		if tm.has_method("set_playtime"):
			tm.set_playtime(restored_seconds)
		if tm.has_method("start_clock"):
			tm.start_clock()
	
	# --------------------------------------------------------------------------
	# 4. LOGGING & COMPLETION NOTIFICATION
	# --------------------------------------------------------------------------
	var log_msg: String = ""
	if game_data.has(GameSaveKeys.DEMO_PROGRESS):
		log_msg = "[%s/_on_after_load_hook] Load complete: Progress '%s' (Playtime: %s | Migration: %s)" % [
			GAME_NAME_CLASS, 
			game_data[GameSaveKeys.DEMO_PROGRESS],
			EssenceTimeUtils.format_seconds(restored_seconds),
			"Migrated" if migration_result == EssenceSaveMigrator.MigrationResult.MIGRATED else "OK"
		]
	else:
		log_msg = "[%s/_on_after_load_hook] Load complete: No previous progress detected. Starting fresh." % GAME_NAME_CLASS
		
	_safe_log(log_msg)
