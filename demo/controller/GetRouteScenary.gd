# ==============================================================================
# SCRIPT: GetRouteScenary.gd
# DESCRIPTION: Bridge mapping GameIDs.RoomID to DemoItemsRoute constants.
# ==============================================================================

class_name GetRouteScenary
extends RefCounted

## Manifest mapping RoomIDs to DemoItemsRoute scene path constants
const ROOM_SCENERY_MANIFEST: Dictionary = {
	GameIDs.RoomID.INITIAL_ROOM: DemoItemsRoute.SCENERY_MAIN_ROOM_SCENE,
	GameIDs.RoomID.ROOM_3_DOORS: DemoItemsRoute.SCENERY_THREE_DOORS_ROOM_SCENE,
	GameIDs.RoomID.ROOM_1_DOOR: DemoItemsRoute.SCENERY_ONE_DOOR_ROOM_SCENE,
	GameIDs.RoomID.PARK: DemoItemsRoute.SCENERY_THE_PARK_SCENE
}


## Resolves and returns the .tscn scene path bound to a specific RoomID
static func get_scenery_path(room_id: int) -> String:
	return ROOM_SCENERY_MANIFEST.get(room_id, "")
