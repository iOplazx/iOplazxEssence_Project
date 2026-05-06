class_name EssenceSaveLoadController extends Control
const ES_NAME_CLASS = "EssenceSaveLoadController"

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
@export var btn_page_prev: Button
@export var btn_page_next: Button
@export var btn_back: Button

@export_category("Prefabs de Slots")
@export var prefab_classic: PackedScene
@export var prefab_modern: PackedScene

@export_category("Control de Archivos")
@export var btn_export: Button
@export var btn_import: Button

@onready var folder_dialog: FileDialog = $FolderDialog

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
const IMPORT_CONFLICT_SCENE = preload(EssencePaths.PATH_UI_OVERLAYS + "EssenceImportConflictBox.tscn")

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
	if folder_dialog:
		folder_dialog.dir_selected.connect(_on_export_dir_selected)
	else:
		print("folder_dialog no fue encontrado")
	
func _conectar_botones_estaticos():
	if btn_back:
		btn_back.pressed.connect(func(): 
			AudioManager.play_ui_sfx()
			SaveManager.delete_temp_screenshot()
			
			# --- EL PUENTE ---
			# Verificamos si hay una sesión en vivo usando tu función 'has_live_session()'
			if SaveManager.has_live_session():
				# Pasamos lo que estaba en el caché temporal a la RAM de carga
				# para que game.gd lo detecte al volver.
				SaveManager.loaded_game_data = SaveManager._temp_game_data.duplicate()
				
				# Opcional: Limpiamos el temporal para que no se quede duplicado
				SaveManager.clear_temp_data()
			
			SceneManager.go_back()
		)
	if btn_mode_save: btn_mode_save.pressed.connect(func(): _set_mode(true))
	if btn_mode_load: btn_mode_load.pressed.connect(func(): _set_mode(false))
	
	if btn_import: btn_import.pressed.connect(_on_import_file_pressed)
	if btn_export: btn_export.pressed.connect(_on_export_file_pressed)
	
	if btn_page_prev: btn_page_prev.pressed.connect(_on_prev_page_pressed)
	if btn_page_next: btn_page_next.pressed.connect(_on_next_page_pressed)
	
	if btn_add_new_slot and not btn_add_new_slot.pressed.is_connected(_on_add_new_pressed):
		btn_add_new_slot.pressed.connect(_on_add_new_pressed)
	
	_bloquear_guardado_desde_menu()
	
func _bloquear_guardado_desde_menu():
	var has_live_data = not SaveManager._temp_game_data.is_empty()
	
	if not has_live_data:
		if btn_mode_save:
			btn_mode_save.disabled = true
			# Al ponerlo en IGNORE, el botón no procesa hover ni clics en absoluto
			btn_mode_save.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Limpiamos cualquier texto de ayuda para que no salga el "globo" de texto
			btn_mode_save.tooltip_text = "" 
			btn_mode_save.modulate.a = 0.5
			
		if btn_add_new_slot:
			btn_add_new_slot.visible = false
			
		# Forzamos que la UI esté en modo LOAD
		_set_mode(false) 
		if btn_mode_load:
			btn_mode_load.button_pressed = true
	else:
		# Si hay datos, nos aseguramos de que el botón sea interactuable de nuevo
		if btn_mode_save:
			btn_mode_save.disabled = false
			btn_mode_save.mouse_filter = Control.MOUSE_FILTER_STOP

func _set_mode(is_save: bool):
	_is_save_mode = is_save
	
	var final_title = ""
	if _current_style == 1:
		final_title = tr("PAGE_TITLE_SAVES_MODERN") 
	else:
		final_title = tr("PAGE_TITLE_SAVE") if _is_save_mode else tr("PAGE_TITLE_LOAD")
		btn_add_new_slot.disabled = true
		btn_add_new_slot.visible = false
		
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
	if not box_pagination: return
	
	# IMPORTANTE: Aseguramos que el contenedor reciba clics
	box_pagination.mouse_filter = Control.MOUSE_FILTER_PASS
	
	for c in box_pagination.get_children(): c.queue_free()
	
	var p_state = paginator.get_ui_state()
	
	# Sincronizamos las flechas con la nueva lógica del bloque 1
	if btn_page_prev: btn_page_prev.disabled = not p_state.can_go_left
	if btn_page_next: btn_page_next.disabled = not p_state.can_go_right
	
	for btn_data in p_state.buttons_to_draw:
		var btn = Button.new()
		btn.text = btn_data.label
		
		# OPTIMIZACIÓN DE CLIC:
		# Damos un tamaño mínimo para que el dedo o mouse no falle el clic
		btn.custom_minimum_size = Vector2(40, 40)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP # Detiene el evento para que el botón lo atrape
		
		btn.disabled = btn_data.is_active
		btn.pressed.connect(func(): _cambiar_pagina(btn_data.page_num))
		
		box_pagination.add_child(btn)

