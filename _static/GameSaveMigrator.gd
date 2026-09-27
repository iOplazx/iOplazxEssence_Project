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
	
## Step 3 -> 4: Fixes missing playtime by setting a default fallback (e.g., 3 minutes = 180.0 seconds).
func _migrate_v3_to_v4(game_data: Dictionary, meta_data: Dictionary) -> void:
	EssenceLogger.system_info("[%s] Executing migration step: v3 -> v4" % GAME_NAME_CLASS)
	
	# 1. Recover current playtime or set 3 minutes fallback (180.0 seconds) for legacy testing
	var raw_playtime: float = float(game_data.get(GameSaveKeys.PLAYTIME_SECONDS, 0.0))
	if raw_playtime <= 0.0:
		raw_playtime = 180.0 # 3 minutes test fallback
		game_data[GameSaveKeys.PLAYTIME_SECONDS] = raw_playtime
		
	# 2. Update display metadata string to reflect the repaired playtime
	meta_data[GameSaveKeys.META_PLAYTIME] = EssenceTimeUtils.format_seconds(raw_playtime)
	
	EssenceLogger.system_info("[%s/v3_to_v4] Repaired playtime data: %f seconds (%s)" % [
		GAME_NAME_CLASS, 
		raw_playtime, 
		meta_data[GameSaveKeys.META_PLAYTIME]
	])
