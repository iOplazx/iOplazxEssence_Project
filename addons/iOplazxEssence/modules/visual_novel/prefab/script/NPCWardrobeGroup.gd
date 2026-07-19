## [NPCWardrobeGroup] - Específico para los NPCs del parque
extends EssenceWardrobeGroup
class_name NPCWardrobeGroup

@export_category("Mapeo Ciudadanos")
## ¡Desplegable exclusivo con las chaquetas y bigotes de los NPCs!
@export var npc_wardrobe: Dictionary[IDsNPCModular.Items, Node2D] = {}

func _ready() -> void:
	registry = npc_wardrobe
