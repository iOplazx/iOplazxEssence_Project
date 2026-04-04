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

@export_category("Control de Archivos")
@export var btn_export: Button
@export var btn_import: Button

# Supongamos que tienes una referencia al FileDialog
@onready var export_dialog: FileDialog = $ExportDialog

# --- EL CEREBRO DE LA PAGINACIÓN ---
var paginator: EssencePaginator = EssencePaginator.new()

# ==========================================
# ESTADO INTERNO
# ==========================================
var _slots_per_page: int = 6

# true = Guardar, false = Cargar
var _is_save_mode: bool = false 
# 0 = Classic (Ren'Py), 1 = Modern (Lista)
var _current_style: int = 0 

var _all_saves_meta: Dictionary = {}

# Variable para saber si exportamos uno o todos
var _export_all: bool = false
var _current_slot_to_export: String = ""

const EXPORT_MENU_SCENE = preload( EssencePaths.PATH_UI_OVERLAYS + "EssenceExportMenu.tscn")

func _ready():
	_conectar_botones_estaticos()
	
	_current_style = Preferences.get_setting("game", "save_style", 0)
	
	_all_saves_meta = SaveManager.get_all_metadata()
	if _current_style == 0:
		_saltar_a_pagina_reciente()
	
	# Inicializamos la paginación visualmente
	_generar_botones_paginacion()
	
	var open_as_save = SaveManager.intent_is_save_mode
	_set_mode(open_as_save)
	
	on_export_dialog_config()
	
	
func on_export_dialog_config():
	if export_dialog:
		export_dialog.dir_selected.connect(_on_export_dir_selected)
	else:
		print("export_dialog no fue encontrado")
	
func _conectar_botones_estaticos():
	if btn_back:
		btn_back.pressed.connect(func(): 
			AudioManager.play_ui_sfx()
			SaveManager.delete_temp_screenshot()
			SceneManager.go_back()
		)
	if btn_mode_save: btn_mode_save.pressed.connect(func(): _set_mode(true))
	if btn_mode_load: btn_mode_load.pressed.connect(func(): _set_mode(false))
	
	if btn_import: btn_import.pressed.connect(_on_import_file_pressed)
	if btn_export: btn_export.pressed.connect(_on_export_file_pressed)

func _set_mode(is_save: bool):
	_is_save_mode = is_save
	
	var final_title = ""
	if _current_style == 1:
		final_title = tr("PAGE_TITLE_SAVES_MODERN") 
	else:
		final_title = tr("PAGE_TITLE_SAVE") if _is_save_mode else tr("PAGE_TITLE_LOAD")
		
	if lbl_title:
		lbl_title.text = final_title
		
	if btn_mode_save: btn_mode_save.disabled = _is_save_mode
	if btn_mode_load: btn_mode_load.disabled = not _is_save_mode
	
	AudioManager.play_ui_sfx()
	_refresh_slots()

# ==========================================
# GESTIÓN VISUAL (REFRESH)
# ==========================================
func _refresh_slots():
	var is_classic = (_current_style == 0)
	_all_saves_meta = SaveManager.get_all_metadata()
	
	# 1. Visibilidad: Modo Clásico
	if grid_classic: 
		grid_classic.visible = is_classic
		var classic_scroll = grid_classic
		while classic_scroll and not classic_scroll is ScrollContainer:
			classic_scroll = classic_scroll.get_parent()
		if classic_scroll:
			classic_scroll.visible = is_classic
			classic_scroll.mouse_filter = Control.MOUSE_FILTER_PASS if is_classic else Control.MOUSE_FILTER_IGNORE
			
	# 2. Visibilidad: Modo Moderno
	if list_modern: 
		list_modern.visible = not is_classic
		var modern_scroll = list_modern
		while modern_scroll and not modern_scroll is ScrollContainer:
			modern_scroll = modern_scroll.get_parent()
		if modern_scroll:
			modern_scroll.visible = not is_classic
			modern_scroll.mouse_filter = Control.MOUSE_FILTER_PASS if not is_classic else Control.MOUSE_FILTER_IGNORE
	
	# 3. Visibilidad de Elementos Exclusivos
	if mode_toggle_container: mode_toggle_container.visible = is_classic
	if pagination_container: pagination_container.visible = is_classic
	
	# 4. Generación de Contenido
	if is_classic:
		_generar_slots_classic()
	else:
		_generar_slots_modern()

