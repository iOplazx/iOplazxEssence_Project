class_name OneRoomDoor
extends EssenceNavigationRoom 

func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	# Maintain framework base behavior (logging, state tracking)
	super._on_hotspot_clicked(event, node)
	
	if not environment_interactable: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# NODE FILTER: Validate specific technical door node
		if node.name == "ExampleDoor1_1":
			print("[%s] Validation successful! Physical door ExampleDoor1_1 clicked. Transitioning..." % name)
			
			# Emit inherited 'navigation_requested' signal to request room change
			navigation_requested.emit(GameIDs.RoomID.SAVE_SCENE, 1, false)
