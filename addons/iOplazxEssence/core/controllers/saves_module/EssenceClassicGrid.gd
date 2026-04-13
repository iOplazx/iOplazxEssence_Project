class_name EssenceClassicGrid extends GridContainer

const ES_NAME_CLASS = "EssenceClassicGrid"

signal on_slot_action(action: String, slot_id: String)

@export var prefab_slot: PackedScene

func _ready():
	# Primero validamos que todo esté en su lugar antes de permitir refrescos
	if _validate_requirements():
		EssenceLogger.system_info("[%s] Successfully initialized." % ES_NAME_CLASS)

## Verifica que las dependencias críticas del Inspector existan
func _validate_requirements() -> bool:
	if prefab_slot == null:
		EssenceError.report(
			"Missing Prefab",
			"No prefab has been assigned for the 'Prefab Slot' in the Inspector of %s. The grid will not be able to display saves." % name,
			EssenceError.Severity.CRITICAL
		)
		return false
	return true

func refresh_grid(page: int, is_save_mode: bool, all_meta_data: Dictionary):
	# Si por algún error el prefab es nulo, detenemos la ejecución para evitar el crash
	if not is_instance_valid(prefab_slot): 
		return
		
	for c in get_children(): c.queue_free()
	
	for i in range(EssenceSlotMapper.SLOTS_PER_PAGE):
		var slot_id = EssenceSlotMapper.get_id_for_grid(page, i)
		var real_data = all_meta_data.get(slot_id, {})
		
		var slot = prefab_slot.instantiate()
		add_child(slot)
		slot.setup(slot_id, real_data, is_save_mode)
		
		# Conexión segura usando una función anónima (Lambda)
		slot.on_slot_clicked.connect(func(act, id): on_slot_action.emit(act, id))
