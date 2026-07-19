## [GICWardrobeGroup] - Específico para el héroe
extends EssenceWardrobeGroup
class_name GICWardrobeGroup

@export_category("Mapeo Protagonista")
## ¡BOOM! Al tiparlo con IDsGIC.Items, el Inspector te da el menú desplegable limpio.
@export var local_wardrobe: Dictionary[IDsGIC.Items, Node2D] = {}

func _ready() -> void:
	# Le pasamos nuestro diccionario cómodo al motor genérico del padre
	registry = local_wardrobe
