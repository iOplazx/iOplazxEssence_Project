class_name OneRoomDoor
extends EssenceNavigationRoom 

func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	# Mantenemos cualquier comportamiento base del framework (como logs o estados)
	super._on_hotspot_clicked(event, node)
	
	if not environment_interactable: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# 🚨 FILTRO DEL NODO: Solo si es la puerta técnica
		if node.name == "ExampleDoor1_1":
			print("[%s] ¡Validación exitosa! Se pulsó físicamente ExampleDoor1_1. Transicionando..." % name)
			
			# 🚀 Emitimos la señal 'navigation_requested' que heredamos de la madre
			navigation_requested.emit(LevelManager.RoomID["SAVE_SCENE"], 1, false)
