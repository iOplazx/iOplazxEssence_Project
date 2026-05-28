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
	
	match current_place:
		RoomID["INITIAL_ROOM"]:
			match next_place:
				RoomID["INITIAL_ROOM"]:
					if is_only_change_mode:
						print("No estamos cambiando de habitacion, activamos el modo 1/interactuable")
						config["interaction_mode"] = 1
					else:
						print("Error ya estas en esa habitacion")
						config["flag_error"] = true
				RoomID["ROOM_3_DOORS"]:
					print("Ir a la habitacion de 3 puertas")
					config["interaction_mode"] = 0
					config["id_background_scene"] = BackgroundImageID["ROOM_3_DOORS"] 
				RoomID["ROOM_1_DOOR"]:
					print("Ir a la habitacion de 1 puerta")
					config["interaction_mode"] = 0
					config["id_background_scene"] = BackgroundImageID["ROOM_1_DOOR"]
				_:
					print("Estas llendo a un lugar que no esta programado aun.")
					config["flag_error"] = true
					
		RoomID["ROOM_3_DOORS"]:
			match next_place:
				RoomID["INITIAL_ROOM"]:
					print("Ir a la habitacion inicial")
					config["interaction_mode"] = 0
					config["id_background_scene"] = BackgroundImageID["INITIAL_ROOM"] 
				RoomID["ROOM_3_DOORS"]:
					if is_only_change_mode:
						if mode == 1:
							print("Activamos el modo 1 osea el interactivo inicial")
							config["interaction_mode"] = 1
						else:
							print("Activamos el modo 2, osea el interactivo con la puerta 3 incapaz de interactuar")
							config["interaction_mode"] = 2
					else:
						print("Error ya estas en esa habitacion")
						config["flag_error"] = true
				RoomID["ROOM_1_DOOR"]:
					print("Ir a la habitacion de 1 puerta")
					config["interaction_mode"] = 0
					config["id_background_scene"] = BackgroundImageID["ROOM_1_DOOR"]
				_:
					print("Estas llendo a un lugar que no esta programado aun.")
					config["flag_error"] = true
					
		RoomID["ROOM_1_DOOR"]:
			match next_place:
				RoomID["INITIAL_ROOM"]:
					print("Ir a la habitacion inicial")
					config["interaction_mode"] = 0
					config["id_background_scene"] = BackgroundImageID["INITIAL_ROOM"]
				RoomID["ROOM_3_DOORS"]:
					print("Ir a la habitacion de 3 puertas")
					config["interaction_mode"] = 0
					config["id_background_scene"] = BackgroundImageID["ROOM_3_DOORS"]
				RoomID["ROOM_1_DOOR"]:
					if is_only_change_mode:
						print("No estamos cambiando de habitacion, activamos el modo 1/interactuable")
						config["interaction_mode"] = 1
					else:
						print("Error ya estas en esa habitacion")
						config["flag_error"] = true
				_:
					print("Estas llendo a un lugar que no esta programado aun.")
					config["flag_error"] = true
		_:
			print("No se obtuvo el valor de la habitacion actual de manera correcta")
			config["flag_error"] = true
			
	return config
	
