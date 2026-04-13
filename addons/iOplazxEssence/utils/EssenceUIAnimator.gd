class_name EssenceUIAnimator extends RefCounted

const ES_NAME_CLASS = "EssenceUIAnimator"

# ==========================================
# ANIMACIONES DE ENTRADA
# ==========================================

## Hace aparecer un nodo suavemente.
static func fade_in(node: Control, duration: float, delay: float = 0.0) -> Tween:
	# 1. Blindaje contra nodos destruidos (is_instance_valid es mejor que "not node")
	if not is_instance_valid(node): return null
	
	node.modulate.a = 0.0
	var tween = node.create_tween()
	
	# 2. Seguridad extrema: bind_node evita que el juego crashee si el jugador
	# cierra el menú antes de que termine el delay de la animación.
	tween.bind_node(node)
	tween.tween_property(node, "modulate:a", 1.0, duration).set_delay(delay).set_trans(Tween.TRANS_SINE)
	return tween

## Hace caer un nodo desde arriba con un ligero rebote
static func slide_from_top(node: Control, distance: float, duration: float) -> Tween:
	if not is_instance_valid(node): return null
	
	# 3. BLINDAJE CONTRA CONTENEDORES: 
	# Si intentamos mover la "position" de un nodo dentro de un contenedor, Godot se rompe.
	if node.get_parent() is Container:
		# Fallback elegante: Si está en un contenedor, lo cambiamos a un simple Fade-in para evitar bugs.
		EssenceLogger.system_info("[%s] 'slide_from_top' convertido a 'fade_in' para evitar conflicto con Container en el nodo: %s" % [ES_NAME_CLASS, node.name])
		return fade_in(node, duration)
		
	node.modulate.a = 1.0
	node.pivot_offset = node.size / 2.0
	var target_y = node.position.y
	node.position.y -= distance
	
	var tween = node.create_tween()
	tween.bind_node(node)
	tween.tween_property(node, "position:y", target_y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween

# ==========================================
# ANIMACIONES IDLE (BUCLES)
# ==========================================

## Crea un efecto de respiración (escala) infinito
static func breathing(node: Control, duration: float, scale_max: float = 1.05) -> Tween:
	if not is_instance_valid(node): return null
	
	# Validar el tamaño para evitar pivot_offset en (0,0) si el nodo aún no se dibuja
	if node.size != Vector2.ZERO:
		node.pivot_offset = node.size / 2.0
		
	var tween = node.create_tween().set_loops()
	tween.bind_node(node)
	tween.tween_property(node, "scale", Vector2(scale_max, scale_max), duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_SINE)
	return tween

# ==========================================
# ANIMACIONES DE GRUPO
# ==========================================

## Hace aparecer una lista de nodos uno tras otro (efecto cascada)
static func cascade_fade_in(nodes: Array, duration: float, stagger: float, start_delay: float = 0.0):
	var current_delay = start_delay
	for node in nodes:
		if is_instance_valid(node) and node is Control:
			fade_in(node, duration, current_delay)
			current_delay += stagger