class_name EssenceClassicGrid extends GridContainer

signal on_slot_action(action: String, slot_id: String)

@export var prefab_slot: PackedScene

func refresh_grid(page: int, is_save_mode: bool, all_meta_data: Dictionary):
	for c in get_children(): c.queue_free()
	
	for i in range(EssenceSlotMapper.SLOTS_PER_PAGE):
		# ¡Llamamos al cerebro!
		var slot_id = EssenceSlotMapper.get_id_for_grid(page, i)
		var real_data = all_meta_data.get(slot_id, {})
		
		var slot = prefab_slot.instantiate()
		add_child(slot)
		slot.setup(slot_id, real_data, is_save_mode)
		
		slot.on_slot_clicked.connect(func(act, id): on_slot_action.emit(act, id))