# ==========================================
# GENERACIÓN LÓGICA DE SLOTS
# ==========================================
func _generar_slots_classic():
	if not grid_classic: return
	for c in grid_classic.get_children(): c.queue_free()
	
	var current_p = paginator.current_page 
	
	for i in range(EssenceSlotMapper.SLOTS_PER_PAGE):
		# Uso del Mapper para calcular el ID exacto
		var slot_id = EssenceSlotMapper.get_id_for_grid(current_p, i)
		var real_data = _all_saves_meta.get(slot_id, {})
		
		_crear_instancia_slot(slot_id, grid_classic, real_data)

func _generar_slots_modern():
	if not list_modern: return
	
	for c in list_modern.get_children(): 
		if c != btn_add_new_slot: 
			c.queue_free()
			
	# 1. Extraemos los slots manuales que ya existen
	var existing_manual_saves = []
	for key in _all_saves_meta.keys():
		if key.begins_with("save_"):
			existing_manual_saves.append(key)
			
	# 2. Dibujamos las partidas reales
	for slot_id in existing_manual_saves:
		_crear_instancia_slot(slot_id, list_modern, _all_saves_meta[slot_id])
		
	# 3. Rellenamos con slots virtuales si hay menos de 5
	var current_count = existing_manual_saves.size()
	var min_virtuals = 5
	
	if current_count < min_virtuals:
		var missing_slots = min_virtuals - current_count
		var added_virtuals = 0
		var search_page = 1
		var search_index = 0
		
		while added_virtuals < missing_slots:
			var potential_id = EssenceSlotMapper.get_id_for_grid(search_page, search_index)
			if not _all_saves_meta.has(potential_id):
				_crear_instancia_slot(potential_id, list_modern, {})
				added_virtuals += 1
				
			search_index += 1
			if search_index >= EssenceSlotMapper.SLOTS_PER_PAGE:
				search_index = 0
				search_page += 1

	# 4. Configurar el botón "Crear Nuevo" al final de la lista
	if btn_add_new_slot:
		var has_live_data = not SaveManager._temp_game_data.is_empty()
		
		btn_add_new_slot.visible = has_live_data
		
		if btn_add_new_slot.pressed.is_connected(_on_add_new_pressed):
			btn_add_new_slot.pressed.disconnect(_on_add_new_pressed)
		btn_add_new_slot.pressed.connect(_on_add_new_pressed)
		
		var real_parent = btn_add_new_slot.get_parent()
		if real_parent:
			real_parent.move_child(btn_add_new_slot, -1)

func _crear_instancia_slot(slot_id: String, container: Control, save_data: Dictionary = {}):
	if _current_style == 0:
		# El Clásico sigue obedeciendo a sus pestañas (_is_save_mode)
		var slot = prefab_classic.instantiate()
		container.add_child(slot)
		slot.setup(slot_id, save_data, _is_save_mode)
		slot.on_slot_clicked.connect(_handle_slot_action)
	else:
		# El Moderno obedece a la existencia de una partida viva
		var slot = prefab_modern.instantiate()
		container.add_child(slot)
		
		# ¿Hay datos vivos en la RAM listos para guardarse?
		var has_live_data = not SaveManager._temp_game_data.is_empty()
		
		slot.setup(slot_id, save_data, has_live_data)
		slot.on_action_requested.connect(_handle_slot_action)

