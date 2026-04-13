class_name EssencePaginator extends RefCounted

const ES_NAME_CLASS = "EssencePaginator"

var current_page: int = 0 

# ==========================================
# CONTROL DE ESTADO (BLOQUES DE 9)
# ==========================================

func next_page():
	# Si estamos en Auto (0), saltamos al inicio del segundo bloque (10)
	if current_page == 0:
		current_page = 10
	else:
		# Buscamos dónde empieza nuestro bloque actual y sumamos 9
		var block_start = _get_block_start(current_page)
		current_page = block_start + 9
	_clamp_page()

func prev_page():
	var block_start = _get_block_start(current_page)
	# Si estamos en el bloque 10-18, el previo es 0 (Auto)
	if block_start == 10:
		current_page = 0
	elif block_start > 10:
		current_page = block_start - 9
	else:
		current_page = 0
	_clamp_page()

func _get_block_start(page: int) -> int:
	if page <= 0: return 1
	# Fórmula estricta para bloques: 1-9, 10-18, 19-27...
	return (floori((page - 1) / 9.0) * 9) + 1

func _clamp_page():
	current_page = maxi(0, current_page)

func set_page(page: int) -> bool:
	if current_page != page:
		current_page = page
		return true
	return false

# ==========================================
# LÓGICA DE DIBUJO (COMPORTAMIENTO REN'PY)
# ==========================================

func get_ui_state(_unused = 0) -> Dictionary:
	var buttons = []
	
	# La "A" siempre es el primer botón
	buttons.append({
		"label": "Auto" if current_page == 0 else "A",
		"page_num": 0,
		"is_active": current_page == 0
	})
	
	var block_start = _get_block_start(current_page)
	
	for i in range(block_start, block_start + 9):
		buttons.append({
			"label": str(i),
			"page_num": i,
			"is_active": current_page == i
		})
	
	return {
		"buttons_to_draw": buttons,
		"can_go_left": current_page >= 10, # Deshabilitada en bloque 1 (0-9)
		"can_go_right": true 
	}