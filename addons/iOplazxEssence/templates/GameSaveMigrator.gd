class_name GameSaveMigrator_IESS #GameSaveMigrator In the real file en _statics
extends EssenceSaveMigrator

const GAME_NAME_CLASS = "GameSaveMigrator-TEMPLATE"

# ==============================================================================
# GAME SAVE MIGRATOR (TEMPLATE / USER SPACE)
# This script extends EssenceSaveMigrator to manage save file schema changes.
# Place this file in res://_static/GameSaveMigrator.gd so framework updates
# do not overwrite your game-specific migration rules.
# ==============================================================================


func _get_target_save_version() -> int:
	# Returns the current active save schema version defined in your game constants.
	return GameConstants.CURRENT_SAVE_VERSION


func _get_min_supported_save_version() -> int:
	# Returns the oldest save version compatible with this game release.
	# Saves older than this number will be rejected as incompatible.
	return GameConstants.MIN_SUPPORTED_SAVE_VERSION


func _get_class_name() -> String:
	return GAME_NAME_CLASS


# ==============================================================================
# MIGRATION PIPELINE HOOK
# ==============================================================================

func _apply_migration_step(from_version: int, game_data: Dictionary, meta_data: Dictionary) -> bool:
	# OVERRIDE: Routes incremental version steps (e.g., v1 -> v2, v2 -> v3).
	# Must return true if the migration step succeeded, or false to abort.
	
	EssenceLogger.system_info("[%s/_apply_migration_step] Processing migration step: v%d" % [GAME_NAME_CLASS, from_version])
	
	match from_version:
		1:
			_migrate_v1_to_v2(game_data, meta_data)
			return true
		2:
			_migrate_v2_to_v3(game_data, meta_data)
			return true
		_:
			# Unhandled version step
			EssenceLogger.system_error("[%s/_apply_migration_step] No migration rule defined for version %d." % [GAME_NAME_CLASS, from_version])
			return false


# ==============================================================================
# SPECIFIC VERSION TRANSFORMATIONS
# Define your schema changes step by step below.
# ==============================================================================

## Step 1 -> 2: Standardizes legacy dictionary keys and injects new default fields.
func _migrate_v1_to_v2(game_data: Dictionary, meta_data: Dictionary) -> void:
	# --------------------------------------------------------------------------
	# 1. RENAME OR CONVERT LEGACY KEYS
	# Adapt older variable names to your updated GameSaveKeys constants.
	# --------------------------------------------------------------------------
	if game_data.has("escena_actual") and not game_data.has(GameSaveKeys.CURRENT_SCENE):
		game_data[GameSaveKeys.CURRENT_SCENE] = game_data.get("escena_actual", "MainRoom")
		game_data.erase("escena_actual")
		
	if game_data.has("fase_actual") and not game_data.has(GameSaveKeys.CURRENT_PHASE):
		game_data[GameSaveKeys.CURRENT_PHASE] = game_data.get("fase_actual", 0)
		game_data.erase("fase_actual")

	if game_data.has("habitacion_actual") and not game_data.has(GameSaveKeys.CURRENT_ROOM):
		game_data[GameSaveKeys.CURRENT_ROOM] = game_data.get("habitacion_actual", 0)
		game_data.erase("habitacion_actual")

	if game_data.has("ropa_estado_personaje") and not game_data.has(GameSaveKeys.CHARACTER_CLOTHING_STATE):
		game_data[GameSaveKeys.CHARACTER_CLOTHING_STATE] = game_data.get("ropa_estado_personaje", {})
		game_data.erase("ropa_estado_personaje")

	# --------------------------------------------------------------------------
	# 2. INJECT NEW MANDATORY DATA FIELDS
	# Ensure new features don't throw null errors on loaded older saves.
	# --------------------------------------------------------------------------
	if not game_data.has(GameSaveKeys.PLAYTIME_SECONDS):
		game_data[GameSaveKeys.PLAYTIME_SECONDS] = 0.0

	# --------------------------------------------------------------------------
	# 3. SYNCHRONIZE METADATA
	# Update old UI display metadata keys if needed.
	# --------------------------------------------------------------------------
	if meta_data.has("play_time") and not meta_data.has(GameSaveKeys.META_PLAYTIME):
		meta_data[GameSaveKeys.META_PLAYTIME] = meta_data.get("play_time", "00:00:00")


## Step 2 -> 3: Example placeholder for future feature updates (e.g., Inventory system rework).
func _migrate_v2_to_v3(_game_data: Dictionary, _meta_data: Dictionary) -> void:
	# Add your v2 to v3 transformation logic here when incrementing CURRENT_SAVE_VERSION to 3.
	pass