func _cambiar_pagina(num: int):
	# Si set_page devuelve true, significa que sí hubo un cambio real
	if paginator.set_page(num):
		EssenceLogger.system_info("[%s] Saltando a página: %d" % [ES_NAME_CLASS, num])
		_actualizar_todo()
		
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
		
		
# ========================================================
# EL MOTOR DEL FILE DIALOG (Una sola función para todo)
# ========================================================
func _abrir_explorador_archivos(es_exportacion: bool):
	AudioManager.play_ui_sfx()
	folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	
	# Textos dinámicos
	folder_dialog.title = tr("FILEDIALOG_TITLE") if es_exportacion else tr("UI_IMPORT_DIALOG_TITLE")
	
	# Cargamos la última ruta conocida para ahorrar clics al usuario
	var ultima_ruta = SaveManager.get_last_export_path()
	if ultima_ruta != "":
		folder_dialog.current_dir = ultima_ruta
		
	# Limpieza de seguridad de señales
	if folder_dialog.dir_selected.is_connected(_on_export_dir_selected):
		folder_dialog.dir_selected.disconnect(_on_export_dir_selected)
	if folder_dialog.dir_selected.is_connected(_procesar_directorio_importacion):
		folder_dialog.dir_selected.disconnect(_procesar_directorio_importacion)
		
	# Conectamos la ruta correcta según lo que pidió el usuario
	if es_exportacion:
		folder_dialog.dir_selected.connect(_on_export_dir_selected)
	else:
		folder_dialog.dir_selected.connect(_procesar_directorio_importacion)
		
	folder_dialog.popup_centered(Vector2i(600, 400))

# ========================================================
# LOS BOTONES PRINCIPALES
# ========================================================
func _on_import_file_pressed():
	_abrir_explorador_archivos(false)

func _on_export_file_pressed():
	AudioManager.play_ui_sfx()
	
	var export_menu = EXPORT_MENU_SCENE.instantiate()
	add_child(export_menu)
	
	export_menu.on_option_selected.connect(func(opcion: String):
		if opcion == "CANCEL":
			return
			
		elif opcion == "CURRENT":
			if not SaveManager.has_live_session() and _current_slot_to_export == "":
				_mostrar_alerta(tr("DIALOG_WARNING_TITLE"), tr("DIALOG_SELECT_SLOT_MSG"))
				return
				
			_export_all = false
			_abrir_explorador_archivos(true)
			
		elif opcion == "ALL":
			_export_all = true
			_abrir_explorador_archivos(true)
	)

# ========================================================
# LÓGICA DE EXPORTACIÓN
# ========================================================
func _on_export_dir_selected(dir_path: String):
	# Guardamos la ruta para la próxima vez
	SaveManager.update_last_export_path(dir_path)

	if _export_all:
		_ejecutar_exportacion_masiva(dir_path)
		return 
		
	# LÓGICA DE EXPORTAR CURRENT
	GlobalLoading.show_loading(tr("UI_EXPORT_PROCESSING").format({"count": 1}))
	await get_tree().process_frame
	
	var nombre_unico = "export_" + str(Time.get_unix_time_from_system())
	var snapshot_success = SaveManager.commit_save(nombre_unico, true)
	
	if snapshot_success:
		var export_success = EssenceExportUtils.export_slot(nombre_unico, "user://saves/temp/", dir_path)
		
		if export_success:
			AudioManager.play_ui_sfx()
			var success_msg = tr("UI_EXPORT_SINGLE_SUCCESS_MSG").format({"path": dir_path})
			_mostrar_alerta(tr("UI_EXPORT_SUCCESS_TITLE"), success_msg)
			_limpiar_aduana_temporal(nombre_unico, false, true) 
		else:
			_mostrar_alerta(tr("UI_EXPORT_ERROR_TITLE"), tr("UI_EXPORT_ERROR_MSG"))
	else:
		_mostrar_alerta(tr("UI_EXPORT_TEMP_FAIL_TITLE"), tr("UI_EXPORT_TEMP_FAIL_MSG"))
		
	GlobalLoading.hide_loading()

func _ejecutar_exportacion_masiva(dir_path: String):
	var slots_validos = _all_saves_meta.keys()
	
	if slots_validos.is_empty():
		_mostrar_alerta(tr("DIALOG_WARNING_TITLE"), tr("UI_EXPORT_NO_SAVES"))
		return
	
	var loading_text = tr("UI_EXPORT_PROCESSING").format({"count": slots_validos.size()})
	GlobalLoading.show_loading(loading_text)
	await get_tree().process_frame
	
	var export_success = EssenceExportUtils.export_all_slots(slots_validos, SaveManager._save_dir, dir_path)
	
	await get_tree().create_timer(0.5).timeout 
	GlobalLoading.hide_loading()
	
	if export_success:
		AudioManager.play_ui_sfx()
		var success_msg = tr("UI_EXPORT_SUCCESS_MSG").format({"path": dir_path})
		_mostrar_alerta(tr("UI_EXPORT_SUCCESS_TITLE"), success_msg)
	else:
		_mostrar_alerta(tr("UI_EXPORT_ERROR_TITLE"), tr("UI_EXPORT_ERROR_MSG"))