func _on_add_new_pressed():
	AudioManager.play_ui_sfx()
	var target_slot_id = EssenceSlotMapper.get_next_empty_slot_id(_all_saves_meta)
	
	# 1. Ejecutamos el guardado
	# Si _handle_slot_action no es async, asegúrate de que SaveManager.commit_save devuelva true
	_handle_slot_action("SAVE", target_slot_id)
	
	# 2. ESPERA CRÍTICA:
	# Esperamos un instante a que el sistema operativo registre el nuevo archivo .webp
	await get_tree().create_timer(0.1).timeout
	
	# 3. Refrescamos la lista de slots
	_refresh_slots()

# ==========================================
# ACCIONES GLOBALES (GUARDAR / CARGAR)
# ==========================================
func _handle_slot_action(action: String, slot_id: String):
	AudioManager.play_ui_sfx()
	
	var slot_has_data = _all_saves_meta.has(slot_id)
	
	# === LÓGICA DE EDICIÓN ===
	if action == "EDIT":
		_mostrar_dialogo_edicion(slot_id, _all_saves_meta[slot_id].get("title", ""))
		return
	
	# === VERIFICACIÓN DE PREFERENCIAS DE CONFIRMACIÓN ===
	var ask_confirm: bool = true
	
	if action == "SAVE":
		ask_confirm = Preferences.get_setting("game", "confirm_save", true)
		# Excepción de UX: Si el slot está vacío, guardamos directo sin preguntar, 
		# sin importar cómo estén las preferencias.
		if not slot_has_data:
			ask_confirm = false
			
	elif action == "LOAD":
		ask_confirm = Preferences.get_setting("game", "confirm_load", true)
		
	elif action == "DELETE":
		ask_confirm = Preferences.get_setting("game", "confirm_delete", true)
	
	# === LÓGICA DE SALTO DE CONFIRMACIÓN ===
	if not ask_confirm:
		_ejecutar_accion_real(action, slot_id)
		return
		
	# === CAJA DE CONFIRMACIÓN (SAVE, LOAD, DELETE) ===
	var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	get_tree().root.add_child(box)
	
	var title = ""
	var msg = ""
	
	if action == "SAVE":
		# Ya sabemos que si llegó aquí es porque tiene datos (por la excepción de arriba), 
		# así que siempre será un mensaje de Sobrescribir.
		title = "OVERWRITE_SAVE_TITLE"
		msg = "OVERWRITE_SAVE_MSG"
	elif action == "LOAD":
		title = "LOAD_SAVE_TITLE"
		msg = "LOAD_SAVE_MSG"
	elif action == "DELETE":
		title = "DELETE_SAVE_TITLE"
		msg = "DELETE_SAVE_MSG"

	box.setup(title, msg, "MENU_YES", "MENU_NO")
	
	box.on_choice.connect(func(accepted: bool):
		if accepted:
			_ejecutar_accion_real(action, slot_id)
		box.queue_free() 
	)
	
func _mostrar_dialogo_edicion(slot_id: String, current_title: String):
	var input_prefab = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceInputBox.tscn")
	if not input_prefab: return
		
	var input_box = input_prefab.instantiate()
	get_tree().root.add_child(input_box)
	
	input_box.setup("RENAME_SAVE_TITLE", "RENAME_SAVE_MSG", current_title)
	
	input_box.on_submit.connect(func(new_text: String):
		if new_text.strip_edges() != "":
			# 1. Le pedimos al Manager que guarde en el disco
			SaveManager.update_save_title(slot_id, new_text)
			
			# 2. Actualizamos nuestra caché local de la interfaz
			if _all_saves_meta.has(slot_id):
				_all_saves_meta[slot_id]["title"] = new_text
				
			# 3. Recargamos los slots para que el texto cambie visualmente
			_refresh_slots() 
			
		input_box.queue_free()
	)
	
