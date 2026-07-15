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

@onready var anchor: Control = $Anchor
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

## Base initialization lifecycle for the interaction menu container.
func _ready() -> void:
	# 1. VERIFIED RADIAL BLUEPRINT: Set root to PASS so children receive inputs first.
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	visible = false
	modulate.a = 0.0 
	
	if is_instance_valid(anchor):
		anchor.scale = Vector2(0.1, 0.1)
	
	# 2. CRITICAL CONTAINER NORMALIZATION LAYER:
	# Forcibly strips any 40x40 editor sizing artifacts from the container node[cite: 6].
	# This aligns the physical collision system 1:1 with visual canvas space calculations.
	if is_instance_valid(buttons_container):
		buttons_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buttons_container.custom_minimum_size = Vector2.ZERO
		buttons_container.size = Vector2.ZERO
		buttons_container.position = Vector2.ZERO
		
		for child in buttons_container.get_children():
			child.queue_free()
		
	# 3. VIRTUAL CALL: Execute child geometric arrangement (e.g., Hexagonal layout)
	_generate_geometric_structure()


## Captures global clicks that bypassed the UI to close the menu dynamically.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_animating and visible:
			close_menu()


## PUBLIC API: Configures the action page matrix sent by the Gameplay Director.
func configure_menu(data_by_pages: Array) -> void:
	paginas_acciones = data_by_pages
	pagina_actual = 0
	_update_page_view()


## Processes the visibility and icons of the buttons based on the currently active page.
func _update_page_view() -> void:
	var datos_pagina = paginas_acciones[pagina_actual] if not paginas_acciones.is_empty() else []
	
	# 1. Update standard action buttons
	for i in range(botones_accion.size()):
		var btn = botones_accion[i]
		if not is_instance_valid(btn): 
			continue
		
		if i < datos_pagina.size() and datos_pagina[i].get("id", "") != "":
			var action_data = datos_pagina[i]
			btn.action_name = action_data.get("id", "")
			btn.get_node("Icon").texture = action_data.get("icono", unknown_icon) if action_data.get("icono", null) != null else unknown_icon
			btn.modulate.a = 1.0 
			_configure_interaction(btn, action_data.get("descripcion", ""), true)
		else:
			_deactivate_button(btn)
			_configure_interaction(btn, "", false)

	# 2. Pagination controls evaluation
	var has_prev: bool = pagina_actual > 0
	var has_next: bool = pagina_actual < paginas_acciones.size() - 1 if not paginas_acciones.is_empty() else false
	
	_manage_pagination_button(btn_prev, "pagina_anterior", has_prev, tr("RADIAL_MENU_PREV_PAGE"), icon_prev)
	_manage_pagination_button(btn_next, "pagina_siguiente", has_next, tr("RADIAL_MENU_NEXT_PAGE"), icon_next)


## Manages visibility and interactions for a specific pagination button safely.
func _manage_pagination_button(btn: EssenceBaseInteractionButton, action: String, condition: bool, tooltip: String, active_icon: Texture2D) -> void:
	if not is_instance_valid(btn): 
		return
		
	if condition:
		btn.action_name = action
		btn.modulate.a = 1.0
		if active_icon:
			btn.get_node("Icon").texture = active_icon
		_configure_interaction(btn, tooltip, true)
	else:
		btn.action_name = ""
		btn.modulate.a = 0.3 # Semi-transparent disabled visual state
		if active_icon:
			btn.get_node("Icon").texture = active_icon
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


## Resets and disables a button safely, showing the unknown icon instead of hiding it.
func _deactivate_button(btn: EssenceBaseInteractionButton) -> void:
	if not is_instance_valid(btn): 
		return
		
	btn.action_name = ""
	btn.modulate.a = 1.0 
	if unknown_icon:
		btn.get_node("Icon").texture = unknown_icon


## Helper utility to safely extract the actual dimensions of a slot node dynamically.
func _get_slot_size(btn: EssenceBaseInteractionButton) -> Vector2:
	if btn.custom_minimum_size != Vector2.ZERO:
		return btn.custom_minimum_size
	return btn.size


## PUBLIC API: Smoothly deploys the menu by interpolating buttons to their calculated geometric target coordinates.
func open_menu(global_click_position: Vector2) -> void:
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
		var slot_size = _get_slot_size(btn)
		btn.position = -(slot_size / 2.0)
		var pos_final = btn.get_meta("pos_final", Vector2.ZERO)
		tween.tween_property(btn, "position", pos_final, animation_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	tween.chain().tween_callback(func(): is_animating = false)


## PUBLIC API: Smoothly retracts and hides the menu using a scale down transition, resetting interaction locks.
func close_menu() -> void:
	if is_animating or not visible: 
		return
		
	is_animating = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, animation_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anchor, "scale", Vector2(0.1, 0.1), animation_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	for btn in buttons_container.get_children():
		var slot_size = _get_slot_size(btn)
		tween.tween_property(btn, "position", -(slot_size / 2.0), animation_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
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
	
	# Center the button pivot according to the mathematically calculated local coordinates[cite: 8]
	var slot_size = _get_slot_size(btn)
	btn.set_meta("pos_final", local_position - (slot_size / 2.0))
	btn.action_name = initial_action
	btn.action_chosen.connect(_on_action_button)
	return btn
	

# ==========================================
# TEMPORARY UI TELEMETRY DIAGNOSTIC LAYER
# ==========================================

var _debug_time_accumulator: float = 0.0

func _process(delta: float) -> void:
	if not visible:
		return
		
	_debug_time_accumulator += delta
	if _debug_time_accumulator >= 0.5:
		_debug_time_accumulator = 0.0
		_run_mouse_diagnostic()


func _run_mouse_diagnostic() -> void:
	var global_mouse_pos: Vector2 = get_global_mouse_position()
	
	print("\n--- [UI MOUSE DIAGNOSTIC START] ---")
	print("Global Mouse Position: ", global_mouse_pos)
	print("Menu Root | Visible: ", visible, " | Filter: ", mouse_filter)
	
	if is_instance_valid(buttons_container):
		print("ButtonsContainer | Filter: ", buttons_container.mouse_filter, " | Size: ", buttons_container.size, " | Global Pos: ", buttons_container.global_position)
	
	var inspect_slot = func(slot_label: String, slot_control: Control) -> void:
		if not is_instance_valid(slot_control):
			print("  [", slot_label, "] State: NULL / INVALID NODE")
			return
			
		var slot_rect: Rect2 = slot_control.get_global_rect()
		var is_inside_slot: bool = slot_rect.has_point(global_mouse_pos)
		
		print("  [", slot_label, "] Visible: ", slot_control.visible, 
			" | Filter: ", slot_control.mouse_filter, 
			" | Rect: ", slot_rect, 
			" | Mouse Inside Rect: ", is_inside_slot)
			
		var internal_btn = slot_control.get_node_or_null("Btn") as TextureButton
		if is_instance_valid(internal_btn):
			var btn_rect: Rect2 = internal_btn.get_global_rect()
			print("    └── Sub-Btn | Filter: ", internal_btn.mouse_filter, 
				" | Rect: ", btn_rect, 
				" | Engine Hovered: ", internal_btn.is_hovered())
		else:
			print("    └── Warning: Internal 'Btn' node missing or structural type mismatch.")

	for i in range(botones_accion.size()):
		inspect_slot.call("Action_Slot_" + str(i), botones_accion[i])
		
	inspect_slot.call("Pagination_Prev", btn_prev)
	inspect_slot.call("Pagination_Next", btn_next)
	print("--- [UI MOUSE DIAGNOSTIC END] ---\n")
