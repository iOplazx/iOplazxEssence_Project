## [EssenceBaseInteractionMenu]
## Abstract parent class for contextual interaction menus.

## Handles data, pagination, animations, and control logic regardless of geometric shape.
class_name EssenceBaseInteractionMenu
extends Control

signal accion_seleccionada(accion: String)
signal menu_cerrado()

@export_category("Configuración Visual")
@export var tiempo_animacion: float = 0.3
@export var escala_botones: float = 0.8 

@export_category("Recursos de Interfaz")
@export var boton_escena: PackedScene 
@export var icono_desconocido: Texture2D 
@export var icono_prev: Texture2D 
@export var icono_next: Texture2D 

@onready var anchor: Marker2D = $Anchor
@onready var buttons_container: Control = $Anchor/ButtonsContainer

var paginas_acciones: Array = []
var pagina_actual: int = 0

var botones_accion: Array[EssenceBaseInteractionButton] = []
var btn_prev: EssenceBaseInteractionButton
var btn_next: EssenceBaseInteractionButton

func _ready() -> void:
	visible = false
	modulate.a = 0.0 
	anchor.scale = Vector2(0.1, 0.1)
	
	# Limpieza de nodos de diseño en el editor
	for child in buttons_container.get_children():
		child.queue_free()
		
	# LLAMADA VIRTUAL: Cada hijo implementará su propia geometría
	_generar_estructura_geometrica()


## API CENTRAL: Configura la matriz de páginas de datos enviada por el Gameplay Director.
func configurar_menu(datos_por_paginas: Array) -> void:
	paginas_acciones = datos_por_paginas
	pagina_actual = 0
	_actualizar_vista_pagina()


## Procesa la visibilidad e íconos de los botones según la página activa.
func _actualizar_vista_pagina() -> void:
	if paginas_acciones.is_empty(): return
	
	var datos_pagina = paginas_acciones[pagina_actual]
	
	# 1. Actualizar botones de acción estándar
	for i in range(botones_accion.size()):
		var btn = botones_accion[i]
		
		if i < datos_pagina.size() and datos_pagina[i].get("id", "") != "":
			var accion_data = datos_pagina[i]
			btn.nombre_accion = accion_data.get("id", "")
			btn.get_node("Icon").texture = accion_data.get("icono", icono_desconocido)
			btn.modulate.a = 1.0 
			_configurar_interaccion(btn, accion_data.get("descripcion", ""), true)
		else:
			_desactivar_boton(btn)
			_configurar_interaccion(btn, "", false)

	# 2. Control de flechas de paginación
	_gestionar_boton_paginacion(btn_prev, "pagina_anterior", pagina_actual > 0, tr("RADIAL_MENU_PREV_PAGE"))
	_gestionar_boton_paginacion(btn_next, "pagina_siguiente", pagina_actual < paginas_acciones.size() - 1, tr("RADIAL_MENU_NEXT_PAGE"))


func _gestionar_boton_paginacion(btn: EssenceBaseInteractionButton, accion: String, condicion: bool, tooltip: String) -> void:
	if condicion:
		btn.nombre_accion = accion
		btn.modulate.a = 1.0
		_configurar_interaccion(btn, tooltip, true)
	else:
		_desactivar_boton(btn)
		_configurar_interaccion(btn, "", false)


func _configurar_interaccion(btn_raiz: Control, texto: String, activado: bool) -> void:
	btn_raiz.tooltip_text = texto
	var nodo_hijo = btn_raiz.get_node_or_null("Btn")
	var filtro_deseado = Control.MOUSE_FILTER_STOP if activado else Control.MOUSE_FILTER_IGNORE
	
	if nodo_hijo:
		nodo_hijo.tooltip_text = texto
		nodo_hijo.mouse_filter = filtro_deseado
		btn_raiz.mouse_filter = Control.MOUSE_FILTER_PASS 
	else:
		btn_raiz.mouse_filter = filtro_deseado


func _desactivar_boton(btn: EssenceBaseInteractionButton) -> void:
	btn.nombre_accion = ""
	btn.modulate.a = 0.0 
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Despliega el menú de forma sutil interpolando las posiciones finales calculadas por el hijo.
func abrir_menu(posicion_global_clic: Vector2) -> void:
	anchor.position = make_canvas_position_local(posicion_global_clic)
	visible = true
	modulate.a = 0.0
	anchor.scale = Vector2(0.1, 0.1) 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, tiempo_animacion).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anchor, "scale", Vector2(1.0, 1.0), tiempo_animacion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	for btn in buttons_container.get_children():
		btn.position = -(btn.size / 2.0)
		var pos_final = btn.get_meta("pos_final", Vector2.ZERO)
		tween.tween_property(btn, "position", pos_final, tiempo_animacion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func cerrar_menu() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, tiempo_animacion).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anchor, "scale", Vector2(0.1, 0.1), tiempo_animacion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	for btn in buttons_container.get_children():
		tween.tween_property(btn, "position", -(btn.size / 2.0), tiempo_animacion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	tween.chain().tween_callback(func():
		visible = false
		menu_cerrado.emit()
	)


func _on_accion_boton(accion: String) -> void:
	if accion == "": return
	
	if accion == "pagina_anterior":
		pagina_actual = max(0, pagina_actual - 1)
		_actualizar_vista_pagina()
		return
	if accion == "pagina_siguiente":
		pagina_actual = min(paginas_acciones.size() - 1, pagina_actual + 1)
		_actualizar_vista_pagina()
		return
		
	accion_seleccionada.emit(accion)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cerrar_menu()


## MÉTODO VIRTUAL (Debe ser sobreescrito por las clases hijas)
func _generar_estructura_geometrica() -> void:
	pass


## Instanciador de botones genérico para las clases hijas.
## Ahora devuelve el puntero tipado hacia la clase abstracta padre.
func _instanciar_slot(posicion_local: Vector2, accion_inicial: String) -> EssenceBaseInteractionButton:
	var btn = boton_escena.instantiate() as EssenceBaseInteractionButton
	buttons_container.add_child(btn)
	btn.scale = Vector2(escala_botones, escala_botones)
	
	# Centramos el pivote del botón en la posición matemática calculada
	btn.set_meta("pos_final", posicion_local - (btn.size / 2.0))
	btn.nombre_accion = accion_inicial
	btn.accion_elegida.connect(_on_accion_boton)
	return btn
