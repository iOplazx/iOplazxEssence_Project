## [GenericModularCharacter]
## Passive filler actor. Uses its own ID file
## and leverages the grouping constant to randomly change color.
class_name GenericModularCharacter
extends EssenceModularActor

# ==
# ESTRUCTURA DE LA ESCENA PROCESADA:
# ==
#GenericModularCharacter (Node2D) [Script: GenericModularCharacter]
#└── SubViewportContainer
#    └── SubViewport
#        └── Visuals (Node2D)
#            └── Pose_Normal (Node2D) [NPCWardrobeGroup] ───> Control de Pose 1
#                ├── BaseBody (Sprite2D)
#                └── Wardrobe (Node2D)
#                    ├── Jacket1 (Sprite2D)
#                    ├── Jacket2 (Sprite2D)
#                    ...
#                    └── Mustache (Sprite2D)

@export_category("NPC Pose Configuration")

@export var npc_poses: Dictionary[IDsNPCModular.Poses, NPCWardrobeGroup] = {}

func _ready() -> void:
	# We transmit the exclusive NPC dictionary to the father.
	poses_registry = npc_poses
	super._ready()
	_randomize_appearance()

func _randomize_appearance() -> void:
	randomize()
	var jacket_pool = IDsNPCModular.JACKET_COLOR_GROUP
	
	for jacket_id in jacket_pool:
		modify_clothing(int(jacket_id), false)
		
	if not jacket_pool.is_empty():
		var random_index: int = randi() % jacket_pool.size()
		var chosen_jacket_id: int = jacket_pool[random_index]
		modify_clothing(int(chosen_jacket_id), true)
		
	var has_mustache: bool = (randi() % 2 == 0)
	modify_clothing(IDsNPCModular.Items.MUSTACHE, has_mustache)