func _ejecutar_accion_real(action: String, slot_id: String):
	if action == "SAVE":
		var success = SaveManager.commit_save(slot_id)
		if success:
			_refresh_slots() 
			
	elif action == "LOAD":
		var data = SaveManager.load_game(slot_id)
		if not data.is_empty() and data.has("game_data"):
			# 1. Cargamos los datos a la RAM
			SaveManager.loaded_game_data = data["game_data"]
			
			print("iOplazxEssence: Datos en RAM. Viajando a la escena principal...")
			
			# 2. Leemos la ruta maestra que el Dev configuró en su RouteConfig.tres
			# (Asumo que tienes acceso a tu config a través del SceneManager)
			var target_scene = SceneManager._config.continue_game_scene 
			
			# Fallback de seguridad por si el Dev olvidó llenarlo
			if target_scene == "":
				target_scene = SceneManager._config.main_menu_scene 
			
			# 3. Viajamos limpiando el historial para que el juego arranque fresco
			SceneManager.goto_loaded_game(target_scene)
			
			# 4. Destruimos este menú para no dejar interfaces fantasma
			self.queue_free()
	elif action == "DELETE":
		SaveManager.delete_save(slot_id)
		_refresh_slots()

# ==========================================
# DELEGACIÓN DE UI (PAGINADOR)
# ==========================================
func _generar_botones_paginacion():
	for c in box_pagination.get_children(): c.queue_free()
	
	var p_state = paginator.get_ui_state(9)
	
	for btn_data in p_state.buttons_to_draw:
		var btn = Button.new()
		btn.text = btn_data.label
		btn.disabled = btn_data.is_active
		btn.pressed.connect(func(): _cambiar_pagina(btn_data.page_num))
		
		box_pagination.add_child(btn)

func _cambiar_pagina(page_num: int):
	if paginator.set_page(page_num):
		AudioManager.play_ui_sfx()
		_generar_botones_paginacion() 
		_refresh_slots()
		
# ==========================================
# UX: SALTO INTELIGENTE A LA ÚLTIMA PARTIDA
# ==========================================
func _saltar_a_pagina_reciente():
	var highest_manual_time: float = -1.0
	var highest_auto_time: float = -1.0
	var target_manual_page: int = 1
	
	for slot_id in _all_saves_meta.keys():
		var meta = _all_saves_meta[slot_id]
		var time = meta.get("timestamp", 0.0)
		
		# Verificamos manuales
		if slot_id.begins_with("save_"):
			if time > highest_manual_time:
				highest_manual_time = time
				# Extraemos la página directamente del nombre del ID (ej. "save_3_1" -> 3)
				var parts = slot_id.split("_")
				if parts.size() >= 3:
					target_manual_page = parts[1].to_int()
					
		# Verificamos automáticos
		elif slot_id.begins_with("auto_"):
			if time > highest_auto_time:
				highest_auto_time = time
				
	# Aplicamos las reglas de prioridad
	if highest_manual_time > -1.0:
		paginator.set_page(target_manual_page)
	elif highest_auto_time > -1.0:
		paginator.set_page(0) # Página de Auto-saves
	else:
		paginator.set_page(1) # Valor por defecto si no hay nada
		
func _on_import_file_pressed():
	var x = 1

func _on_export_file_pressed():
	AudioManager.play_ui_sfx()
	print("iOplazxEssence: Iniciando proceso de exportación...")
		
	# Instanciamos tu menú personalizado SIN bloqueos previos
	var export_menu = EXPORT_MENU_SCENE.instantiate()
	add_child(export_menu)
	
	export_menu.on_option_selected.connect(func(opcion: String):
		if opcion == "CANCEL":
			return
			
		elif opcion == "CURRENT":
			# LA MAGIA LOGICA AQUI:
			# 1. Si hay una partida viva en RAM -> Exportamos el Snapshot (Pasa directo)
			# 2. Si NO hay partida viva en RAM (ej: Menú principal) -> 
			#    Exigimos que el usuario haya seleccionado una tarjeta del Grid.
			if not SaveManager.has_live_session() and _current_slot_to_export == "":
				_mostrar_alerta(tr("DIALOG_WARNING_TITLE"), tr("DIALOG_SELECT_SLOT_MSG"))
				return
				
			_export_all = false
			_abrir_file_dialog_exportacion()
			
		elif opcion == "ALL":
			_export_all = true
			_abrir_file_dialog_exportacion()
	)
	
