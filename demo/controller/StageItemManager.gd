class_name StageItemManager
extends RefCounted

const ItemID = {
	"PHONE_ICON": 0,
	"BACKPACK_ICON": 1,
	"NOTEBOOK": 2,
	"DOOR_SPRITE":4
}

# ==============================================================================
# 🎯 TABLA DE POSICIONES GLOBALES (VALORES FIJOS POR DEFECTO)
# ==============================================================================
# Aquí registras dónde viven los ítems normalmente en todo el juego.
# Si una habitación no dice lo contrario, se usará esta coordenada automáticamente.
const GLOBAL_DEFAULTS = {
	0: {"position": Vector2(1150, 80), "scale": Vector2(0.6, 0.6), "is_visible": true},  # PHONE_ICON (Esquina sup. der.)
	1: {"position": Vector2(1150, 200), "scale": Vector2(0.6, 0.6), "is_visible": true}, # BACKPACK_ICON (Debajo del fóno)
	2: {"position": Vector2(80, 80), "scale": Vector2(0.5, 0.5), "is_visible": true}     # NOTEBOOK (Esquina sup. izq.)
}


## Returns layout configuration, prioritizing room overrides, falling back to global defaults.
## [param room_id]: The current room from LevelManager.RoomID
## [param item_id]: The item to place.
## [param mode]: The specific sub-mode or layout variant.
static func get_item_placement(room_id: int, item_id: int, mode: int) -> Dictionary:
	# 1. PASO BASE: Cargamos el valor global por defecto si existe
	var config: Dictionary = {
		"position": Vector2.ZERO,
		"scale": Vector2.ONE,
		"is_visible": true
	}
	
	if GLOBAL_DEFAULTS.has(item_id):
		# Usamos .duplicate() para clonar el diccionario y no modificar el original en memoria
		config = GLOBAL_DEFAULTS[item_id].duplicate()
		
	# 2. PASO DE ANULACIÓN (OVERRIDES): Buscamos variantes específicas por escenario
	# Aquí SOLO escribes código para las habitaciones donde el objeto cambie de lugar.
	match room_id:
		LevelManager.RoomID["INITIAL_ROOM"]:
			match item_id:
				ItemID["PHONE_ICON"]:
					match mode:
						1: # Variante: El teléfono se teletransporta al centro porque está sonando
							config["position"] = Vector2(640, 360)
							config["scale"] = Vector2(1.0, 1.0)
				ItemID["DOOR_SPRITE"]:			
					config["position"] = Vector2(48, 593)
					config["scale"] = Vector2(0.2, 0.2)
							
		LevelManager.RoomID["ROOM_3_DOORS"]:
			match item_id:
				ItemID["BACKPACK_ICON"]:
					match mode:
						2: # Variante de historia: Alguien te roba la mochila, se vuelve invisible en este modo
							config["is_visible"] = false
				ItemID["DOOR_SPRITE"]:
					match mode:
						0:
							config["position"] = Vector2(48, 593)
							config["scale"] = Vector2(0.2, 0.2)
						1: 
							config["position"] = Vector2(1223, 593)
							config["scale"] = Vector2(0.2, 0.2)
		LevelManager.RoomID["ROOM_1_DOOR"]:
			match item_id:
				ItemID["DOOR_SPRITE"]:			
					config["position"] = Vector2(1223, 593)
					config["scale"] = Vector2(0.2, 0.2)
							
	return config
