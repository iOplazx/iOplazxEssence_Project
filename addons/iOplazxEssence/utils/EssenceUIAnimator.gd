class_name EssenceUIAnimator extends RefCounted

# ==========================================
# ANIMACIONES DE ENTRADA
# ==========================================

## Hace aparecer un nodo suavemente. Devuelve el Tween por si quieres conectarle un .finished
static func fade_in(node: Control, duration: float, delay: float = 0.0) -> Tween:
	if not node: return null
	
	node.modulate.a = 0.0
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration).set_delay(delay).set_trans(Tween.TRANS_SINE)
	return tween

## Hace caer un nodo desde arriba con un ligero rebote
static func slide_from_top(node: Control, distance: float, duration: float) -> Tween:
	if not node: return null
	
	node.modulate.a = 1.0
	node.pivot_offset = node.size / 2.0
	var target_y = node.position.y
	node.position.y -= distance
	
	var tween = node.create_tween()
	tween.tween_property(node, "position:y", target_y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween

# ==========================================
# ANIMACIONES IDLE (BUCLES)
# ==========================================

## Crea un efecto de respiración (escala) infinito
static func breathing(node: Control, duration: float, scale_max: float = 1.05) -> Tween:
	if not node: return null
	
	node.pivot_offset = node.size / 2.0
	var tween = node.create_tween().set_loops()
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
		if node is Control:
			fade_in(node, duration, current_delay)
			current_delay += stagger
