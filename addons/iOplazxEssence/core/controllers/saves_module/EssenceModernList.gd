class_name EssenceModernList extends VBoxContainer

const ES_NAME_CLASS = "EssenceModernList"

signal on_slot_action(action: String, slot_id: String)

@export var prefab_slot: PackedScene
@export var btn_add_new: Button 

const MIN_VIRTUAL_SLOTS = 5

func _ready() -> void:
	if _validate_requirements():
		EssenceLogger.system_info("[%s] Modern List initialized successfully." % ES_NAME_CLASS)

## Inspector validation to prevent Nil reference crashes
func _validate_requirements() -> bool:
	var is_valid = true
	if prefab_slot == null:
		EssenceError.report(
			"Missing Slot Prefab",
			"The 'Prefab Slot' is not assigned in %s. List cannot be rendered." % name,
			EssenceError.Severity.CRITICAL
		)
		is_valid = false
	
	if btn_add_new == null:
		# We use WARNING here because the list could still show existing saves, 
		# but the user won't be able to create new ones.
		EssenceError.report(
			"Missing Add Button",
			"The 'Btn Add New' is not assigned in %s. New saves cannot be created." % name,
			EssenceError.Severity.WARNING
		)
		# We don't return false here to allow the list to at least show current saves
	
	return is_valid

func refresh_list(is_save_mode: bool, all_meta_data: Dictionary):
	if not is_instance_valid(prefab_slot):
		return
		
	# 1. Cleanup (Protecting the Add New button)
	for c in get_children():
		if c != btn_add_new: 
			c.queue_free()
			
	# 2. Filter existing manual saves
	var existing_manual_saves = []
	for key in all_meta_data.keys():
		if key.begins_with("save_"):
			existing_manual_saves.append(key)
			
	# 3. Draw real saves
	for slot_id in existing_manual_saves:
		_crear_slot(slot_id, all_meta_data[slot_id], is_save_mode)
		
	# 4. VIRTUAL ILLUSION: Fill with empty slots if count < MIN_VIRTUAL_SLOTS
	var current_count = existing_manual_saves.size()
	
	if current_count < MIN_VIRTUAL_SLOTS:
		var missing_slots = MIN_VIRTUAL_SLOTS - current_count
		var added_virtuals = 0
		var search_page = 1
		var search_index = 0
		
		while added_virtuals < missing_slots:
			var potential_id = EssenceSlotMapper.get_id_for_grid(search_page, search_index)
			
			if not all_meta_data.has(potential_id):
				_crear_slot(potential_id, {}, is_save_mode)
				added_virtuals += 1
				
			search_index += 1
			if search_index >= EssenceSlotMapper.SLOTS_PER_PAGE:
				search_index = 0
				search_page += 1
				
		EssenceLogger.system_info("[%s] Rendered %d real slots and %d virtual placeholders." % [ES_NAME_CLASS, current_count, added_virtuals])

	# 5. Configure "Add New" button
	if is_instance_valid(btn_add_new):
		btn_add_new.visible = is_save_mode
		
		if btn_add_new.pressed.is_connected(_on_add_new_pressed):
			btn_add_new.pressed.disconnect(_on_add_new_pressed)
			
		btn_add_new.pressed.connect(func(): _on_add_new_pressed(all_meta_data))
		move_child(btn_add_new, -1)

func _crear_slot(slot_id: String, real_data: Dictionary, is_save_mode: bool):
	if not is_instance_valid(prefab_slot): return
	
	var slot = prefab_slot.instantiate()
	add_child(slot)
	slot.setup(slot_id, real_data, is_save_mode)
	
	# Safe connection using Lambda
	if slot.has_signal("on_action_requested"):
		slot.on_action_requested.connect(func(act, id): on_slot_action.emit(act, id))

func _on_add_new_pressed(all_meta_data: Dictionary):
	var target_slot_id = EssenceSlotMapper.get_next_empty_slot_id(all_meta_data)
	EssenceLogger.system_info("[%s] Add New Slot requested. Target ID: %s" % [ES_NAME_CLASS, target_slot_id])
	on_slot_action.emit("SAVE", target_slot_id)