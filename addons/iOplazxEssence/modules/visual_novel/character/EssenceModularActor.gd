## [EssenceModularActor]
## Clase base del framework encargada de la gestión modular de apariencias,
## control seguro de posturas y sincronización de prendas mediante IDs inmutables.
class_name EssenceModularActor
extends EssenceActor

@export_category("Base Modular Configuration")
## La pose entera activa inicial.
@export var current_pose_id: int = 1

## Registro visual indexado por enteros (Pose ID -> Nodo del Grupo Visual)
@export var poses_registry: Dictionary[int, EssenceWardrobeGroup] = {}

## Lista maestra que guarda los enteros de la ropa que el personaje lleva puesta (Save State).
var _equipped_items: Array[int] = []


func _ready() -> void:
	super._ready()
	_sync_modular_initial_state()


func _sync_modular_initial_state() -> void:
	for pose_id in poses_registry.keys():
		var pose_node = poses_registry[pose_id]
		if is_instance_valid(pose_node):
			pose_node.visible = (pose_id == current_pose_id)
			
	# Hornear inventario inicial analizando qué dejamos encendido en el editor
	var active_pose = poses_registry.get(current_pose_id)
	if active_pose:
		for item_id in active_pose.registry.keys():
			if active_pose.registry[item_id].visible:
				_equipped_items.append(item_id)


## PUBLIC API: Cambia la postura usando identificadores numéricos puros.
func change_pose(target_pose_id: int) -> void:
	if not poses_registry.has(target_pose_id) or target_pose_id == current_pose_id:
		return
		
	var old_pose = poses_registry.get(current_pose_id)
	var new_pose = poses_registry.get(target_pose_id)
	
	if old_pose: old_pose.visible = false
	if new_pose: new_pose.visible = true
	
	current_pose_id = target_pose_id
	
	if new_pose:
		new_pose.hide_all_registered()
		new_pose.sync_equipped_items(_equipped_items)


## PUBLIC API: Modifica el estado de una prenda en el inventario lógico.
func modify_clothing(item_id: int, is_equipped: bool) -> void:
	if is_equipped and not item_id in _equipped_items:
		_equipped_items.append(item_id)
	elif not is_equipped and item_id in _equipped_items:
		_equipped_items.erase(item_id)
		
	var active_pose = poses_registry.get(current_pose_id)
	if active_pose:
		active_pose.sync_equipped_items(_equipped_items)


# ==========================================
# SERIALIZACIÓN DE ESTADO (SAVE & LOAD)
# ==========================================

## PUBLIC API: Serializa el estado actual del guardarropa y la postura.
## Devuelve un diccionario limpio con puros IDs numéricos estables.
func get_clothing_state() -> Dictionary:
	return {
		"current_pose_id": current_pose_id,
		"equipped_ids": _equipped_items.duplicate()
	}


## PUBLIC API: Restaura la postura y las prendas equipadas desde el archivo de guardado.
## Sanitiza automáticamente los números float que genera el formato JSON nativo de Godot.
func apply_clothing_state(state: Dictionary) -> void:
	if state.is_empty():
		return
		
	# 1. Extraer y sanitizar la lista de ropa equipada (Bypass de floats a int)
	if state.has("equipped_ids"):
		_equipped_items.clear()
		for id in state["equipped_ids"]:
			_equipped_items.append(int(id))
			
	# 2. Procesar el cambio seguro de postura
	if state.has("current_pose_id"):
		var target_pose = int(state["current_pose_id"])
		change_pose(target_pose)
	else:
		# Si la partida no guardó una pose, forzamos la sincronización de la pose actual
		var active_pose = poses_registry.get(current_pose_id)
		if active_pose:
			active_pose.hide_all_registered()
			active_pose.sync_equipped_items(_equipped_items)
