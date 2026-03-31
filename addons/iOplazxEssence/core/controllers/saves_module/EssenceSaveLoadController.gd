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

var _all_saves_meta: Dictionary = {}

func _ready():
	_conectar_botones_estaticos()
	
	_current_style = Preferences.get_setting("game", "save_style", 0)
	_generar_botones_paginacion()
	
	# Leemos la intención y ponemos un print para debuggear
	var open_as_save = SaveManager.intent_is_save_mode
	print("iOplazxEssence: Abriendo pantalla de guardado. ¿Es modo Save?: ", open_as_save)
	
	_set_mode(open_as_save)
	

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
	
	_all_saves_meta = SaveManager.get_all_metadata()
	
	print("iOplazxEssence: Datos encontrados en disco: ", _all_saves_meta.keys())
	
	# 1. Visibilidad y Filtros: Modo Clásico
	if grid_classic: 
		grid_classic.visible = is_classic
		# Rastrear hacia arriba hasta encontrar el ScrollContainer clásico
		var classic_scroll = grid_classic
		while classic_scroll and not classic_scroll is ScrollContainer:
			classic_scroll = classic_scroll.get_parent()
		if classic_scroll:
			classic_scroll.visible = is_classic
			classic_scroll.mouse_filter = Control.MOUSE_FILTER_PASS if is_classic else Control.MOUSE_FILTER_IGNORE
			
	# 1.5 Visibilidad y Filtros: Modo Moderno (El culpable)
	if list_modern: 
		list_modern.visible = not is_classic
		# Rastrear hacia arriba hasta encontrar el ScrollContainer moderno (ModernView)
		var modern_scroll = list_modern
		while modern_scroll and not modern_scroll is ScrollContainer:
			modern_scroll = modern_scroll.get_parent()
		if modern_scroll:
			modern_scroll.visible = not is_classic
			modern_scroll.mouse_filter = Control.MOUSE_FILTER_PASS if not is_classic else Control.MOUSE_FILTER_IGNORE
	
	# 2. Visibilidad de Elementos Exclusivos
	if mode_toggle_container: mode_toggle_container.visible = is_classic
	if pagination_container: pagination_container.visible = is_classic
	
	# 3. Tratamiento especial del botón "Añadir"
	if btn_add_new_slot: 
		btn_add_new_slot.visible = not is_classic
		if not is_classic:
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
		
		var real_data = _all_saves_meta.get(slot_id, {})
		
		_crear_instancia_slot(slot_id, grid_classic, real_data)

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
	var slot_has_data = _all_saves_meta.has(slot_id)
	
	# Si el jugador desactivó las confirmaciones en los ajustes y va a guardar en un slot vacío, lo dejamos pasar directo.
	if not ask_confirm and (action == "SAVE" and not slot_has_data):
		_ejecutar_accion_real(action, slot_id)
		return

	# Si llegamos aquí, instanciamos la caja de confirmación
	var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	get_tree().root.add_child(box)
	
	var title = ""
	var msg = ""
	
	# Configuramos los textos dinámicamente según la acción
	if action == "SAVE":
		if slot_has_data:
			title = "OVERWRITE_SAVE_TITLE" # "Sobrescribir Partida"
			msg = "OVERWRITE_SAVE_MSG" # "¿Deseas sobrescribir esta partida? Los datos anteriores se perderán."
		else:
			title = "NEW_SAVE_TITLE" # "Nueva Partida"
			msg = "NEW_SAVE_MSG" # "¿Deseas guardar la partida en este espacio?"
	elif action == "LOAD":
		title = "LOAD_SAVE_TITLE" # "Cargar Partida"
		msg = "LOAD_SAVE_MSG" # "¿Deseas cargar esta partida? El progreso no guardado se perderá."

	# Pasamos las llaves al dialog (tu confirm_box debería usar tr() internamente para traducirlas)
	box.setup(title, msg, "MENU_YES", "MENU_NO")
	
	# Escuchamos la respuesta del usuario
	box.on_choice.connect(func(accepted: bool):
		if accepted:
			_ejecutar_accion_real(action, slot_id)
		else:
			print("iOplazxEssence: Acción cancelada por el usuario.")
			
		# Muy importante: Eliminar el dialog una vez usado
		box.queue_free() 
	)
		
func _ejecutar_accion_real(action: String, slot_id: String):
	if action == "SAVE":
		var success = SaveManager.commit_save(slot_id)
		if success:
			print("iOplazxEssence: Partida guardada con éxito en ", slot_id)
			_refresh_slots() 
			
	elif action == "LOAD":
		var data = SaveManager.load_game(slot_id)
		if not data.is_empty():
			print("iOplazxEssence: Partida cargada. Restaurando mundo...")
			SaveManager.loaded_game_data = data.get("game_data", {})
			SceneManager.go_back()

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
		
