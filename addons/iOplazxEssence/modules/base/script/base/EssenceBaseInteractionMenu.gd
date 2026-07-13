## [EssenceBaseInteractionMenu]
## Abstract parent class for contextual interaction menus.
## Handles data, pagination, animations, and control logic regardless of geometric shape.
class_name EssenceBaseInteractionMenu
extends Control

## Emitted when a valid action button is pressed. Passes the unique action ID string.
signal action_selected(action: String)

## Emitted when the menu completely finishes its closing transition.
signal menu_closed()

@export_category("Visual Configuration")
## Duration of the open and close transitions in seconds.
@export var animation_time: float = 0.3
## Scale factor applied to the instantiated action buttons.
@export var button_scale: float = 0.8 

@export_category("UI Resources")
## PackedScene template used to instantiate individual interaction slots.
@export var button_scene: PackedScene 
## Default texture used when an action doesn't define a custom icon.
@export var unknown_icon: Texture2D 
## Texture for the previous page pagination button.
@export var icon_prev: Texture2D 
## Texture for the next page pagination button.
@export var icon_next: Texture2D 

@onready var anchor: Marker2D = $Anchor
@onready var buttons_container: Control = $Anchor/ButtonsContainer

# Internal pagination tracking data structures
var paginas_acciones: Array = []
var pagina_actual: int = 0

var botones_accion: Array[EssenceBaseInteractionButton] = []
var btn_prev: EssenceBaseInteractionButton
var btn_next: EssenceBaseInteractionButton

# ==========================================
# PUBLIC CONTROL & ANIMATION STATE
# ==========================================
## Safety flag that blocks inputs and new interactions while visual transitions are active.
var is_animating: bool = false


func _ready() -> void:
	visible = false
	modulate.a = 0.0 
	anchor.scale = Vector2(0.1, 0.1)
	
	# Clean up design-time placeholder nodes from the editor container
	for child in buttons_container.get_children():
		child.queue_free()
		
	# VIRTUAL CALL: Each child menu class will implement its own geometric arrangement
	_generate_geometric_structure()


## PUBLIC API: Configures the action page matrix sent by the Gameplay Director.
func configure_menu(data_by_pages: Array) -> void:
	paginas_acciones = data_by_pages
	pagina_actual = 0
	_update_page_view()


## Processes the visibility and icons of the buttons based on the currently active page.
func _update_page_view() -> void:
	if paginas_acciones.is_empty(): 
		return
	
	var datos_pagina = paginas_acciones[pagina_actual]
	
	# 1. Update standard action buttons
	for i in range(botones_accion.size()):
		var btn = botones_accion[i]
		
		if i < datos_pagina.size() and datos_pagina[i].get("id", "") != "":
			var action_data = datos_pagina[i]
			if is_instance_valid(btn):
				btn.nombre_accion = action_data.get("id", "")
				btn.get_node("Icon").texture = action_data.get("icono", unknown_icon)
				btn.modulate.a = 1.0 
				_configure_interaction(btn, action_data.get("descripcion", ""), true)
		else:
			_deactivate_button(btn)
			_configure_interaction(btn, "", false)

	# 2. Pagination arrows control with null-safe guards
	_manage_pagination_button(btn_prev, "pagina_anterior", pagina_actual > 0, tr("RADIAL_MENU_PREV_PAGE"))
	_manage_pagination_button(btn_next, "pagina_siguiente", pagina_actual < paginas_acciones.size() - 1, tr("RADIAL_MENU_NEXT_PAGE"))
	

## Manages visibility and interactions for a specific pagination button safely.
func _manage_pagination_button(btn: EssenceBaseInteractionButton, action: String, condition: bool, tooltip: String) -> void:
	if not is_instance_valid(btn): 
		return # Prevents cascading crashes if initialization failed early
		
	if condition:
		btn.nombre_accion = action
		btn.modulate.a = 1.0
		_configure_interaction(btn, tooltip, true)
	else:
		_deactivate_button(btn)
		_configure_interaction(btn, "", false)


