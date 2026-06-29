class_name LevelManager
extends RefCounted

# --- DECLARATIVE NAVIGATION GRAPH ---
# Registers which rooms are legally connected to each other.
const NAVIGATION_MAP = {
	GameIDs.RoomID.INITIAL_ROOM: [GameIDs.RoomID.ROOM_3_DOORS],
	GameIDs.RoomID.ROOM_3_DOORS: [GameIDs.RoomID.INITIAL_ROOM, GameIDs.RoomID.ROOM_1_DOOR, GameIDs.RoomID.PARK], 
	GameIDs.RoomID.ROOM_1_DOOR:  [GameIDs.RoomID.ROOM_3_DOORS, GameIDs.RoomID.SAVE_SCENE],  
	GameIDs.RoomID.PARK:         [GameIDs.RoomID.ROOM_3_DOORS]
}

## Calculates and returns the scenery configuration based on spatial transitions and interaction modes.
## [param current_place]: The ID of the room where the player is currently located.
## [param next_place]: The ID of the room the player wants to navigate to.
## [param mode]: The specific sub-mode or layout variant to apply within the room.
## [param is_only_change_mode]: If true, skips room reloading and only updates the internal interaction rules.
static func get_scenery_config(current_place: int, next_place: int, mode: int, is_only_change_mode: bool) -> Dictionary:
	var config: Dictionary = {
		"id_room": next_place,         
		"id_background_scene": -1,    
		"interaction_mode": 0,
		"flag_error": false
	}
	
	# Case A: Internal room modification (Sub-modes/Variants)
	if is_only_change_mode:
		if current_place != next_place:
			push_error("[LevelManager] Error: Cannot change mode while attempting to switch rooms.")
			config["flag_error"] = true
			return config
		return _handle_internal_room_modes(current_place, mode, config)
		
	# Case B: Standard navigation between different rooms
	if current_place == next_place:
		push_error("[LevelManager] Error: Already in this room. Use is_only_change_mode=true instead.")
		config["flag_error"] = true
		return config
		
	return _handle_room_transitions(current_place, next_place, config)

# ==============================================================================
# PRIVATE METHODS (Internal Navigation Engine)
# ==============================================================================

## Handles room-to-room switching by validating paths against the declarative navigation map.
static func _handle_room_transitions(origin: int, destination: int, config: Dictionary) -> Dictionary:
	if NAVIGATION_MAP.has(origin) and destination in NAVIGATION_MAP[origin]:
		config["interaction_mode"] = 0 # All new rooms start in mode 0 (locked/cutscene)
		config["id_background_scene"] = destination 
		return config
		
	push_error("[LevelManager] Error: Illegal route requested from Room %d to Room %d" % [origin, destination])
	config["flag_error"] = true
	return config

## Handles logic and layout variants exclusively inside the current active room.
static func _handle_internal_room_modes(room: int, mode: int, config: Dictionary) -> Dictionary:
	config["id_background_scene"] = room
	
	match room:
		GameIDs.RoomID.INITIAL_ROOM:
			config["interaction_mode"] = mode
		GameIDs.RoomID.ROOM_3_DOORS:
			config["interaction_mode"] = 1 if mode == 1 else 2
		GameIDs.RoomID.ROOM_1_DOOR, GameIDs.RoomID.PARK:
			config["interaction_mode"] = 1
		_:
			config["flag_error"] = true
	return config

## [Domain Query] Returns the raw list of items to be instantiated
## in a specific scenario. Useful for pre-warming resources or validating plot conditions.
static func get_expected_room_items(room_id: int) -> Array:
	return StageItemManager.ROOM_ITEM_MANIFESTO.get(room_id, [])
