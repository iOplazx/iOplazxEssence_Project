## [GenericInteractiveCharacter]
## Specialized interactive component. Keeps its abstraction clean
## by delegating all visual and wardrobe management to its pad class
extends EssenceInteractiveActor
class_name GenericInteractiveCharacter

# ==
# ESTRUCTURA DE LA ESCENA PROCESADA:
# ==
#GenericInteractiveCharacter (Node2D) [Script: GenericInteractiveCharacter]
#└── SubViewportContainer
#    └── SubViewport
#        └── Visuals (Node2D)
#            ├── Pose_Normal (Node2D) [GICPoseComponent] ───> Control de Pose 1
#            │   ├── BaseBody (Sprite2D)
#            │   └── Wardrobe (Node2D)
#            │       └── Shirt (Sprite2D) 
#            ├── Pose_Action (Node2D) [GICPoseComponent] ───> Control de Pose 2
#            │   ├── BaseBody (Sprite2D)
#            │   └── Wardrobe (Node2D)
#            │       └── Shirt_V2 (Sprite2D) 
#            └── CommonClothes (Node2D) ───> Contenedor maestro invisible
#                └── Group_Normal_Action (Node2D) [GICWardrobeGroup] <── Tu "testClothesFixed"
#                    ├── Belt (Sprite2D)
#                    ├── Hat (Sprite2D)
#                    ├── Pant (Sprite2D)
#                    ├── Shoes (Sprite2D)
#                    └── Sunglass (Sprite2D)

@export_category("GIC Pose Configuration")
## Clean dropdown in the Inspector with IDsGIC.Poses!
@export var gic_poses: Dictionary[IDsGIC.Poses, GICPoseComponent] = {}

func _ready() -> void:
	poses_registry = gic_poses
	# Call the parent's master initializer (EssenceModularActor)
	# to build the initial inventory and initialize the poses.
	super._ready() 	


# ==========================================
# AREA CLICK DETECTION
# ==========================================
func _on_interact_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_interactable:
			# We are broadcasting the official Framework signal.
			clicked_on_character.emit()
			
			# We consume the click so it doesn't keep passing through the screen.
			get_viewport().set_input_as_handled()
