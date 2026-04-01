class_name EssencePaginator extends RefCounted

var current_page: int = 0 # 0 es Auto
var total_pages: int = 9

# --- CONTROL DE ESTADO ---

func next_page() -> bool:
	if current_page < total_pages:
		current_page += 1
		return true # Indica que la página sí cambió
	return false

func prev_page() -> bool:
	if current_page > 0:
		current_page -= 1
		return true
	return false

func set_page(page: int) -> bool:
	if page >= 0 and page <= total_pages and current_page != page:
		current_page = page
		return true
	return false

# --- LÓGICA DE DIBUJO PARA LA UI ---

## Devuelve un paquete con todo lo que la UI necesita saber
func get_ui_state(max_visible_buttons: int = 5) -> Dictionary:
	var state = {
		"can_go_left": current_page > 0,
		"can_go_right": current_page < total_pages,
		"buttons_to_draw": [] # Array de diccionarios con info de cada botón
	}
	
	# Siempre agregamos el botón Auto (Página 0)
	state.buttons_to_draw.append({
		"label": "Auto" if current_page == 0 else "A",
		"page_num": 0,
		"is_active": current_page == 0
	})
	
	# Calculamos la ventana de números (Paginación inteligente tipo Google)
	var start_page = maxi(1, current_page - (max_visible_buttons / 2))
	var end_page = mini(total_pages, start_page + max_visible_buttons - 1)
	
	# Ajuste si estamos cerca del final
	if end_page - start_page < max_visible_buttons - 1:
		start_page = maxi(1, end_page - max_visible_buttons + 1)
		
	for i in range(start_page, end_page + 1):
		state.buttons_to_draw.append({
			"label": str(i),
			"page_num": i,
			"is_active": current_page == i
		})
		
	return state
