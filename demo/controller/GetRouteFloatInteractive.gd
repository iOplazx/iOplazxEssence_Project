# ==============================================================================
# SCRIPT: GetRouteInteractive.gd
# DESCRIPTION: Central resolver mapping GameIDs.RoomID to Interactive Hotspot scenes (.tscn).
# ==============================================================================

class_name GetRouteFloatInteractive
extends RefCounted

## Manifest mapping RoomIDs to DemoItemsRoute interactive scene constants
const INTERACTIVE_MANIFEST: Dictionary = {
	GameIDs.RoomID.ROOM_3_DOORS: DemoItemsRoute.TESTROOMDOOR_SCENE,
	GameIDs.RoomID.ROOM_1_DOOR:  DemoItemsRoute.ONEDOORROOM_SCENE,
	# INITIAL_ROOM y PARK no tienen hotspot scene fija o usan solo elementos dinámicos
}


## Resolves and returns the .tscn scene path bound to a specific RoomID
static func get_interactive_path(room_id: int) -> String:
	return INTERACTIVE_MANIFEST.get(room_id, "")
