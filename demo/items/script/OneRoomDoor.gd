class_name OneRoomDoor
extends EssenceNavigationRoom 

func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	super._on_hotspot_clicked(event, node)
	
	if not environment_interactable: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Supongamos que la puerta física de regreso se llama "DoorTo3Doors" o "Slot0"
		# Mandamos: (Destino, Modo de interacción, ¿Es sólo cambio de modo?)
		# Como queremos volver a la de 3 puertas, mandamos su RoomID, modo 1, y false (rearga escena completa).
		navigation_requested.emit(LevelManager.RoomID["ROOM_3_DOORS"], 1, false)
