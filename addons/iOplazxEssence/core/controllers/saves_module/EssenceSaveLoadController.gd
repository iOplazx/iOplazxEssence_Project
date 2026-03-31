class_name EssenceSaveLoadController extends Control

# ==========================================
# REFERENCIAS UI
# ==========================================
@export_category("Contenedores Visuales")
@export var grid_classic: GridContainer
@export var list_modern: VBoxContainer
@export var lbl_title: Label

@export_category("Contenedores de Modo")
@export var mode_toggle_container: Control  
@export var pagination_container: Control   
@export var btn_add_new_slot: Button        

@export_category("Paginación y Modos")
@export var box_pagination: HBoxContainer
@export var btn_mode_save: Button
@export var btn_mode_load: Button
@export var btn_back: Button

@export_category("Prefabs de Slots")
@export var prefab_classic: PackedScene
@export var prefab_modern: PackedScene

# ==========================================
# ESTADO INTERNO
# ==========================================
# 0 = Autosaves (A), 1 = Página 1, etc.
var _current_page: int = 1 
var _slots_per_page: int = 6

# true = Guardar, false = Cargar
var _is_save_mode: bool = false 
# 0 = Classic (Ren'Py), 1 = Modern (Lista)
var _current_style: int = 0 

func _ready():
	_conectar_botones_estaticos()
	
	_current_style = Preferences.get_setting("game", "save_style", 0)
	_generar_botones_paginacion()
	
	# Leemos la intención y ponemos un print para debuggear
	var open_as_save = SaveManager.intent_is_save_mode
	print("iOplazxEssence: Abriendo pantalla de guardado. ¿Es modo Save?: ", open_as_save)
	
	_set_mode(open_as_save)
	# Nota: Borré el _refresh_slots() que tenías aquí abajo porque _set_mode ya lo llama.

func _conectar_botones_estaticos():
	if btn_back: btn_back.pressed.connect(func(): AudioManager.play_ui_sfx(); SceneManager.go_back())
	if btn_mode_save: btn_mode_save.pressed.connect(func(): _set_mode(true))
	if btn_mode_load: btn_mode_load.pressed.connect(func(): _set_mode(false))

func _set_mode(is_save: bool):
	_is_save_mode = is_save
	
	# 1. Ajuste del Título (Neutro para Moderno, Específico para Clásico)
	var final_title = ""
	if _current_style == 1:
		final_title = tr("PAGE_TITLE_SAVES_MODERN") 
	else:
		final_title = tr("PAGE_TITLE_SAVE") if _is_save_mode else tr("PAGE_TITLE_LOAD")
		
	# Verificamos si el nodo del Título existe antes de intentar cambiarlo
	if lbl_title:
		lbl_title.text = final_title
	else:
		push_error("iOplazxEssence CRÍTICO: 'lbl_title' está vacío. ¡Arrastra el Label de título al Inspector!")
		
	# 2. Ajuste visual de las pestañas (Solo relevante en Clásico)
	if btn_mode_save: 
		btn_mode_save.disabled = _is_save_mode
	else:
		push_warning("iOplazxEssence: No asignaste 'btn_mode_save' en el Inspector.")
		
	if btn_mode_load: 
		btn_mode_load.disabled = not _is_save_mode
	else:
		push_warning("iOplazxEssence: No asignaste 'btn_mode_load' en el Inspector.")
	
	AudioManager.play_ui_sfx()
	_refresh_slots()

# ==========================================
# GENERACIÓN DE SLOTS
# ==========================================
func _refresh_slots():
	var is_classic = (_current_style == 0)
	
	# 1. Visibilidad de Contenedores Principales
	if grid_classic: grid_classic.visible = is_classic
	if list_modern: list_modern.get_parent().visible = not is_classic
	
	# 2. Visibilidad de Elementos Exclusivos
	if mode_toggle_container: mode_toggle_container.visible = is_classic
	if pagination_container: pagination_container.visible = is_classic
	
	# 3. Tratamiento especial del botón "Añadir"
	if btn_add_new_slot: 
		btn_add_new_slot.visible = not is_classic
		if not is_classic:
			# Lo movemos siempre al final de la lista
			btn_add_new_slot.get_parent().move_child(btn_add_new_slot, -1)

	# 4. Generación de Contenido
	if is_classic:
		_generar_slots_classic()
	else:
		_generar_slots_modern()

func _generar_slots_classic():
	# Limpiamos los slots anteriores
	if grid_classic:
		for c in grid_classic.get_children(): c.queue_free()
	
	# Generamos los 6 slots de la página actual
	for i in range(_slots_per_page):
		var slot_id = ""
		if _current_page == 0:
			slot_id = "auto_" + str(i + 1)
		else:
			var slot_num = ((_current_page - 1) * _slots_per_page) + (i + 1)
			slot_id = "save_" + str(_current_page) + "_" + str(i + 1) 
			
		_crear_instancia_slot(slot_id, grid_classic)

func _generar_slots_modern():
	if list_modern:
		for c in list_modern.get_children(): 
			# Limpiamos todo EXCEPTO el botón de añadir nuevo slot
			if c != btn_add_new_slot: 
				c.queue_free()
	
	# Generamos 5 slots. Al primero le daremos datos falsos para probar el diseño.
	for i in range(5):
		var slot_id = "modern_save_" + str(i + 1)
		var mock_data: Dictionary = {}
			
		_crear_instancia_slot(slot_id, list_modern, mock_data)

func _crear_instancia_slot(slot_id: String, container: Control, mock_data: Dictionary = {}):
	if _current_style == 0:
		var slot = prefab_classic.instantiate()
		container.add_child(slot)
		slot.setup(slot_id, mock_data, _is_save_mode)
		slot.on_slot_clicked.connect(_handle_slot_action)
	else:
		var slot = prefab_modern.instantiate()
		container.add_child(slot)
		slot.setup(slot_id, mock_data, _is_save_mode)
		slot.on_action_requested.connect(_handle_slot_action)

# ==========================================
# ACCIONES GLOBALES
# ==========================================
func _handle_slot_action(action: String, slot_id: String):
	AudioManager.play_ui_sfx()
	
	var ask_confirm = Preferences.get_setting("game", "confirm_on_save", true)
	
	if ask_confirm:
		print("iOplazxEssence: Abriendo caja de confirmación para ", action, " en ", slot_id)
		# ... lógica de tu confirm box ...
	else:
		print("iOplazxEssence: Ejecutando ", action, " directamente en ", slot_id)
		# TODO: Ejecutar el guardado/cargado real
		
	_refresh_slots()

# ==========================================
# PAGINACIÓN BÁSICA (A, 1, 2, 3...)
# ==========================================
func _generar_botones_paginacion():
	for c in box_pagination.get_children(): c.queue_free()
	
	var btn_auto = Button.new()
	btn_auto.text = "A"
	btn_auto.pressed.connect(func(): _cambiar_pagina(0))
	box_pagination.add_child(btn_auto)
	
	for i in range(1, 10): 
		var btn = Button.new()
		btn.text = str(i)
		btn.pressed.connect(func(): _cambiar_pagina(i))
		box_pagination.add_child(btn)

func _cambiar_pagina(page_num: int):
	if _current_page != page_num:
		_current_page = page_num
		AudioManager.play_ui_sfx()
		_refresh_slots()
