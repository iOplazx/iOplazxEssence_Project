class_name StageActorManager
extends RefCounted

const ActorID = {
	"PROTAGONIST" : 0,
	"SECONDARY" : 1
}

## Returns the layout configuration for a character based on the room and mode.
## [param room_id]: The current room from LevelManager.RoomID
## [param actor_id]: The character to place.
## [param placement_mode]: 0 for default, 1 for alternate positions, etc.
static func get_actor_placement(room_id: int, actor_id: int, placement_mode: int) -> Dictionary:
	# Valores por defecto seguros
	var config: Dictionary = {
		"position": Vector2.ZERO,
		"scale": Vector2.ONE,
		"is_visible": true,
		"flip_h": false # Por si necesitas que mire al lado contrario
	}
	
	match room_id:
		LevelManager.RoomID["INITIAL_ROOM"]:
			match actor_id:
				ActorID["PROTAGONIST"]:
					match placement_mode:
						0:
							# Posición estándar de tu personaje en el cuarto inicial
							config["position"] = Vector2(575, 180)
							config["scale"] = Vector2(0.5, 0.5)
						1:
							# Ejemplo: Posición alternativa (ej. asustada en una esquina)
							config["position"] = Vector2(200, 200)
							config["scale"] = Vector2(0.45, 0.45)
							
		LevelManager.RoomID["ROOM_3_DOORS"]:
			match actor_id:
				ActorID["PROTAGONIST"]:
					match placement_mode:
						0:
							config["position"] = Vector2(640, 200)
							config["scale"] = Vector2(0.6, 0.6)
							
	return config
