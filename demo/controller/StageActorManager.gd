class_name StageActorManager
extends RefCounted

## Dictionary key constants to ensure compile-time safety.
const KEY_ACTOR_ID: String = "actor_id"
const KEY_POSITION: String = "position"
const KEY_SCALE: String = "scale"
const KEY_ROTATION: String = "rotation"
const KEY_ORIENTATION_VIEW: String = "orientation_view"
const KEY_IS_VISIBLE: String = "is_visible"
const KEY_FLIP_H: String = "flip_h"

enum Phases {
	TO_BE_DEFINED,
	PROTAGONIST_BASE
}

enum Orientation_View {
	NORMAL,
	MIRROR,
	TO_UP, 
	TO_DOWN
}

# 1. OPTIMIZATION LAYER: Define the shared layout data once in a local constant.
# This prevents duplicating dictionaries in RAM for different modes.
const _PROTAGONIST_INITIAL_DATA: Array = [
	{
		KEY_ACTOR_ID: GameIDs.ActorID.PROTAGONIST,
		KEY_POSITION: Vector2(637, 893), 
		KEY_SCALE: Vector2(0.5, 0.5),
		KEY_ROTATION: 0,
		KEY_ORIENTATION_VIEW: Orientation_View.NORMAL
	}
]

## Declarative database: Maps Room IDs to their respective Layout Modes and Actor blueprints.
const ROOM_ACTOR_MANIFESTO: Dictionary = {
	GameIDs.RoomID.INITIAL_ROOM: {
		# Both modes point to the exact same array reference in memory
		GameIDs.RoomModeState.INITIAL_ROOM_NORMAL: _PROTAGONIST_INITIAL_DATA,
		GameIDs.RoomModeState.INITIAL_ROOM_MODE_2: _PROTAGONIST_INITIAL_DATA
	},
	GameIDs.RoomID.PARK: {
		GameIDs.RoomModeState.PARK_NORMAL: [ 
			{
				KEY_ACTOR_ID: GameIDs.ActorID.PARK_PERSON_SIT_1,
				KEY_POSITION: Vector2(288, 500),
				KEY_SCALE: Vector2(0.23, 0.23),
				KEY_ROTATION: -11.4, #-11.4°
				KEY_ORIENTATION_VIEW: Orientation_View.NORMAL
			},
			{
				KEY_ACTOR_ID: GameIDs.ActorID.PARK_PERSON_SIT_2,
				KEY_POSITION: Vector2(988, 386),
				KEY_SCALE: Vector2(0.07, 0.07),
				KEY_ROTATION: 0,
				KEY_ORIENTATION_VIEW: Orientation_View.NORMAL
			},
			{
				KEY_ACTOR_ID: GameIDs.ActorID.PARK_PERSON_SIT_3,
				KEY_POSITION: Vector2(83, 573),
				KEY_SCALE: Vector2(0.25, 0.25),
				KEY_ROTATION: 0,
				KEY_ORIENTATION_VIEW: Orientation_View.NORMAL
			},
			{
				KEY_ACTOR_ID: GameIDs.ActorID.PARK_DOG_1,
				KEY_POSITION: Vector2(802, 497),
				KEY_SCALE: Vector2(0.2, 0.2),
				KEY_ROTATION: 0,
				KEY_ORIENTATION_VIEW: Orientation_View.NORMAL
			},
			{
				KEY_ACTOR_ID: GameIDs.ActorID.SECONDARY,
				KEY_POSITION: Vector2(724, 712),
				KEY_SCALE: Vector2(0.3, 0.3),
				KEY_ROTATION: 0,
				KEY_ORIENTATION_VIEW: Orientation_View.NORMAL
			}
		]
	}
}

## Returns the exact blueprint configuration for a specific character inside a room layout.
## [param room_id]: The active Room ID from GameIDs.RoomID.
## [param actor_id]: The target Character ID from GameIDs.ActorID.
## [param placement_mode]: The active variant or phase of the current layout.
static func get_actor_placement(room_id: int, actor_id: int, placement_mode: int) -> Dictionary:
	# 1. FALLBACK BASELINE
	var default_config: Dictionary = {
		KEY_POSITION: Vector2.ZERO, 
		KEY_SCALE: Vector2.ONE, 
		KEY_ROTATION: 0,
		KEY_ORIENTATION_VIEW: Orientation_View.NORMAL,
		KEY_IS_VISIBLE: false, 
		KEY_FLIP_H: false
	}
	
	# 2. DICTIONARY DRILL DOWN
	var modes: Dictionary = ROOM_ACTOR_MANIFESTO.get(room_id, {})
	var actor_list: Array = modes.get(placement_mode, [])
	
	# 3. SEARCH AND RETURN TARGET ACTOR DATA
	for actor_data in actor_list:
		if actor_data.get(KEY_ACTOR_ID) == actor_id:
			var result = actor_data.duplicate()
			result[KEY_IS_VISIBLE] = true
			return result
			
	return default_config
