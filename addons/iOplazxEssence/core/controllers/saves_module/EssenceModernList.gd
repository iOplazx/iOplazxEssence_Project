class_name EssenceModernList extends VBoxContainer

signal on_slot_action(action: String, slot_id: String)

@export var prefab_slot: PackedScene
@export var btn_add_new: Button 

const MIN_VIRTUAL_SLOTS = 5

func refresh_list(is_save_mode: bool, all_meta_data: Dictionary):
	# 1. Limpiamos la lista (Protegiendo el botón de "Añadir Nuevo")
	for c in get_children():
		if c != btn_add_new: 
			c.queue_free()
			
	# 2. Separamos los slots que YA existen (ignorando autosaves para la lista principal)
	var existing_manual_saves = []
	for key in all_meta_data.keys():
		if key.begins_with("save_"):
			existing_manual_saves.append(key)
			
	# 3. Dibujamos las partidas reales que el jugador ya guardó
	for slot_id in existing_manual_saves:
		_crear_slot(slot_id, all_meta_data[slot_id], is_save_mode)
		
	# 4. LA ILUSIÓN VIRTUAL: Si hay menos de 5, rellenamos con slots falsos
	var current_count = existing_manual_saves.size()
	
	if current_count < MIN_VIRTUAL_SLOTS:
		var missing_slots = MIN_VIRTUAL_SLOTS - current_count
		var added_virtuals = 0
		var search_page = 1
		var search_index = 0
		
		# Buscamos los siguientes IDs lógicos que estén vacíos para asignárselos a los virtuales
		while added_virtuals < missing_slots:
			var potential_id = EssenceSlotMapper.get_id_for_grid(search_page, search_index)
			
			if not all_meta_data.has(potential_id):
				_crear_slot(potential_id, {}, is_save_mode) # Se envía diccionario vacío
				added_virtuals += 1
				
			search_index += 1
			if search_index >= EssenceSlotMapper.SLOTS_PER_PAGE:
				search_index = 0
				search_page += 1

	# 5. Configurar el botón "Crear Nuevo" (Solo visible si estamos guardando)
	if btn_add_new:
		btn_add_new.visible = is_save_mode
		
		# Limpiamos conexiones viejas por si refrescamos la UI
		if btn_add_new.pressed.is_connected(_on_add_new_pressed):
			btn_add_new.pressed.disconnect(_on_add_new_pressed)
			
		btn_add_new.pressed.connect(func(): _on_add_new_pressed(all_meta_data))
		
		# Aseguramos que siempre, siempre se dibuje al final de la lista
		move_child(btn_add_new, -1)

func _crear_slot(slot_id: String, real_data: Dictionary, is_save_mode: bool):
	var slot = prefab_slot.instantiate()
	add_child(slot)
	slot.setup(slot_id, real_data, is_save_mode)
	
	# El slot moderno avisa a esta lista, y esta lista le avisa al Controlador Principal
	slot.on_action_requested.connect(func(act, id): on_slot_action.emit(act, id))

func _on_add_new_pressed(all_meta_data: Dictionary):
	# ¡La magia del Mapper! Le pedimos el siguiente hueco disponible en todo el disco duro
	var target_slot_id = EssenceSlotMapper.get_next_empty_slot_id(all_meta_data)
	
	# Simulamos que el jugador hizo clic en un slot vacío
	on_slot_action.emit("SAVE", target_slot_id)
