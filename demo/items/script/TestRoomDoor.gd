class_name TestRoomDoor
extends EssenceNavigationRoom

# ==
# TestRoomDoor.tscn
# ==
# TestRoomDoor (TestRoomDoor) [Script: TestRoomDoor]
# ├── StageBackground (TextureRect)    # imagen guia                 
# ├── FixedHotspots (Node2D)   
# │   ├── ExampleDoor (Area2D)   
# │       ├── Sprite2D (Sprite2D)           
# │       └── CollisionShape2D (CollisionShape2D)          
# │   ├── ExampleDoor2 (Area2D)   
# │       ├── Sprite2D (Sprite2D)           
# │       └── CollisionShape2D (CollisionShape2D)      
# │   ├── ExampleDoor3 (Area2D)   
# │       ├── Sprite2D (Sprite2D)           
# │       └── CollisionShape2D (CollisionShape2D)   
# └── DynamicHotspots (Node2d)  #Heredado de la escena anterior, no usado por ahora.                  
#     └── ... (no uso)
# ==

## Sobrescribimos el clic para enviar los datos dinámicos correctos
func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	super._on_hotspot_clicked(event, node)
	
	if not environment_interactable: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Aquí interceptas qué nodo se tocó y mandas los 3 parámetros correspondientes
		# Nota: Si usas '_spawn_navigation_door', el sistema ya le inyecta los destinos a los DynamicDoors,
		# pero si tienes puertas estáticas, puedes mapearlas aquí mismo.
		pass
