class_name LevelManager
extends RefCounted

const RoomID = {
	"INITIAL_ROOM" : 0,
	"ROOM_3_DOORS" : 1,
	"ROOM_1_DOOR" : 2
}

const BackgroundImageID = {
	"INITIAL_ROOM" : 0,
	"ROOM_3_DOORS" : 1,
	"ROOM_1_DOOR": 2,
}


# --- NUESTRO NAVHOST DECLARATIVO (Grafo de Navegación) ---
# Aquí registramos qué habitaciones están conectadas legalmente entre sí.
# Clave: Habitación Origen -> Valor: Lista de Habitaciones Destino Permitidas.
const NAVIGATION_MAP = {
	0: [1], # INITIAL_ROOM puede ir solo a la habitacion 3 doors.
	1: [0, 2], # ROOM_3_DOORS puede volver al inicio o ir a la de 1 puerta.
	2: [1]  # ROOM_1_DOOR puede volver a la habitacion 3 puertas.
}

## Calculates and returns the scenery configuration based on spatial transitions and interaction modes.
## [param current_place]: The ID of the room where the player is currently located.
## [param next_place]: The ID of the room the player wants to navigate to.
## [param mode]: The specific sub-mode or layout variant to apply within the room.
## [param is_only_change_mode]: If true, skips room reloading and only updates the internal interaction rules.
## Returns a Dictionary containing "id_room", "id_background_scene", "interaction_mode", and "flag_error".
static func get_scenery_config(current_place: int, next_place: int, mode: int, is_only_change_mode: bool) -> Dictionary:
	var config: Dictionary = {
		"id_room": next_place,         
		"id_background_scene": -1,    
		"interaction_mode": 0,
		"flag_error": false
	}
	
	# Caso A: Modificación interna del mismo cuarto (Sub-modos)
	if is_only_change_mode:
		if current_place != next_place:
			print("[LevelManager] Error: Cannot change mode while attempting to switch rooms.")
			config["flag_error"] = true
			return config
		return _handle_internal_room_modes(current_place, mode, config)
		
	# Caso B: Navegación estándar entre habitaciones diferentes
	if current_place == next_place:
		print("[LevelManager] Error: Already in this room. Use is_only_change_mode=true instead.")
		config["flag_error"] = true
		return config
		
	return _handle_room_transitions(current_place, next_place, config)


# ==============================================================================
# PRIVATE METHODS (Internal Navigation Engine)
# ==============================================================================

## Handles room-to-room switching by validating paths against the declarative navigation map.
static func _handle_room_transitions(origin: int, destination: int, config: Dictionary) -> Dictionary:
	# Verificamos si la ruta existe en nuestro mapa declarativo (Igual que buscar una ruta en Compose)
	if NAVIGATION_MAP.has(origin) and destination in NAVIGATION_MAP[origin]:
		#print("[LevelManager] Transition allowed. Navigating to room ID: ", destination)
		config["interaction_mode"] = 0 # Toda habitación nueva inicia bloqueada (modo diálogo)
		config["id_background_scene"] = destination # El ID de la habitación coincide con su imagen
		return config
		
	print("[LevelManager] Error: Unprogrammed or illegal route from Room %d to Room %d" % [origin, destination])
	config["flag_error"] = true
	return config


## Handles logic and layout variants exclusively inside the current active room.
static func _handle_internal_room_modes(room: int, mode: int, config: Dictionary) -> Dictionary:
	config["id_background_scene"] = room # Mantenemos el fondo actual
	
	match room:
		RoomID["INITIAL_ROOM"]:
			#print("No estamos cambiando de habitacion, activamos el modo 1/interactuable")
			config["interaction_mode"] = 1
			
		RoomID["ROOM_3_DOORS"]:
			if mode == 1:
				#print("Activamos el modo 1 osea el interactivo inicial")
				config["interaction_mode"] = 1
			else:
				#print("Activamos el modo 2, osea el interactivo con la puerta 3 incapaz de interactuar")
				config["interaction_mode"] = 2
				
		RoomID["ROOM_1_DOOR"]:
			#print("No estamos cambiando de habitacion, activamos el modo 1/interactuable")
			config["interaction_mode"] = 1
			
		_:
			print("[LevelManager] Error: Room has no internal mode behaviors programmed.")
			config["flag_error"] = true
			
	return config
