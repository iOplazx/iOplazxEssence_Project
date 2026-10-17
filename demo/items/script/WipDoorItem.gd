class_name WipDoorItem
extends EssenceGenericActionItem

## Se ejecuta automáticamente al hacer clic gracias al addon genérico.
func _on_custom_action() -> void:
	_execute_wip_return()

## Lógica central para regresar de forma segura a la sala guardada en el LevelManager.
func _execute_wip_return() -> void:
	var return_room_id: int = LevelManager.last_room_before_wip
	
	if return_room_id <= 0:
		return_room_id = GameIDs.RoomID.INITIAL_ROOM
		
	print("[WIP Door - Demo] Regresando a la sala: %d" % return_room_id)
	
	# Búsqueda blindada: Primero intenta con la escena actual del árbol
	var main_game = get_tree().current_scene
	if not is_instance_valid(main_game) or not main_game.has_method("_on_room_navigation_requested"):
		# Fallback por si la escena actual no es el TestMainGame directamente
		main_game = get_tree().get_first_node_in_group("MainGame")
		
	if is_instance_valid(main_game) and main_game.has_method("_on_room_navigation_requested"):
		main_game._on_room_navigation_requested(return_room_id, 0, false)
	else:
		EssenceReportUtils.critical("Navigation Error", "MainGame controller not found from WIP Door.")
