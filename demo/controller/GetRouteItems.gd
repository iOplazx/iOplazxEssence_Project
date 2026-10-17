# ==============================================================================
# SCRIPT: GetRouteItems.gd
# DESCRIPTION: Central resolver mapping GameIDs.ItemID to DemoItemsRoute constants.
# ==============================================================================

class_name GetRouteItems
extends RefCounted

## Manifest mapping ItemIDs to DemoItemsRoute scene path constants
const ITEM_MANIFEST: Dictionary = {
	GameIDs.ItemID.DOOR_SPRITE:     DemoItemsRoute.ITEMDOOR_SCENE,
	GameIDs.ItemID.HOUSE_SPRITE:    DemoItemsRoute.ITEMHOUSE_SCENE,
	GameIDs.ItemID.TOUCH_INDICATOR: DemoItemsRoute.ITEMTOUCH_SCENE,
	GameIDs.ItemID.WIP_DOOR_EXIT:   DemoItemsRoute.ITEMWIPDOOR_SCENE
}

## Resolves and returns the .tscn scene path bound to a specific ItemID
static func get_item_path(item_id: int) -> String:
	return ITEM_MANIFEST.get(item_id, "")
