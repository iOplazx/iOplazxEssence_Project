## Centralized script to manage demo item file paths.
class_name DemoItemsRoute
extends RefCounted

#Extension shortcut
const EXTENSION_PNG = ".png"
const EXTENSION_TSCN = ".tscn"

# ==========================================
# BASE ROUTES
# ==========================================
const BASE_ROUTE = "res://"
const DEMO_ROUTE = BASE_ROUTE + "demo/"
const DEMO_ITEMS_ROUTE = DEMO_ROUTE + "items/"
const DEMO_ITEMS_INDIVIDUAL_ROUTE = DEMO_ITEMS_ROUTE + "individual/"
const DEMO_ITEMS_ACTOR_ROUTE = DEMO_ITEMS_ROUTE + "actors/"
const OVERLOAD_ADDON_ROUTE = BASE_ROUTE + "overloadAddon/"
const DEMO_NON_OWN_ROUTE = DEMO_ROUTE + "non_own_resources/"

# ==========================================
# SCENE PATHS
# ==========================================
const TESTMAINGAME_SCENE = DEMO_ROUTE + "TestMainGame" + EXTENSION_TSCN
const TESTSAVESCENE_SCENE = OVERLOAD_ADDON_ROUTE + "test_save_scene" + EXTENSION_TSCN

const TESTROOMDOOR_SCENE = DEMO_ITEMS_ROUTE + "scene/TestRoomDoor" + EXTENSION_TSCN
const ONEDOORROOM_SCENE = DEMO_ITEMS_ROUTE + "scene/OneDoorRoom" + EXTENSION_TSCN
const ITEMDOOR_SCENE = DEMO_ITEMS_INDIVIDUAL_ROUTE + "ItemDoor" + EXTENSION_TSCN
const ITEMHOUSE_SCENE = DEMO_ITEMS_INDIVIDUAL_ROUTE + "ItemHouse" + EXTENSION_TSCN
const ITEMTOUCH_SCENE = DEMO_ITEMS_INDIVIDUAL_ROUTE + "ItemTouch" + EXTENSION_TSCN

const ACTOR_PARK_DOG_RUN_SCENE = DEMO_ITEMS_ACTOR_ROUTE + "ActorParkDogRun.tscn"
const ACTOR_PARK_PERSON_SIT_1_SCENE = DEMO_ITEMS_ACTOR_ROUTE + "ActorParkPersonSit1.tscn"
const ACTOR_PARK_PERSON_SIT_2_SCENE = DEMO_ITEMS_ACTOR_ROUTE + "ActorParkPersonSit2.tscn"
const ACTOR_PARK_PERSON_SIT_3_SCENE = DEMO_ITEMS_ACTOR_ROUTE + "ActorParkPersonSit3.tscn"

const TEST_SHIRT_MINIGAME_SCENE = DEMO_ROUTE + "TestShirtMinigame" + EXTENSION_TSCN

# ==========================================
# RESOURCE Non Own
# ==========================================
const SPRITE_SIT_PERSON = DEMO_NON_OWN_ROUTE + "prawny-vintage-1892128.png"
