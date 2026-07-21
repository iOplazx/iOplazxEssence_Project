## [EssenceModularActor]
## Clase base del framework encargada de la gestión modular de apariencias,
## control seguro de posturas y sincronización de prendas mediante IDs inmutables.
class_name EssenceModularActor
extends EssenceActor

@export_category("Base Modular Configuration")
## La pose entera activa inicial.
@export var current_pose_id: int = 1

## Registro visual indexado por enteros (Pose ID -> Nodo del Grupo Visual)
var poses_registry: Dictionary = {}

## Lista maestra que guarda los enteros de la ropa que el personaje lleva puesta (Save State).
var _equipped_items: Array[int] = []


func _ready() -> void:
	super._ready()
	_sync_modular_initial_state()

## Valida en tiempo de diseño/ejecución si el desarrollador olvidó conectar la pose.
func _validate_poses_registry() -> void:
	if poses_registry.is_empty():
		push_warning("[%s] ⚠️ WARNING: 'poses_registry' está VACÍO en el Inspector. El personaje no podrá actualizar su ropa ni cambiar de pose." % name)
		

func _sync_modular_initial_state() -> void:
	_equipped_items.clear()
	
	for pose_id in poses_registry.keys():
		var pose_node = poses_registry[pose_id]
		if is_instance_valid(pose_node):
			pose_node.visible = (int(pose_id) == current_pose_id)
			
	var active_pose = poses_registry.get(current_pose_id)
	if active_pose:
		# 1. Hornear inventario local forzando enteros primitivos
		for item_id in active_pose.registry.keys():
			if active_pose.registry[item_id].visible:
				_equipped_items.append(int(item_id))
				
		# 2. Hornear inventario compartido forzando enteros primitivos
		if "shared_clothing_group" in active_pose and is_instance_valid(active_pose.shared_clothing_group):
			var shared = active_pose.shared_clothing_group
			for item_id in shared.registry.keys():
				if shared.registry[item_id].visible and not int(item_id) in _equipped_items:
					_equipped_items.append(int(item_id))
					
		# ¡CORRECCIÓN CRÍTICA!: Forzar la primera sincronización visual en el arranque
		# Esto sobreescribe cualquier estado manual que haya quedado visible en el editor.
		active_pose.sync_equipped_items(_equipped_items)
		if "shared_clothing_group" in active_pose and is_instance_valid(active_pose.shared_clothing_group):
			active_pose.shared_clothing_group.sync_equipped_items(_equipped_items)

## PUBLIC API: Cambia la postura usando identificadores numéricos puros.
func change_pose(target_pose_id: int) -> void:
	var target_id: int = int(target_pose_id)
	if not poses_registry.has(target_id) or target_id == current_pose_id:
		return
		
	var old_pose = poses_registry.get(current_pose_id)
	var new_pose = poses_registry.get(target_id)
	
	var old_shared = old_pose.shared_clothing_group if (old_pose and "shared_clothing_group" in old_pose) else null
	var new_shared = new_pose.shared_clothing_group if (new_pose and "shared_clothing_group" in new_pose) else null
	
	if old_pose: old_pose.visible = false
	if new_pose: new_pose.visible = true
	
	if old_shared and old_shared != new_shared: old_shared.visible = false
	if new_shared: new_shared.visible = true
	
	current_pose_id = target_id
	
	if new_pose:
		new_pose.hide_all_registered()
		new_pose.sync_equipped_items(_equipped_items)
	if new_shared:
		new_shared.hide_all_registered()
		new_shared.sync_equipped_items(_equipped_items)

## PUBLIC API: Modifica el estado de una prenda en el inventario lógico.
func modify_clothing(item_id: int, is_equipped: bool) -> void:
	var target_id: int = int(item_id)
	
	if is_equipped and not target_id in _equipped_items:
		_equipped_items.append(target_id)
	elif not is_equipped and target_id in _equipped_items:
		_equipped_items.erase(target_id)
		
	var active_pose = poses_registry.get(current_pose_id)
	if active_pose:
		active_pose.sync_equipped_items(_equipped_items)
		if "shared_clothing_group" in active_pose and is_instance_valid(active_pose.shared_clothing_group):
			active_pose.shared_clothing_group.sync_equipped_items(_equipped_items)
	else:
		push_warning("[%s] ⚠️ WARNING: No se encontró la pose ID %d en 'poses_registry'. Revisa el Inspector." % [name, current_pose_id])
					

# ==========================================
# SERIALIZACIÓN DE ESTADO (SAVE & LOAD)
# ==========================================

## PUBLIC API: Serializa el estado actual del guardarropa y la postura.
## Devuelve un diccionario limpio con puros IDs numéricos estables.
func get_clothing_state() -> Dictionary:
	return {
		"equipped_ids": _equipped_items.duplicate(),
		"current_pose": current_pose_id
	}


## PUBLIC API: Restaura la postura y las prendas equipadas desde el archivo de guardado.
## Sanitiza automáticamente los números float que genera el formato JSON nativo de Godot.
func apply_clothing_state(state: Dictionary) -> void:
	if state.has("equipped_ids"):
		_equipped_items.clear()
		for id in state["equipped_ids"]:
			_equipped_items.append(int(id)) # Limpieza de flotantes JSON
			
	if state.has("current_pose"):
		var target_pose_id: int = int(state["current_pose"])
		if target_pose_id == current_pose_id:
			var active_pose = poses_registry.get(current_pose_id)
			if active_pose:
				active_pose.hide_all_registered()
				active_pose.sync_equipped_items(_equipped_items)
				if "shared_clothing_group" in active_pose and is_instance_valid(active_pose.shared_clothing_group):
					active_pose.shared_clothing_group.sync_equipped_items(_equipped_items)
		else:
			change_pose(target_pose_id)