# ========================================================
# LÓGICA DE IMPORTACIÓN
# ========================================================
func _procesar_directorio_importacion(dir_path: String):
	# Guardamos la ruta para la próxima vez
	SaveManager.update_last_export_path(dir_path)
	
	var aplicar_a_todos: bool = false
	var accion_masiva: String = "" 
	var slots_importados = []
	
	var archivos_encontrados = _escanear_directorio_por_saves(dir_path) 
	
	GlobalLoading.show_loading(tr("UI_IMPORT_STARTING"))
	await get_tree().process_frame
	
	for archivo_externo in archivos_encontrados:
		var slot_id_destino = archivo_externo["slot_id_destino"]
		var nombre_archivo = archivo_externo["slot_id_original"] 
		var accion_a_tomar = "SOBRESCRIBIR" 
		
		GlobalLoading.show_loading(tr("UI_IMPORT_PROCESSING").format({"file": nombre_archivo}))
		await get_tree().process_frame
		
		if slot_id_destino == "":
			accion_a_tomar = "NUEVO"
		elif _all_saves_meta.has(slot_id_destino):
			if aplicar_a_todos:
				accion_a_tomar = accion_masiva
			else:
				GlobalLoading.hide_loading()
				var respuesta = await _mostrar_dialogo_conflicto(slot_id_destino)
				accion_a_tomar = respuesta.accion 
				
				if respuesta.aplicar_a_todos:
					aplicar_a_todos = true
					accion_masiva = accion_a_tomar
					
				GlobalLoading.show_loading(tr("UI_IMPORT_PROCESSING").format({"file": nombre_archivo}))
				await get_tree().process_frame
				
		if accion_a_tomar == "OMITIR":
			continue 
		elif accion_a_tomar == "NUEVO":
			slot_id_destino = SaveManager.get_next_free_slot(_all_saves_meta)
			if slot_id_destino == "":
				continue 
				
		var copiado_ok = SaveManager.import_physical_file(archivo_externo["ruta_ess"], archivo_externo["ruta_webp"], slot_id_destino)
		
		if copiado_ok:
			slots_importados.append(slot_id_destino)
		
		_all_saves_meta[slot_id_destino] = {
			"title": "Respaldo Importado",
			"timestamp": Time.get_unix_time_from_system(),
			"playtime": 0,
			"location": "Desconocida"
		}
		
	for slot in slots_importados:
		SaveManager._update_save_index(slot)
	
	_refresh_slots() 
	GlobalLoading.hide_loading()
	_mostrar_alerta(tr("UI_IMPORT_SUCCESS_TITLE"), tr("UI_IMPORT_SUCCESS_MSG"))

func _escanear_directorio_por_saves(dir_path: String) -> Array:
	var saves_encontrados = []
	var dir = DirAccess.open(dir_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(GameConstants.EXTENSION_SAVE_FILE):
				var nombre_base = file_name.replace(GameConstants.EXTENSION_SAVE_FILE, "")
				var ruta_ess = dir_path.path_join(file_name)
				var ruta_webp = dir_path.path_join(nombre_base + GameConstants.EXTENSION_IMAGE)
				var es_slot_formal = nombre_base.begins_with("save_")
				
				saves_encontrados.append({
					"slot_id_original": nombre_base,
					"slot_id_destino": nombre_base if es_slot_formal else "", 
					"ruta_ess": ruta_ess,
					"ruta_webp": ruta_webp
				})
				
			file_name = dir.get_next()
	else:
		push_error("iOplazxEssence: Error al abrir la carpeta de importación.")
		
	return saves_encontrados

func _mostrar_dialogo_conflicto(slot_id: String) -> Dictionary:
	# Usamos la constante pre-cargada para rendimiento máximo
	var box = IMPORT_CONFLICT_SCENE.instantiate()
	get_tree().root.add_child(box)
	
	box.setup(slot_id)
	var respuesta = await box.on_conflict_resolved
	box.queue_free()
	
	return respuesta

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


# ==========================================
# EVENTOS DE FLECHAS (NAVEGACIÓN POR BLOQUES)
# ==========================================

func _on_prev_page_pressed():
	# El paginador resta 9, o si está en el primer bloque, vuelve a 0 ("A")
	paginator.prev_page() 
	EssenceLogger.system_info("[%s] Flecha Atrás -> Bloque actual: %d" % [ES_NAME_CLASS, paginator.current_page])
	_actualizar_todo()

func _on_next_page_pressed():
	# El paginador suma 9 páginas
	paginator.next_page() 
	EssenceLogger.system_info("[%s] Flecha Adelante -> Bloque actual: %d" % [ES_NAME_CLASS, paginator.current_page])
	_actualizar_todo()

# ==========================================
# FLUJO UNIFICADO DE ACTUALIZACIÓN VISUAL
# ==========================================
func _actualizar_todo():
	_reproducir_sfx_interfaz()
	
	# 1. Redibujamos los números y estados de las flechas
	_generar_botones_paginacion()
	
	# 2. Refrescamos los "slots" (cuadritos de guardado) para que muestren la info de la nueva página
	_refresh_slots()

func _reproducir_sfx_interfaz():
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