## Configures the mouse filtering rules and tooltips for interaction buttons.
func _configure_interaction(btn_raiz: Control, text: String, activated: bool) -> void:
	btn_raiz.tooltip_text = text
	var nodo_hijo = btn_raiz.get_node_or_null("Btn")
	var filtro_deseado = Control.MOUSE_FILTER_STOP if activated else Control.MOUSE_FILTER_IGNORE
	
	if nodo_hijo:
		nodo_hijo.tooltip_text = text
		nodo_hijo.mouse_filter = filtro_deseado
		btn_raiz.mouse_filter = Control.MOUSE_FILTER_PASS 
	else:
		btn_raiz.mouse_filter = filtro_deseado

## Resets and hides a button, disabling all mouse filtering interactions.
func _deactivate_button(btn: EssenceBaseInteractionButton) -> void:
	# CRITICAL FIX: Safety check to avoid writing properties on a Nil object
	if not is_instance_valid(btn): 
		return
		
	btn.nombre_accion = ""
	btn.modulate.a = 0.0 
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

## PUBLIC API: Smoothly deploys the menu by interpolating buttons to their calculated geometric target coordinates.
func open_menu(global_click_position: Vector2) -> void:
	# Reject execution if an animation is currently active or the menu is already visible
	if is_animating or visible: 
		return
		
	is_animating = true
	anchor.position = make_canvas_position_local(global_click_position)
	visible = true
	modulate.a = 0.0
	anchor.scale = Vector2(0.1, 0.1) 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, animation_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anchor, "scale", Vector2(1.0, 1.0), animation_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	for btn in buttons_container.get_children():
		btn.position = -(btn.size / 2.0)
		var pos_final = btn.get_meta("pos_final", Vector2.ZERO)
		tween.tween_property(btn, "position", pos_final, animation_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	# Release the animation lock once the transitions finish
	tween.chain().tween_callback(func(): is_animating = false)


## PUBLIC API: Smoothly retracts and hides the menu using a scale down transition, resetting interaction locks.
func close_menu() -> void:
	# Reject execution if an animation is currently active or the menu is already hidden
	if is_animating or not visible: 
		return
		
	is_animating = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, animation_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anchor, "scale", Vector2(0.1, 0.1), animation_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	for btn in buttons_container.get_children():
		tween.tween_property(btn, "position", -(btn.size / 2.0), animation_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Clean up visibility states and emit the notification signal upon sequence completion
	tween.chain().tween_callback(func():
		visible = false
		is_animating = false
		menu_closed.emit()
	)


## Callback receiver for button selection signals. Coordinates pagination or forwards structural actions.
func _on_action_button(action: String) -> void:
	if action == "": return
	
	if action == "pagina_anterior":
		pagina_actual = max(0, pagina_actual - 1)
		_update_page_view()
		return
	if action == "pagina_siguiente":
		pagina_actual = min(paginas_acciones.size() - 1, pagina_actual + 1)
		_update_page_view()
		return
		
	action_selected.emit(action)


func _gui_input(event: InputEvent) -> void:
	# Closes the menu when a physical left click registers outside the button boundaries
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_animating:
			close_menu()


## VIRTUAL METHOD: Must be overridden by child classes to build specific structural shapes.
func _generate_geometric_structure() -> void:
	pass


## Generic slot instantiator for child class layouts. Returns the base interaction button pointer.
func _instance_slot(local_position: Vector2, initial_action: String) -> EssenceBaseInteractionButton:
	var btn = button_scene.instantiate() as EssenceBaseInteractionButton
	buttons_container.add_child(btn)
	btn.scale = Vector2(button_scale, button_scale)
	
	# Center the button pivot according to the mathematically calculated local coordinates
	btn.set_meta("pos_final", local_position - (btn.size / 2.0))
	btn.nombre_accion = initial_action
	btn.accion_elegida.connect(_on_action_button)
	return btn
