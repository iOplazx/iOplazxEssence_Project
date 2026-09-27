class_name EssenceSaveFactory
extends RefCounted

const ES_NAME_CLASS = "EssenceSaveFactory"

# ==============================================================================
# ESSENCE SAVE FACTORY (ADDON CORE UTIL)
# Factory utility responsible for dynamically instantiating the correct 
# EssenceSaveData subclass defined by the user in EssenceMasterConfig.
# ==============================================================================

## Dynamically creates and returns a save instance (custom subclass or base fallback).
static func create_save_instance(config: EssenceMasterConfig) -> EssenceSaveData:
	# 1. Check if the developer provided a custom save script (e.g., MyGameSave.gd)
	if config and config.custom_save_script:
		return config.custom_save_script.new() as EssenceSaveData
	
	# 2. Fallback to base EssenceSaveData if no custom script was configured
	EssenceLogger.system_info("[%s] No custom save script detected in configuration. Fallback to base EssenceSaveData." % ES_NAME_CLASS)
	return EssenceSaveData.new()
