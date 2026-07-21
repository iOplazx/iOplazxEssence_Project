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
	# 1. VERIFIED RADIAL BLUEPRINT FIXED LAYER: 
	# Forcibly expands the root menu to occupy 100% of the screen viewport size.
	# This ensures the mouse pointer is ALWAYS within parent boundaries, unblocking child input picking.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	visible = false
	modulate.a = 0.0 
	
	# Elevate parent canvas priority dynamically if available
	var parent_canvas = get_parent() as CanvasLayer
	if parent_canvas:
		parent_canvas.visible = true
		parent_canvas.layer = 100
	
	if is_instance_valid(anchor):
		anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		anchor.scale = Vector2(0.1, 0.1)
	
	# 2. CONTAINER NORMALIZATION LAYER: Strip sizes and set to IGNORE.
	if is_instance_valid(buttons_container):
		buttons_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buttons_container.custom_minimum_size = Vector2.ZERO
		buttons_container.size = Vector2.ZERO
		buttons_container.position = Vector2.ZERO
		
		for child in buttons_container.get_children():
			child.queue_free()
		
	# 3. VIRTUAL CALL: Execute child geometric arrangement (e.g., Hexagonal layout)
	_generate_geometric_structure()


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
			
			# ===================================================================
			# RESOLUCIÓN DE TEXTURA (Soporta objetos Texture2D y rutas String)
			# ===================================================================
			var raw_icon = action_data.get("icono", null)
			var resolved_texture: Texture2D = unknown_icon
			
			if raw_icon is Texture2D:
				resolved_texture = raw_icon
			elif raw_icon is String and not raw_icon.is_empty():
				if ResourceLoader.exists(raw_icon):
					resolved_texture = load(raw_icon) as Texture2D
				else:
					push_warning("[%s] ⚠️ No se encontró la textura en la ruta: %s" % [name, raw_icon])
			
			var icon_node = btn.get_node_or_null("Icon") as TextureRect
			if is_instance_valid(icon_node):
				icon_node.texture = resolved_texture
			# ===================================================================
			
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
		btn.modulate.a = 0.3
		if active_icon:
			btn.get_node("Icon").texture = active_icon
		_configure_interaction(btn, "", false)

## Configures the mouse filtering rules and tooltips for interaction buttons.
func _configure_interaction(btn_raiz: Control, text: String, activated: bool) -> void:
	btn_raiz.tooltip_text = text
	var filtro_deseado = Control.MOUSE_FILTER_STOP if activated else Control.MOUSE_FILTER_IGNORE
	
	# THE SLOT IS NOW THE KING: The root control node handles the interaction area directly
	btn_raiz.mouse_filter = filtro_deseado
	
	# GHOST LAYER: We force all visual child nodes to IGNORE inputs so they don't block the root rect
	var nodo_hijo = btn_raiz.get_node_or_null("Btn")
	if nodo_hijo:
		nodo_hijo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	var nodo_icono = btn_raiz.get_node_or_null("Icon")
	if is_instance_valid(nodo_icono) and nodo_icono is Control:
		nodo_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	
	var slot_size = _get_slot_size(btn)
	btn.set_meta("pos_final", local_position - (slot_size / 2.0))
	btn.action_name = initial_action
	btn.action_chosen.connect(_on_action_button)
	return btn
