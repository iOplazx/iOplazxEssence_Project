class_name EssencePaginator extends RefCounted

const ES_NAME_CLASS = "EssencePaginator"

var current_page: int = 0 # 0 es Auto
var total_pages: int = 99

# ==========================================
# INICIALIZACIÓN
# ==========================================

## Configura el paginador basándose en la cantidad real de páginas del juego
func setup(real_total_pages: int, starting_page: int = 0):
	# Validamos que nunca haya menos de 1 página (evita errores de división por cero)
	total_pages = maxi(1, real_total_pages)
	# clampi asegura que si le pasas un número loco (ej. página 50 de 10), lo limite al máximo real
	current_page = clampi(starting_page, 0, total_pages)
	
	EssenceLogger.system_info("[%s] Configurado: %d páginas en total. Empezando en pág. %d" % [ES_NAME_CLASS, total_pages, current_page])

# ==========================================
# CONTROL DE ESTADO
# ==========================================

func next_page():
	# Si estamos en Auto (0), saltamos a la 1
	if current_page == 0:
		current_page = 1
	else:
		# Saltamos al siguiente bloque (si estamos en el 1, vamos al 10)
		current_page += 9
	_clamp_page()

func prev_page():
	if current_page > 9:
		current_page -= 9
	elif current_page <= 9 and current_page > 0:
		current_page = 0 # Regresamos a Auto
	_clamp_page()

func _clamp_page():
	current_page = maxi(0, current_page)

func set_page(page: int):
	current_page = page
	EssenceLogger.system_info("[%s] Página cambiada a: %d" % [ES_NAME_CLASS, current_page])

# ==========================================
# LÓGICA DE DIBUJO (ESTILO REN'PY)
# ==========================================

func get_ui_state(_unused = 0) -> Dictionary:
	var buttons = []
	
	# 1. El botón "Auto" siempre está al principio
	buttons.append({
		"label": "Auto" if current_page == 0 else "A",
		"page_num": 0,
		"is_active": current_page == 0
	})
	
	# 2. Cálculo del bloque actual (1-9, 10-18, 19-27...)
	# Si estamos en 0, mostramos el primer bloque (1-9)
	var base_page = current_page
	if current_page == 0: base_page = 1
	
	# Fórmula para encontrar el inicio del bloque de 9
	var block_start = (floori((base_page - 1) / 9.0) * 9) + 1
	
	for i in range(block_start, block_start + 9):
		buttons.append({
			"label": str(i),
			"page_num": i,
			"is_active": current_page == i
		})
	
	# 3. Lógica de flechas
	return {
		"buttons_to_draw": buttons,
		"can_go_left": current_page > 0, # Solo desactivada si estamos en Auto
		"can_go_right": true # Siempre activo para esa sensación de infinidad
	}
