class_name EssenceSaveMigrator
extends RefCounted

## [EssenceSaveMigrator]
## Generic base class for save file schema migrations.
## Handles version validation loops and delegates specific transformations to subclasses.

enum MigrationResult {
	OK,           ## Already up to date
	MIGRATED,     ## Successfully migrated from an older version
	INCOMPATIBLE  ## Version is too old or unsupported
}

## Processes version checking and runs incremental migration steps.
func process_migration(game_data: Dictionary, meta_data: Dictionary) -> MigrationResult:
	var loaded_version: int = int(game_data.get("save_version", 1))
	var target_version: int = _get_target_save_version()
	var min_version: int = _get_min_supported_save_version()
	
	# 1. Reject ancient unsupported saves
	if loaded_version < min_version:
		EssenceLogger.system_error("[%s] Save version %d is below minimum supported version %d." % [
			_get_class_name(), loaded_version, min_version
		])
		return MigrationResult.INCOMPATIBLE
	
	# 2. Already up to date
	if loaded_version >= target_version:
		return MigrationResult.OK
	
	# 3. Sequential migration loop (v1 -> v2 -> v3)
	var current_step: int = loaded_version
	while current_step < target_version:
		var success: bool = _apply_migration_step(current_step, game_data, meta_data)
		if not success:
			EssenceLogger.system_error("[%s] Failed to migrate step v%d." % [_get_class_name(), current_step])
			return MigrationResult.INCOMPATIBLE
		current_step += 1
		
	# Stamp new version numbers
	game_data["save_version"] = target_version
	meta_data["save_version"] = target_version
	
	EssenceLogger.system_info("[%s] Save file successfully migrated from v%d to v%d." % [
		_get_class_name(), loaded_version, target_version
	])
	
	return MigrationResult.MIGRATED


# ==============================================================================
# VIRTUAL HOOKS (To be overridden by user subclasses)
# ==============================================================================

func _get_target_save_version() -> int:
	return 1

func _get_min_supported_save_version() -> int:
	return 1

func _apply_migration_step(_from_version: int, _game_data: Dictionary, _meta_data: Dictionary) -> bool:
	return false

func _get_class_name() -> String:
	return "EssenceSaveMigrator"
