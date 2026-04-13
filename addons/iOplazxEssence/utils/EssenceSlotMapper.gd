class_name EssenceSlotMapper extends RefCounted

const ES_NAME_CLASS = "EssenceSlotMapper"
const SLOTS_PER_PAGE: int = 6

# ==========================================
# PARA EL MODO CLÁSICO: Convierte (Página, Índice) a ID
# ==========================================
static func get_id_for_grid(page: int, index: int) -> String:
	# Blindaje Senior: Prevenimos que un error en el bucle For de la UI cree IDs corruptos (ej. save_1_7)
	if index < 0 or index >= SLOTS_PER_PAGE:
		EssenceLogger.system_info("[%s] Advertencia: Índice de slot fuera de rango (%d). Ajustando..." % [ES_NAME_CLASS, index])
		index = clampi(index, 0, SLOTS_PER_PAGE - 1)
		
	if page == 0:
		return "auto_" + str(index + 1)
	else:
		return "save_" + str(page) + "_" + str(index + 1)

# ==========================================
# PARA EL MODO MODERNO: Encuentra el siguiente espacio libre
# ==========================================
static func get_next_empty_slot_id(all_meta: Dictionary) -> String:
	var current_page = 1
	var max_pages_allowed = 100
	
	# Buscamos secuencialmente hasta encontrar un hueco
	while current_page <= max_pages_allowed:
		for i in range(SLOTS_PER_PAGE):
			var slot_id = "save_" + str(current_page) + "_" + str(i + 1)
			if not all_meta.has(slot_id):
				return slot_id # ¡Encontramos uno vacío!
		current_page += 1
		
	# === EL SEGURO DE VIDA PARA EDGE CASES ===
	# Si el bucle termina, significa que el jugador tiene 600 partidas y no hay espacio.
	# Lanzamos la UI de advertencia amarilla sin crashear el juego.
	EssenceError.report(
		"Save Limit Reached",
		"Se ha alcanzado el límite de partidas (%d). Por favor, borra o sobrescribe partidas antiguas." % (max_pages_allowed * SLOTS_PER_PAGE),
		EssenceError.Severity.WARNING
	)
	
	EssenceLogger.system_info("[%s] Límite absoluto alcanzado. Retornando fallback save_99_99." % ES_NAME_CLASS)
	
	return "save_99_99"