## [GICWardrobeGroup] - Específico para el héroe
extends EssenceWardrobeGroup
class_name GICWardrobeGroup

@export_category("Mapeo Protagonista")

@export var local_wardrobe: Dictionary[IDsGIC.Items, Node2D] = {}

func _ready() -> void:
	# We pass our convenient dictionary to the parent's generic engine.
	registry = local_wardrobe
