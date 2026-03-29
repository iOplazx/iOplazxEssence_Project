class_name EssenceSaveLoadController extends Control

# ==========================================
# REFERENCIAS UI
# ==========================================
@export_category("Contenedores Visuales")
@export var grid_classic: GridContainer
@export var list_modern: VBoxContainer
@export var lbl_title: Label

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
	
	# Leemos de las preferencias qué estilo eligió el jugador en los Ajustes
	_current_style = Preferences.get_setting("game", "save_style", 0)
	
	# Por defecto, abrimos en modo "Cargar", pero si venimos del juego pausado, 
	# podríamos cambiar esto a "Guardar"
	_set_mode(false) 
	
	_generar_botones_paginacion()
	_refresh_slots()

func _conectar_botones_estaticos():
	if btn_back: btn_back.pressed.connect(func(): AudioManager.play_ui_sfx(); SceneManager.go_back())
	if btn_mode_save: btn_mode_save.pressed.connect(func(): _set_mode(true))
	if btn_mode_load: btn_mode_load.pressed.connect(func(): _set_mode(false))

func _set_mode(is_save: bool):
	_is_save_mode = is_save
	lbl_title.text = tr("MENU_SAVE_GAME") if _is_save_mode else tr("MENU_LOAD_GAME")
	AudioManager.play_ui_sfx()
	_refresh_slots()

# ==========================================
# GENERACIÓN DE SLOTS
# ==========================================
func _refresh_slots():
	# 1. Limpiamos y mostramos con redes de seguridad
	if grid_classic:
		for c in grid_classic.get_children(): c.queue_free()
		grid_classic.visible = (_current_style == 0)
		
	if list_modern:
		for c in list_modern.get_children(): c.queue_free()
		list_modern.visible = (_current_style == 1)
	
	# 2. Generamos los 6 slots de la página actual
	for i in range(_slots_per_page):
		var slot_id = ""
		if _current_page == 0:
			slot_id = "auto_" + str(i + 1)
		else:
			var slot_num = ((_current_page - 1) * _slots_per_page) + (i + 1)
			slot_id = "save_" + str(_current_page) + "_" + str(i + 1) 
			
		_crear_instancia_slot(slot_id)

func _crear_instancia_slot(slot_id: String):
	# TODO: Aquí le pediremos al SaveManager si existe un archivo para este slot_id
	var mock_data: Dictionary = {}
	
	if _current_style == 0:
		var slot = prefab_classic.instantiate()
		grid_classic.add_child(slot)
		slot.setup(slot_id, mock_data, _is_save_mode)
		slot.on_slot_clicked.connect(_handle_slot_action)
	else:
		var slot = prefab_modern.instantiate()
		list_modern.add_child(slot)
		slot.setup(slot_id, mock_data, _is_save_mode)
		slot.on_action_requested.connect(_handle_slot_action)

# ==========================================
# ACCIONES GLOBALES
# ==========================================
func _handle_slot_action(action: String, slot_id: String):
	AudioManager.play_ui_sfx()
	
	# Revisamos si el jugador quiere confirmaciones en los ajustes
	var ask_confirm = Preferences.get_setting("game", "confirm_on_save", true)
	
	if ask_confirm:
		# Mostrar el EssenceConfirmBox aquí antes de ejecutar
		print("iOplazxEssence: Abriendo caja de confirmación para ", action, " en ", slot_id)
		# ... lógica de tu confirm box ...
	else:
		print("iOplazxEssence: Ejecutando ", action, " directamente en ", slot_id)
		# TODO: Ejecutar el guardado/cargado real
		
	# Después de guardar/borrar, recargamos la vista
	_refresh_slots()

# ==========================================
# PAGINACIÓN BÁSICA (A, 1, 2, 3...)
# ==========================================
func _generar_botones_paginacion():
	# Limpiamos si hay botones viejos
	for c in box_pagination.get_children(): c.queue_free()
	
	var btn_auto = Button.new()
	btn_auto.text = "A"
	btn_auto.pressed.connect(func(): _cambiar_pagina(0))
	box_pagination.add_child(btn_auto)
	
	for i in range(1, 10): # Generamos 9 páginas de ejemplo
		var btn = Button.new()
		btn.text = str(i)
		btn.pressed.connect(func(): _cambiar_pagina(i))
		box_pagination.add_child(btn)

func _cambiar_pagina(page_num: int):
	if _current_page != page_num:
		_current_page = page_num
		AudioManager.play_ui_sfx()
		_refresh_slots()
