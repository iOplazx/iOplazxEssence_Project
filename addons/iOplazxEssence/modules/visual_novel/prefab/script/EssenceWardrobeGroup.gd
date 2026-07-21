## [EssenceWardrobeGroup]
## Clase base abstracta. No expone nada al Inspector por sí misma.
## Contiene la lógica matemática y física de sincronización.
extends Node2D
class_name EssenceWardrobeGroup

## Diccionario genérico en RAM que usarán los métodos internos.
var registry: Dictionary = {}


func hide_all_registered() -> void:
	for node in registry.values():
		if is_instance_valid(node): 
			node.visible = false


func sync_equipped_items(equipped_list: Array) -> void:
	for item_id in registry.keys():
		var node = registry[item_id]
		if is_instance_valid(node):
			var should_be_visible: bool = int(item_id) in equipped_list
			node.visible = should_be_visible
		
