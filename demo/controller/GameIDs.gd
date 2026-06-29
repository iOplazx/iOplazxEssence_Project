class_name GameIDs
extends RefCounted

# ==============================================================================
# 🚪 IDENTIFICADORES ÚNICOS DE ESCENARIOS
# ==============================================================================
const RoomID = {
	"INITIAL_ROOM" : 0,
	"ROOM_3_DOORS" : 1,
	"ROOM_1_DOOR" : 2,
	"PARK"         : 3,
	"SAVE_SCENE"   : 29
}

# ==============================================================================
# 🎯 IDENTIFICADORES ÚNICOS DE ÍTEMS INTERACTUABLES
# ==============================================================================
const ItemID = {
	"PHONE_ICON"    : 0,
	"BACKPACK_ICON" : 1,
	"NOTEBOOK"      : 2,
	"DOOR_SPRITE"   : 4,
	"HOUSE_SPRITE"  : 5,
	"TOUCH_INDICATOR": 6
}

# ==============================================================================
# 👥 IDENTIFICADORES ÚNICOS DE ACTORES / NPCS
# ==============================================================================
const ActorID = {
	"PROTAGONIST" : 0,
	"SECONDARY"   : 1
}

## Operadores lógicos para evaluar en qué momento de la historia vive el objeto
enum StageCondition {
	EQUAL,          # ==
	GREATER,        # >
	GREATER_EQUAL,  # >=
	LESS,           # <
	LESS_EQUAL      # <=
}
