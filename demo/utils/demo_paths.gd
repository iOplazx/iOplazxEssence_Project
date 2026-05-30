## Centralized script to manage demo item file paths.
class_name DemoItemsRoute
extends RefCounted

# ==========================================
# BASE ROUTES
# ==========================================
const BASE_ROUTE = "res://"
const DEMO_ROUTE = BASE_ROUTE + "demo/"
const DEMO_ITEMS_ROUTE = DEMO_ROUTE + "items/"

# ==========================================
# SCENE PATHS
# ==========================================
const TESTROOMDOOR_SCENE = DEMO_ITEMS_ROUTE + "scene/TestRoomDoor.tscn"
