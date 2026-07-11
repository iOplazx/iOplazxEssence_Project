## [HexagonMenu]
## Modifica la estructura geométrica para ordenar los botones en un patrón hexagonal rígido.
class_name EssenceHexagonMenu
extends EssenceBaseInteractionMenu

#==
#HexagonMenu.tscn
#==
#HexagonMenu (Control) [Script: HexagonMenu]
#├──  Anchor (Marker2D)
#└── ButtonsContainer (Control)
#==


@export_category("Geometría Hexagonal")
## Distancia desde el centro del menú hasta el centro de cada celda hexagonal.
@export var espacio_celda: float = 110.0

## Implementación de la estructura geométrica utilizando vectores directos de un anillo hexagonal.
func _generar_estructura_geometrica() -> void:
	if not boton_escena:
		push_error("[%s] Error: Asigna la escena del botón en el Inspector." % name)
		return

	# 1. DIRECCIONES DE UN ANILLO HEXAGONAL (Pointy-Topped Hexagon)
	# Calculamos las 6 esquinas del panal alrededor del origen (0,0)
	# Usamos las relaciones trigonométricas fijas del hexágono (sin(60°) = 0.866)
	var h_offset: float = espacio_celda * 0.866025 # Altura interna del triángulo hex
	var v_offset: float = espacio_celda * 0.5      # Mitad del radio
	
	var posiciones_hex: Array[Vector2] = [
		Vector2(0, -espacio_celda),      # 1. Arriba Centro
		Vector2(h_offset, -v_offset),    # 2. Arriba Derecha
		Vector2(h_offset, v_offset),     # 3. Abajo Derecha
		Vector2(0, espacio_celda),       # 4. Abajo Centro
		Vector2(-h_offset, v_offset),    # 5. Abajo Izquierda
		Vector2(-h_offset, -v_offset) # 6. Arriba Izquierda (Ajustado abajo como -h_offset)
	]
	
	# Corrección manual de typos matemáticos para precisión de compresión por hardware
	posiciones_hex[5] = Vector2(-h_offset, -v_offset)

	# 2. ASIGNACIÓN DE LOS 6 SLOTS DE ACCIÓN CENTRALES
	for pos in posiciones_hex:
		var btn = _instanciar_slot(pos, "vacio")
		if icono_desconocido:
			btn.get_node("Icon").texture = icono_desconocido
			
		# ¡LÍNEA NUEVA!: Rota el botón para que apunte hacia afuera del centro
		# Sumamos 90 grados en radianes porque el triángulo base mira hacia el Norte.
		btn.rotation = pos.angle() + deg_to_rad(90)
		
		botones_accion.append(btn)

	# 3. POSICIONAMIENTO DE FLECHAS DE PAGINACIÓN (Alas exteriores horizontales)
	# Las colocamos simétricamente a los costados del hexágono para un look de consola de ciencia ficción
	var pos_prev: Vector2 = Vector2(-h_offset * 1.8, 0.0)
	var pos_next: Vector2 = Vector2(h_offset * 1.8, 0.0)

	btn_prev = _instanciar_slot(pos_prev, "pagina_anterior")
	if icono_prev: btn_prev.get_node("Icon").texture = icono_prev

	btn_next = _instanciar_slot(pos_next, "pagina_siguiente")
	if icono_next: btn_next.get_node("Icon").texture = icono_next
