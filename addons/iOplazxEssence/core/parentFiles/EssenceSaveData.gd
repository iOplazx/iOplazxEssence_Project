class_name EssenceSaveData
extends RefCounted

const ES_NAME_CLASS = "EssenceSaveData"

# ==============================================================================
# MANDATORY FRAMEWORK METADATA
# ==============================================================================
var version: int = 1
var timestamp: float = 0.0
var date_string: String = ""
var title: String = "Auto-Save"
var description: String = "" 
var play_time: String = "00:00:00"
var slot_number: int = 1
var page: int = 1
var is_auto: bool = false

## Dynamic dictionary to hold developer custom metadata without modifying core addon code
var custom_meta: Dictionary = {}


# ==============================================================================
# IN-MEMORY STATE MANAGEMENT (PREPARATION HOOKS)
# ==============================================================================

## Prepares save data when target slot is empty.
func prepare_as_new(temp_meta: Dictionary, temp_game: Dictionary) -> void:
	title = temp_meta.get("title", "Auto-Save")
	description = temp_meta.get("description", "")
	play_time = temp_meta.get("play_time", "00:00:00")
	
	# Preserve custom developer metadata dynamically (e.g., game_version, save_version)
	custom_meta = temp_meta.duplicate()
	_load_child_data(temp_game)


## Prepares save data when overwriting an existing slot.
func prepare_as_overwrite(old_data: Dictionary, temp_meta: Dictionary, temp_game: Dictionary) -> void:
	# 1. Inspect existing metadata to preserve custom slot attributes
	var old_meta: Dictionary = old_data.get("essence_meta", {})
	
	# TITLE RECOVERY: Retain custom title if it was previously modified
	var old_title: String = old_meta.get("title", "")
	if not old_title.is_empty() and old_title != "Auto-Save":
		title = old_title
	else:
		title = temp_meta.get("title", "Auto-Save")
		
	description = temp_meta.get("description", "")
	play_time = temp_meta.get("play_time", "00:00:00")
	
	# Preserve position within UI pagination grid
	page = old_meta.get("page", 1)
	slot_number = old_meta.get("slot_number", 1)
	
	# Preserve custom developer metadata
	custom_meta = temp_meta.duplicate()
	
	# 2. Delegate game state merging hook to child class
	_handle_overwrite_game_data(old_data.get("game_data", {}), temp_game)


# ==============================================================================
# SERIALIZATION / DESERIALIZATION PIPELINE
# ==============================================================================

## Serializes metadata and child game data into a structured Dictionary.
func to_dict() -> Dictionary:
	if timestamp == 0.0:
		timestamp = Time.get_unix_time_from_system()
		
	if date_string.is_empty():
		date_string = Time.get_datetime_string_from_system(false, true).replace("T", " ")
	
	var base_meta: Dictionary = {
		"version": version,
		"timestamp": timestamp,
		"date_string": date_string,
		"title": title,
		"description": description,
		"play_time": play_time,
		"slot_number": slot_number,
		"page": page,
		"is_auto": is_auto
	}
	
	# Dynamically merge extra metadata keys into the serialized output
	base_meta.merge(custom_meta, true)
	
	return {
		"essence_meta": base_meta,
		"game_data": _get_child_data() 
	}


## Deserializes raw save Dictionary back into instance properties.
func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		EssenceLogger.system_info("[%s] Warning: Attempted to load an empty dictionary in from_dict." % ES_NAME_CLASS)
		return

	# 1. Unpack framework metadata
	var meta: Dictionary = data.get("essence_meta", {})
	
	version     = meta.get("version", 1)
	timestamp   = meta.get("timestamp", 0.0)
	date_string = meta.get("date_string", "")
	title       = meta.get("title", "Auto-Save")
	description = meta.get("description", "")
	play_time   = meta.get("play_time", "00:00:00")
	slot_number = meta.get("slot_number", 1)
	page        = meta.get("page", 1)
	is_auto     = meta.get("is_auto", false)

	# Keep dynamic custom metadata in memory
	custom_meta = meta.duplicate()

	# 2. Unpack game-specific child data
	_load_child_data(data.get("game_data", {}))
	
	EssenceLogger.system_info("[%s] Data successfully deserialized for slot %d." % [ES_NAME_CLASS, slot_number])


# ==============================================================================
# VIRTUAL METHODS (Overridden by developer subclass, e.g., MyGameSave.gd)
# ==============================================================================

## Virtual method to return child game data payload.
func _get_child_data() -> Dictionary:
	return {}


## Virtual method to unpack child game data.
func _load_child_data(_data: Dictionary) -> void:
	pass


## Optional virtual hook for developer-defined state merging during slot overwrites.
func _handle_overwrite_game_data(_old_game_data: Dictionary, new_game_data: Dictionary) -> void:
	# Default behavior: overwrite old game data with new game data
	_load_child_data(new_game_data)
