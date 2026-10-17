class_name WipDoorItem
extends EssenceGenericActionItem

## Aquí la demo implementa su propia lógica usando sus propios managers (LevelManager, etc.)
func _on_custom_action() -> void:
	var return_room_id: int = LevelManager.last_room_before_wip
	
	if return_room_id <= 0:
		return_room_id = GameIDs.RoomID.INITIAL_ROOM
		
	print("[WIP Door - Demo] Regresando a la sala: %d" % return_room_id)
	
	var main_game = get_tree().get_first_node_in_group("MainGame")
	if is_instance_valid(main_game) and main_game.has_method("_on_room_navigation_requested"):
		main_game._on_room_navigation_requested(return_room_id, 0, false)
