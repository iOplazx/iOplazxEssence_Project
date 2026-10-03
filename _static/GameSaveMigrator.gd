## [GameSaveMigrator]
## Game-specific migration factory. Manages version rules and properties for this game.

class_name GameSaveMigrator
extends EssenceSaveMigrator

const GAME_NAME_CLASS = "EssenceSaveMigrator-USER"

func _get_target_save_version() -> int:
	return GameConstants.CURRENT_SAVE_VERSION

func _get_min_supported_save_version() -> int:
	return GameConstants.MIN_SUPPORTED_SAVE_VERSION

func _get_class_name() -> String:
	return "GameSaveMigrator-USER"


## Custom transformation rules for each version step
func _apply_migration_step(from_version: int, game_data: Dictionary, meta_data: Dictionary) -> bool:
	EssenceLogger.system_info("[%s/_apply_migration_step] Processing migration step: v%d" % [GAME_NAME_CLASS, from_version])
	
	match from_version:
		1:
			_migrate_v1_to_v2(game_data, meta_data)
			return true
		2:
			_migrate_v2_to_v3(game_data, meta_data)
			return true
		3:
			_migrate_v3_to_v4(game_data, meta_data)
			return true
		_:
			EssenceLogger.system_error("[%s/_apply_migration_step] No migration rule defined for version %d." % [GAME_NAME_CLASS, from_version])
			return false

# ==============================================================================
# SPECIFIC VERSION TRANSFORMATIONS
# ==============================================================================

func _migrate_v1_to_v2(game_data: Dictionary, _meta_data: Dictionary) -> void:
	EssenceLogger.system_info("[%s] Migrating data: v1 -> v2" % _get_class_name())
	
	# Spanish keys -> English GameSaveKeys
	if game_data.has("escena_actual"):
		game_data[GameSaveKeys.CURRENT_SCENE] = game_data.get("escena_actual", "MainRoom")
		game_data.erase("escena_actual")
		
	if game_data.has("fase_actual"):
		game_data[GameSaveKeys.CURRENT_PHASE] = game_data.get("fase_actual", 0)
		game_data.erase("fase_actual")

	if not game_data.has(GameSaveKeys.PLAYTIME_SECONDS):
		game_data[GameSaveKeys.PLAYTIME_SECONDS] = 0.0


func _migrate_v2_to_v3(_game_data: Dictionary, _meta_data: Dictionary) -> void:
	# Future migration rules go here
	pass
	
## Step 3 -> 4: Establishes baseline Schema v4, backfilling legacy version fields and playtime.
func _migrate_v3_to_v4(game_data: Dictionary, meta_data: Dictionary) -> void:
	EssenceLogger.system_info("[%s] Executing migration step: v3 -> v4 (Legacy Sanitization)" % GAME_NAME_CLASS)
	
	# --------------------------------------------------------------------------
	# 1. BACKFILL LEGACY GAME VERSION
	# Pre-v4 saves lacked explicit game version tags. Normalize them to "0.0.3".
	# --------------------------------------------------------------------------
	# 1. Normalize game version if absent in legacy payload
	if not game_data.has("game_version") or str(game_data["game_version"]).is_empty():
		game_data["game_version"] = "0.0.3"
	
	# --------------------------------------------------------------------------
	# 2. REPAIR PLAYTIME SECONDS
	# Apply 3-minute test fallback (180.0 seconds) if no clock data was recorded.
	# --------------------------------------------------------------------------
	var raw_playtime: float = float(game_data.get(GameSaveKeys.PLAYTIME_SECONDS, 0.0))
	if raw_playtime <= 0.0:
		raw_playtime = 180.0
		game_data[GameSaveKeys.PLAYTIME_SECONDS] = raw_playtime
	
	# --------------------------------------------------------------------------
	# 3. SYNCHRONIZE DISPLAY METADATA FOR UI CARDS
	# Update metadata so card labels (lbl_save_version / lbl_game_version) reflect state.
	# --------------------------------------------------------------------------
	meta_data[GameSaveKeys.META_PLAYTIME] = EssenceTimeUtils.format_seconds(raw_playtime)
	meta_data["save_version"] = 4
	meta_data["game_version"] = game_data["game_version"]
	
	EssenceLogger.system_info("[%s/v3_to_v4] Repaired legacy save (Origin: %s) | Schema: v4" % [
		GAME_NAME_CLASS,
		meta_data[GameSaveKeys.META_PLAYTIME]
	])
