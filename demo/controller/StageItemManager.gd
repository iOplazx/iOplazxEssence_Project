class_name StageItemManager
extends RefCounted

const ItemID = {
	"PHONE_ICON": 0,
	"BACKPACK_ICON": 1,
	"NOTEBOOK": 2,
	"DOOR_SPRITE": 4,
	"HOUSE_SPRITE": 5
}

# ==============================================================================
# 📋 MANIFIESTO DE ESCENARIOS (Qué ítems existen en cada habitación)
# ==============================================================================
# Cambiamos las claves numéricas crudas por las constantes tipadas del archivo central.
const ROOM_ITEM_MANIFESTO = {
	GameIDs.RoomID.INITIAL_ROOM: [
		{"item_id": GameIDs.ItemID.PHONE_ICON, "mode": 0, "destination": -1},
		{"item_id": GameIDs.ItemID.NOTEBOOK, "mode": 0, "destination": -1},
		{"item_id": GameIDs.ItemID.DOOR_SPRITE, "mode": 0, "destination": GameIDs.RoomID.ROOM_3_DOORS}
	],
	GameIDs.RoomID.ROOM_3_DOORS: [
		{"item_id": GameIDs.ItemID.DOOR_SPRITE, "mode": 0, "destination": GameIDs.RoomID.ROOM_1_DOOR}, # Puerta Izq
		{"item_id": GameIDs.ItemID.DOOR_SPRITE, "mode": 1, "destination": GameIDs.RoomID.INITIAL_ROOM}, # Puerta Der
		{"item_id": GameIDs.ItemID.BACKPACK_ICON, "mode": 0, "destination": -1}
	],
	GameIDs.RoomID.ROOM_1_DOOR: [
		{"item_id": GameIDs.ItemID.PHONE_ICON, "mode": 0, "destination": -1},
		{"item_id": GameIDs.ItemID.BACKPACK_ICON, "mode": 0, "destination": -1},
		{"item_id": GameIDs.ItemID.DOOR_SPRITE, "mode": 0, "destination": GameIDs.RoomID.ROOM_3_DOORS}
	],
	GameIDs.RoomID.PARK: [
		{"item_id": GameIDs.ItemID.HOUSE_SPRITE, "mode": 0, "destination": GameIDs.RoomID.ROOM_3_DOORS}, # Casita de regreso
		{"item_id": GameIDs.ItemID.PHONE_ICON, "mode": 0, "destination": -1}
	]
}

# ==============================================================================
# 🎯 TABLA DE POSICIONES GLOBALES (VALORES FIJOS POR DEFECTO)
# ==============================================================================
const GLOBAL_DEFAULTS = {
	0: {"position": Vector2(1150, 80), "scale": Vector2(0.6, 0.6), "is_visible": true},  # PHONE_ICON
	1: {"position": Vector2(1150, 200), "scale": Vector2(0.6, 0.6), "is_visible": true}, # BACKPACK_ICON
	2: {"position": Vector2(80, 80), "scale": Vector2(0.5, 0.5), "is_visible": true}     # NOTEBOOK
}

## Returns layout configuration, prioritizing room overrides, falling back to global defaults.
static func get_item_placement(room_id: int, item_id: int, mode: int) -> Dictionary:
	var config: Dictionary = {
		"position": Vector2.ZERO,
		"scale": Vector2.ONE,
		"is_visible": true
	}
	
	if GLOBAL_DEFAULTS.has(item_id):
		config = GLOBAL_DEFAULTS[item_id].duplicate()
		
	match room_id:
		GameIDs.RoomID.INITIAL_ROOM:
			match item_id:
				GameIDs.ItemID.PHONE_ICON:
					if mode == 1:
						config["position"] = Vector2(640, 360)
						config["scale"] = Vector2(1.0, 1.0)
				GameIDs.ItemID.DOOR_SPRITE:			
					config["position"] = Vector2(48, 593)
					config["scale"] = Vector2(0.2, 0.2)
							
		GameIDs.RoomID.ROOM_3_DOORS:
			match item_id:
				GameIDs.ItemID.BACKPACK_ICON:
					if mode == 2: 
						config["is_visible"] = false
				GameIDs.ItemID.DOOR_SPRITE:
					match mode:
						0:
							config["position"] = Vector2(48, 593)
							config["scale"] = Vector2(0.2, 0.2)
						1: 
							config["position"] = Vector2(1223, 593)
							config["scale"] = Vector2(0.2, 0.2)
						2: 
							config["position"] = Vector2(640, 593)
							config["scale"] = Vector2(0.2, 0.2)

		GameIDs.RoomID.ROOM_1_DOOR:
			match item_id:
				GameIDs.ItemID.DOOR_SPRITE:			
					config["position"] = Vector2(1223, 593)
					config["scale"] = Vector2(0.2, 0.2)

		GameIDs.RoomID.PARK:
			match item_id:
				GameIDs.ItemID.HOUSE_SPRITE:
					config["position"] = Vector2(250, 480)
					config["scale"] = Vector2(1.0, 1.0)
							
	return config
