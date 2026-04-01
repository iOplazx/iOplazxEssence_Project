class_name EssenceSlotMapper extends RefCounted

const SLOTS_PER_PAGE: int = 6

# ==========================================
# PARA EL MODO CLÁSICO: Convierte (Página, Índice) a ID
# ==========================================
static func get_id_for_grid(page: int, index: int) -> String:
	if page == 0:
		return "auto_" + str(index + 1)
	else:
		return "save_" + str(page) + "_" + str(index + 1)

# ==========================================
# PARA EL MODO MODERNO: Encuentra el siguiente espacio libre
# ==========================================
static func get_next_empty_slot_id(all_meta: Dictionary) -> String:
	var current_page = 1
	
	# Buscamos secuencialmente hasta encontrar un hueco
	while current_page < 100: # Límite de seguridad
		for i in range(SLOTS_PER_PAGE):
			var slot_id = "save_" + str(current_page) + "_" + str(i + 1)
			if not all_meta.has(slot_id):
				return slot_id # ¡Encontramos uno vacío!
		current_page += 1
		
	return "save_99_99" # Fallback extremo por si el jugador lleva 600 partidas