func _abrir_file_dialog_exportacion():
	# 1. Asignamos el título traducido
	export_dialog.title = tr("FILEDIALOG_TITLE")
	
	# 2. Mostramos el FileDialog de Windows/Linux
	export_dialog.popup_centered_ratio(0.6)

# Se conecta a la señal 'dir_selected' del FileDialog
func _on_export_dialog_dir_selected(dir_path: String):
	if _export_all:
		_ejecutar_exportacion_masiva(dir_path)
	else:
		_ejecutar_exportacion_individual(dir_path)

func _ejecutar_exportacion_individual(dest_path: String):
	# Llamamos a tu clase utilitaria que creamos antes
	var exito = EssenceExportUtils.export_slot(
		_current_slot_to_export, 
		SaveManager._save_dir, 
		dest_path
	)
	
	if exito:
		AudioManager.play_ui_sfx() # Sonido de éxito
		_mostrar_alerta("Éxito", "La partida se ha exportado correctamente a:\n" + dest_path)
	else:
		_mostrar_alerta("Error", "Hubo un problema al exportar la partida. Revisa la consola.")

func _ejecutar_exportacion_masiva(dest_path: String):
	# Aquí podrías iterar sobre todos los archivos en SaveManager._save_dir
	# y copiarlos a una carpeta "Full_Backup"
	pass
	
func _on_export_current_pressed():
	AudioManager.play_ui_sfx()
	export_dialog.popup_centered_ratio(0.6) # Abre la ventana de Windows/Linux
	
func _on_export_dir_selected(dir_path: String):
	# Opcional: Si tienes tu nodo ColorRect de bloqueo (Overlay), puedes activarlo aquí
	# para que el usuario no toque nada mientras el Athlon procesa.
	
	# PASO 1: Hacemos el "Snapshot" a la carpeta temporal
	var nombre_unico = "export_" + str(Time.get_unix_time_from_system())
	var snapshot_success = SaveManager.commit_save(nombre_unico, true)
	
	if snapshot_success:
		# PASO 2: Usamos TU función estática, pero le decimos que busque en 'temp/'
		var export_success = EssenceExportUtils.export_slot(
			nombre_unico, 
			"user://saves/temp/", # <--- Origen: La aduana temporal
			dir_path              # <--- Destino: La carpeta que eligió el jugador
		)
		
		if export_success:
			AudioManager.play_ui_sfx()
			_mostrar_alerta("Éxito", "Partida exportada correctamente a:\n" + dir_path)
			
			# eliminar los archivos imagen pero conservar los archivos exportados para poder recuperarlos despues
			_limpiar_aduana_temporal(nombre_unico,false, true) 
		else:
			_mostrar_alerta("Error", "No se pudo copiar el archivo de respaldo al destino.")
			
	else:
		_mostrar_alerta("Error", "Fallo al generar el archivo de guardado temporal.")

# ==========================================
# UTILIDAD DE LIMPIEZA
# ==========================================
func _limpiar_aduana_temporal(nombre_archivo: String, delete_file: bool, delete_img: bool):
	var dir = DirAccess.open("user://saves/temp/")
	if dir:
		if delete_file && dir.file_exists(nombre_archivo + GameConstants.EXTENSION_SAVE_FILE):
			dir.remove(nombre_archivo + GameConstants.EXTENSION_SAVE_FILE)
		if delete_img && dir.file_exists(nombre_archivo + GameConstants.EXTENSION_IMAGE):
			dir.remove(nombre_archivo + GameConstants.EXTENSION_IMAGE)

# ==========================================
# UTILIDAD DE UI: Mostrar alertas rápidas
# ==========================================
func _mostrar_alerta(titulo: String, mensaje: String):
	var dialog = AcceptDialog.new()
	dialog.title = titulo
	dialog.dialog_text = mensaje
	
	# Lo añadimos a la escena actual
	add_child(dialog)
	dialog.popup_centered()
	
	# Cuando el usuario le da "OK", borramos el nodo para no ensuciar la RAM
	dialog.confirmed.connect(func(): dialog.queue_free())
