## [NPCWardrobeGroup] - Specific to park NPCs
extends EssenceWardrobeGroup
class_name NPCWardrobeGroup

@export_category("Mapeo Ciudadanos")

@export var npc_wardrobe: Dictionary[IDsNPCModular.Items, Node2D] = {}

func _ready() -> void:
	registry = npc_wardrobe
