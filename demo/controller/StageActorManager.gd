class_name StageActorManager
extends RefCounted

## Returns the layout configuration for a character based on the room and mode.
## [param room_id]: The current room from LevelManager.RoomID
## [param actor_id]: The character to place.
## [param placement_mode]: 0 for default, 1 for alternate positions, etc.
static func get_actor_placement(room_id: int, actor_id: int, placement_mode: int) -> Dictionary:
	var config = {"position": Vector2.ZERO, "scale": Vector2.ONE, "is_visible": true, "flip_h": false}
	
	match room_id:
		GameIDs.RoomID.INITIAL_ROOM:
			match actor_id:
				GameIDs.ActorID.PROTAGONIST:
					config["position"] = Vector2(575, 180) if placement_mode == 0 else Vector2(200, 200)
					config["scale"] = Vector2(0.5, 0.5) if placement_mode == 0 else Vector2(0.45, 0.45)
					
		GameIDs.RoomID.ROOM_3_DOORS:
			match actor_id:
				GameIDs.ActorID.PROTAGONIST:
					config["position"] = Vector2(640, 200)
					config["scale"] = Vector2(0.6, 0.6)
	return config
