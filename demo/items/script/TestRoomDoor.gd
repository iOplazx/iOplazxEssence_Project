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

## Overrides the core hotspot interaction to route spatial navigation dynamically.
func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	super._on_hotspot_clicked(event, node)
	
	if not environment_interactable: 
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 1. NAVIGATION ROUTING
		# Check if the clicked interactive element matches the specific door to the Park
		if node.name == "ExampleDoor2":
			print("[%s] Navigation triggered via ExampleDoor2. Target: PARK" % name)
			
			# 2. EMIT CORE NAVIGATION SIGNAL
			# Parameters:
			# - next_place: GameIDs.RoomID.PARK (The destination scene ID)
			# - mode: 0 (Starts in Mode 0 as a clean slate / loading screen)
			# - is_only_mode: false (It's a full room switch, not an internal layout change)
			navigation_requested.emit(GameIDs.RoomID.PARK, 0, false)
