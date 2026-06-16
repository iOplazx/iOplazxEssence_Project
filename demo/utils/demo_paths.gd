## Centralized script to manage demo item file paths.
class_name DemoItemsRoute
extends RefCounted

# ==========================================
# BASE ROUTES
# ==========================================
const BASE_ROUTE = "res://"
const DEMO_ROUTE = BASE_ROUTE + "demo/"
const DEMO_ITEMS_ROUTE = DEMO_ROUTE + "items/"
const DEMO_ITEMS_INDIVIDUAL_ROUTE = DEMO_ITEMS_ROUTE + "individual/"

# ==========================================
# SCENE PATHS
# ==========================================
const TESTROOMDOOR_SCENE = DEMO_ITEMS_ROUTE + "scene/TestRoomDoor.tscn"
const ONEDOORROOM_SCENE = DEMO_ITEMS_ROUTE + "scene/OneDoorRoom.tscn"
const ITEMDOOR_SCENE = DEMO_ITEMS_INDIVIDUAL_ROUTE + "ItemDoor.tscn"
