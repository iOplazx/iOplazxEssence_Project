class_name EssenceSaveLoadController extends Control

const ES_NAME_CLASS = "EssenceSaveLoadController"

# ==========================================
# UI REFERENCES
# ==========================================
@export_category("Visual Containers")
@export var grid_classic: GridContainer
@export var list_modern: VBoxContainer
@export var lbl_title: Label

@export_category("Mode Containers")
@export var mode_toggle_container: Control  
@export var pagination_container: Control   
@export var btn_add_new_slot: Button        

@export_category("Pagination and Modes")
@export var box_pagination: HBoxContainer
@export var btn_mode_save: Button
@export var btn_mode_load: Button
@export var btn_page_prev: Button
@export var btn_page_next: Button
@export var btn_back: Button

@export_category("Slot Prefabs")
@export var prefab_classic: PackedScene
@export var prefab_modern: PackedScene

@export_category("File Control")
@export var btn_export: Button
@export var btn_import: Button

@onready var folder_dialog: FileDialog = $FolderDialog

# --- PAGINATION ENGINE ---
var paginator: EssencePaginator = EssencePaginator.new()

# ==========================================
# INTERNAL STATE
# ==========================================
var _slots_per_page: int = 6

# true = Save mode, false = Load mode
var _is_save_mode: bool = false 
# 0 = Classic (Ren'Py grid), 1 = Modern (List)
var _current_style: int = 0 

var _all_saves_meta: Dictionary = {}

# Export scope flag
var _export_all: bool = false
var _current_slot_to_export: String = ""

const EXPORT_MENU_SCENE = preload(EssencePaths.PATH_UI_OVERLAYS + "EssenceExportMenu.tscn")
const IMPORT_CONFLICT_SCENE = preload(EssencePaths.PATH_UI_OVERLAYS + "EssenceImportConflictBox.tscn")

func _ready() -> void:
	_connect_static_buttons()
	
	_current_style = Preferences.get_setting("game", "save_style", 0)
	_all_saves_meta = SaveManager.get_all_metadata()
	
	if _current_style == 0:
		_jump_to_recent_page()
	
	# Visually initialize pagination
	_generate_pagination_buttons()
	
	var open_as_save: bool = SaveManager.intent_is_save_mode
	_set_mode(open_as_save)
	
	_configure_export_dialog()

func _configure_export_dialog() -> void:
	if folder_dialog:
		folder_dialog.dir_selected.connect(_on_export_dir_selected)
	else:
		EssenceReportUtils.warning("UI Setup", "folder_dialog node was not found.")

func _connect_static_buttons() -> void:
	if btn_back:
		btn_back.pressed.connect(func(): 
			AudioManager.play_ui_sfx()
			SaveManager.delete_temp_screenshot()
			
			# Bridge check: If there's an active live session, bridge temp data back to RAM
			if SaveManager.has_live_session():
				SaveManager.loaded_game_data = SaveManager._temp_game_data.duplicate()
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
	
	_block_save_from_menu()

func _block_save_from_menu() -> void:
	var has_live_data: bool = not SaveManager._temp_game_data.is_empty()
	
	if not has_live_data:
		if btn_mode_save:
			btn_mode_save.disabled = true
			btn_mode_save.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_mode_save.tooltip_text = "" 
			btn_mode_save.modulate.a = 0.5
			
		if btn_add_new_slot:
			btn_add_new_slot.visible = false
			
		# Force UI into LOAD mode if no live gameplay session exists
		_set_mode(false) 
		if btn_mode_load:
			btn_mode_load.button_pressed = true
	else:
		if btn_mode_save:
			btn_mode_save.disabled = false
			btn_mode_save.mouse_filter = Control.MOUSE_FILTER_STOP

func _set_mode(is_save: bool) -> void:
	_is_save_mode = is_save
	
	var final_title: String = ""
	if _current_style == 1:
		final_title = tr("PAGE_TITLE_SAVES_MODERN") 
	else:
		final_title = tr("PAGE_TITLE_SAVE") if _is_save_mode else tr("PAGE_TITLE_LOAD")
		if btn_add_new_slot:
			btn_add_new_slot.disabled = true
			btn_add_new_slot.visible = false
		
	if lbl_title:
		lbl_title.text = final_title
		
	if btn_mode_save: btn_mode_save.disabled = _is_save_mode
	if btn_mode_load: btn_mode_load.disabled = not _is_save_mode
	
	AudioManager.play_ui_sfx()
	_refresh_slots()

# ==========================================
# VISUAL MANAGEMENT (REFRESH)
# ==========================================
func _refresh_slots() -> void:
	var is_classic: bool = (_current_style == 0)
	_all_saves_meta = SaveManager.get_all_metadata()
	
	# 1. Visibility: Classic Mode
	if grid_classic: 
		grid_classic.visible = is_classic
		var classic_scroll = grid_classic
		while classic_scroll and not classic_scroll is ScrollContainer:
			classic_scroll = classic_scroll.get_parent()
		if classic_scroll:
			classic_scroll.visible = is_classic
			classic_scroll.mouse_filter = Control.MOUSE_FILTER_PASS if is_classic else Control.MOUSE_FILTER_IGNORE
			
	# 2. Visibility: Modern Mode
	if list_modern: 
		list_modern.visible = not is_classic
		var modern_scroll = list_modern
		while modern_scroll and not modern_scroll is ScrollContainer:
			modern_scroll = modern_scroll.get_parent()
		if modern_scroll:
			modern_scroll.visible = not is_classic
			modern_scroll.mouse_filter = Control.MOUSE_FILTER_PASS if not is_classic else Control.MOUSE_FILTER_IGNORE
	
	# 3. Visibility of Exclusive Controls
	if mode_toggle_container: mode_toggle_container.visible = is_classic
	if pagination_container: pagination_container.visible = is_classic
	
	# 4. Content Generation
	if is_classic:
		_generate_classic_slots()
	else:
		_generate_modern_slots()

# ==========================================
# SLOT GENERATION LOGIC
# ==========================================
func _generate_classic_slots() -> void:
	if not grid_classic: return
	for child in grid_classic.get_children(): child.queue_free()
	
	var current_page: int = paginator.current_page 
	
	for i in range(EssenceSlotMapper.SLOTS_PER_PAGE):
		var slot_id: String = EssenceSlotMapper.get_id_for_grid(current_page, i)
		var real_data: Dictionary = _all_saves_meta.get(slot_id, {})
		
		_create_slot_instance(slot_id, grid_classic, real_data)

func _generate_modern_slots() -> void:
	if not list_modern: return
	
	for child in list_modern.get_children(): 
		if child != btn_add_new_slot: 
			child.queue_free()
			
	# 1. Extract existing manual save slots
	var existing_manual_saves: Array[String] = []
	for key in _all_saves_meta.keys():
		if key.begins_with("save_"):
			existing_manual_saves.append(key)
			
	# 2. Render actual save files
	for slot_id in existing_manual_saves:
		_create_slot_instance(slot_id, list_modern, _all_saves_meta[slot_id])
		
	# 3. Fill with virtual slots if under 5 total
	var current_count: int = existing_manual_saves.size()
	var min_virtuals: int = 5
	
	if current_count < min_virtuals:
		var missing_slots: int = min_virtuals - current_count
		var added_virtuals: int = 0
		var search_page: int = 1
		var search_index: int = 0
		
		while added_virtuals < missing_slots:
			var potential_id: String = EssenceSlotMapper.get_id_for_grid(search_page, search_index)
			if not _all_saves_meta.has(potential_id):
				_create_slot_instance(potential_id, list_modern, {})
				added_virtuals += 1
				
			search_index += 1
			if search_index >= EssenceSlotMapper.SLOTS_PER_PAGE:
				search_index = 0
				search_page += 1

func _create_slot_instance(slot_id: String, container: Control, save_data: Dictionary = {}) -> void:
	if _current_style == 0:
		var slot = prefab_classic.instantiate()
		container.add_child(slot)
		slot.setup(slot_id, save_data, _is_save_mode)
		slot.on_slot_clicked.connect(_handle_slot_action)
	else:
		var slot = prefab_modern.instantiate()
		container.add_child(slot)
		
		var has_live_data: bool = not SaveManager._temp_game_data.is_empty()
		slot.setup(slot_id, save_data, has_live_data)
		slot.on_action_requested.connect(_handle_slot_action)

func _on_add_new_pressed() -> void:
	AudioManager.play_ui_sfx()
	var target_slot_id: String = EssenceSlotMapper.get_next_empty_slot_id(_all_saves_meta)
	
	# 1. Commit save
	_handle_slot_action("SAVE", target_slot_id)
	
	# 2. Wait frame for file I/O writing
	await get_tree().create_timer(0.1).timeout
	
	# 3. Refresh list
	_refresh_slots()

# ==========================================
# GLOBAL ACTIONS (SAVE / LOAD / DELETE)
# ==========================================
func _handle_slot_action(action: String, slot_id: String) -> void:
	AudioManager.play_ui_sfx()
	
	var slot_has_data: bool = _all_saves_meta.has(slot_id)
	
	# === EDIT TITLE LOGIC ===
	if action == "EDIT":
		_show_edit_dialog(slot_id, _all_saves_meta[slot_id].get("title", ""))
		return
	
	# === CONFIRMATION PREFERENCES EVALUATION ===
	var ask_confirm: bool = true
	
	if action == "SAVE":
		ask_confirm = Preferences.get_setting("game", "confirm_save", true)
		# Empty slot save bypass UX exception
		if not slot_has_data:
			ask_confirm = false
			
	elif action == "LOAD":
		ask_confirm = Preferences.get_setting("game", "confirm_load", true)
		
	elif action == "DELETE":
		ask_confirm = Preferences.get_setting("game", "confirm_delete", true)
	
	# === BYPASS CONFIRMATION ===
	if not ask_confirm:
		_execute_real_action(action, slot_id)
		return
		
	# === CONFIRMATION DIALOG SETUP ===
	var confirm_box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	get_tree().root.add_child(confirm_box)
	
	var title: String = ""
	var msg: String = ""
	
	if action == "SAVE":
		title = "OVERWRITE_SAVE_TITLE"
		msg = "OVERWRITE_SAVE_MSG"
	elif action == "LOAD":
		title = "LOAD_SAVE_TITLE"
		msg = "LOAD_SAVE_MSG"
	elif action == "DELETE":
		title = "DELETE_SAVE_TITLE"
		msg = "DELETE_SAVE_MSG"

	confirm_box.setup(title, msg, "MENU_YES", "MENU_NO")
	
	confirm_box.on_choice.connect(func(accepted: bool):
		if accepted:
			_execute_real_action(action, slot_id)
		confirm_box.queue_free() 
	)

func _show_edit_dialog(slot_id: String, current_title: String) -> void:
	var input_prefab = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceInputBox.tscn")
	if not input_prefab: return
		
	var input_box = input_prefab.instantiate()
	get_tree().root.add_child(input_box)
	
	input_box.setup("RENAME_SAVE_TITLE", "RENAME_SAVE_MSG", current_title)
	
	input_box.on_submit.connect(func(new_text: String):
		if new_text.strip_edges() != "":
			SaveManager.update_save_title(slot_id, new_text)
			
			if _all_saves_meta.has(slot_id):
				_all_saves_meta[slot_id]["title"] = new_text
				
			_refresh_slots() 
			
		input_box.queue_free()
	)

func _execute_real_action(action: String, slot_id: String) -> void:
	if action == "SAVE":
		var success: bool = SaveManager.commit_save(slot_id)
		if success:
			_refresh_slots() 
			
	elif action == "LOAD":
		var data: Dictionary = SaveManager.load_game(slot_id)
		if not data.is_empty() and data.has("game_data"):
			SaveManager.loaded_game_data = data["game_data"]
			
			EssenceLogger.system_info("[%s] Data loaded to RAM. Navigating to gameplay scene..." % ES_NAME_CLASS)
			
			var target_scene: String = SceneManager._config.continue_game_scene 
			if target_scene == "":
				target_scene = SceneManager._config.main_menu_scene 
			
			SceneManager.goto_loaded_game(target_scene)
			self.queue_free()
			
	elif action == "DELETE":
		SaveManager.delete_save(slot_id)
		_refresh_slots()

# ==========================================
# UI DELEGATION (PAGINATOR)
# ==========================================
func _generate_pagination_buttons() -> void:
	if not box_pagination: return
	
	box_pagination.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in box_pagination.get_children(): child.queue_free()
	
	var p_state = paginator.get_ui_state()
	
	if btn_page_prev: btn_page_prev.disabled = not p_state.can_go_left
	if btn_page_next: btn_page_next.disabled = not p_state.can_go_right
	
	for btn_data in p_state.buttons_to_draw:
		var btn = Button.new()
		btn.text = btn_data.label
		btn.custom_minimum_size = Vector2(40, 40)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		btn.disabled = btn_data.is_active
		btn.pressed.connect(func(): _change_page(btn_data.page_num))
		
		box_pagination.add_child(btn)

func _change_page(num: int) -> void:
	if paginator.set_page(num):
		EssenceLogger.system_info("[%s] Jumping to page: %d" % [ES_NAME_CLASS, num])
		_update_all()

# ==========================================
# UX: SMART JUMP TO RECENT SAVE
# ==========================================
func _jump_to_recent_page() -> void:
	var highest_manual_time: float = -1.0
	var highest_auto_time: float = -1.0
	var target_manual_page: int = 1
	
	for slot_id in _all_saves_meta.keys():
		var meta = _all_saves_meta[slot_id]
		var time = meta.get("timestamp", 0.0)
		
		if slot_id.begins_with("save_"):
			if time > highest_manual_time:
				highest_manual_time = time
				var parts = slot_id.split("_")
				if parts.size() >= 3:
					target_manual_page = parts[1].to_int()
					
		elif slot_id.begins_with("auto_"):
			if time > highest_auto_time:
				highest_auto_time = time
				
	if highest_manual_time > -1.0:
		paginator.set_page(target_manual_page)
	elif highest_auto_time > -1.0:
		paginator.set_page(0)
	else:
		paginator.set_page(1)

# ========================================================
# FILE DIALOG ENGINE
# ========================================================
func _open_file_explorer(is_export: bool) -> void:
	AudioManager.play_ui_sfx()
	folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	folder_dialog.title = tr("FILEDIALOG_TITLE") if is_export else tr("UI_IMPORT_DIALOG_TITLE")
	
	var last_path: String = SaveManager.get_last_export_path()
	if last_path != "":
		folder_dialog.current_dir = last_path
		
	if folder_dialog.dir_selected.is_connected(_on_export_dir_selected):
		folder_dialog.dir_selected.disconnect(_on_export_dir_selected)
	if folder_dialog.dir_selected.is_connected(_process_import_directory):
		folder_dialog.dir_selected.disconnect(_process_import_directory)
		
	if is_export:
		folder_dialog.dir_selected.connect(_on_export_dir_selected)
	else:
		folder_dialog.dir_selected.connect(_process_import_directory)
		
	folder_dialog.popup_centered(Vector2i(600, 400))

# ========================================================
# MAIN ACTION BUTTONS
# ========================================================
func _on_import_file_pressed() -> void:
	_open_file_explorer(false)

func _on_export_file_pressed() -> void:
	AudioManager.play_ui_sfx()
	
	var export_menu = EXPORT_MENU_SCENE.instantiate()
	add_child(export_menu)
	
	export_menu.on_option_selected.connect(func(option: String):
		if option == "CANCEL":
			return
			
		elif option == "CURRENT":
			if not SaveManager.has_live_session() and _current_slot_to_export == "":
				_show_alert(tr("DIALOG_WARNING_TITLE"), tr("DIALOG_SELECT_SLOT_MSG"))
				return
				
			_export_all = false
			_open_file_explorer(true)
			
		elif option == "ALL":
			_export_all = true
			_open_file_explorer(true)
	)

# ========================================================
# EXPORT LOGIC
# ========================================================
func _on_export_dir_selected(dir_path: String) -> void:
	SaveManager.update_last_export_path(dir_path)

	if _export_all:
		_execute_bulk_export(dir_path)
		return 
		
	GlobalLoading.show_loading(tr("UI_EXPORT_PROCESSING").format({"count": 1}))
	await get_tree().process_frame
	
	var unique_name: String = "export_" + str(Time.get_unix_time_from_system())
	var snapshot_success: bool = SaveManager.commit_save(unique_name, true)
	
	if snapshot_success:
		var export_success: bool = EssenceExportUtils.export_slot(unique_name, "user://saves/temp/", dir_path)
		
		if export_success:
			AudioManager.play_ui_sfx()
			var success_msg: String = tr("UI_EXPORT_SINGLE_SUCCESS_MSG").format({"path": dir_path})
			_show_alert(tr("UI_EXPORT_SUCCESS_TITLE"), success_msg)
			_clean_temp_files(unique_name, false, true) 
		else:
			_show_alert(tr("UI_EXPORT_ERROR_TITLE"), tr("UI_EXPORT_ERROR_MSG"))
	else:
		_show_alert(tr("UI_EXPORT_TEMP_FAIL_TITLE"), tr("UI_EXPORT_TEMP_FAIL_MSG"))
		
	GlobalLoading.hide_loading()

func _execute_bulk_export(dir_path: String) -> void:
	var valid_slots: Array = _all_saves_meta.keys()
	
	if valid_slots.is_empty():
		_show_alert(tr("DIALOG_WARNING_TITLE"), tr("UI_EXPORT_NO_SAVES"))
		return
	
	var loading_text: String = tr("UI_EXPORT_PROCESSING").format({"count": valid_slots.size()})
	GlobalLoading.show_loading(loading_text)
	await get_tree().process_frame
	
	var export_success: bool = EssenceExportUtils.export_all_slots(valid_slots, SaveManager._save_dir, dir_path)
	
	await get_tree().create_timer(0.5).timeout 
	GlobalLoading.hide_loading()
	
	if export_success:
		AudioManager.play_ui_sfx()
		var success_msg: String = tr("UI_EXPORT_SUCCESS_MSG").format({"path": dir_path})
		_show_alert(tr("UI_EXPORT_SUCCESS_TITLE"), success_msg)
	else:
		_show_alert(tr("UI_EXPORT_ERROR_TITLE"), tr("UI_EXPORT_ERROR_MSG"))

# ========================================================
# IMPORT LOGIC
# ========================================================
func _process_import_directory(dir_path: String) -> void:
	SaveManager.update_last_export_path(dir_path)
	
	var apply_to_all: bool = false
	var bulk_action: String = "" 
	var imported_slots: Array[String] = []
	
	var found_files: Array[Dictionary] = _scan_directory_for_saves(dir_path) 
	
	GlobalLoading.show_loading(tr("UI_IMPORT_STARTING"))
	await get_tree().process_frame
	
	for external_file in found_files:
		var target_slot_id: String = external_file["target_slot_id"]
		var file_name: String = external_file["original_slot_id"] 
		var action_to_take: String = "SOBRESCRIBIR" 
		
		GlobalLoading.show_loading(tr("UI_IMPORT_PROCESSING").format({"file": file_name}))
		await get_tree().process_frame
		
		if target_slot_id == "":
			action_to_take = "NUEVO"
		elif _all_saves_meta.has(target_slot_id):
			if apply_to_all:
				action_to_take = bulk_action
			else:
				GlobalLoading.hide_loading()
				var conflict_res: Dictionary = await _show_conflict_dialog(target_slot_id)
				action_to_take = conflict_res.get("accion", "OMITIR") 
				
				if conflict_res.get("aplicar_a_todos", false):
					apply_to_all = true
					bulk_action = action_to_take
					
				GlobalLoading.show_loading(tr("UI_IMPORT_PROCESSING").format({"file": file_name}))
				await get_tree().process_frame
				
		if action_to_take == "OMITIR":
			continue 
		elif action_to_take == "NUEVO":
			target_slot_id = SaveManager.get_next_free_slot(_all_saves_meta)
			if target_slot_id == "":
				continue 
				
		var is_copy_successful: bool = SaveManager.import_physical_file(external_file["ess_path"], external_file["webp_path"], target_slot_id)
		
		if is_copy_successful:
			imported_slots.append(target_slot_id)
		
		_all_saves_meta[target_slot_id] = {
			"title": "Imported Backup",
			"timestamp": Time.get_unix_time_from_system(),
			"playtime": 0,
			"location": "Unknown"
		}
		
	for slot in imported_slots:
		SaveManager._update_save_index(slot)
	
	_refresh_slots() 
	GlobalLoading.hide_loading()
	_show_alert(tr("UI_IMPORT_SUCCESS_TITLE"), tr("UI_IMPORT_SUCCESS_MSG"))

func _scan_directory_for_saves(dir_path: String) -> Array[Dictionary]:
	var found_saves: Array[Dictionary] = []
	var dir = DirAccess.open(dir_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(GameConstants.EXTENSION_SAVE_FILE):
				var base_name: String = file_name.replace(GameConstants.EXTENSION_SAVE_FILE, "")
				var ess_path: String = dir_path.path_join(file_name)
				var webp_path: String = dir_path.path_join(base_name + GameConstants.EXTENSION_IMAGE)
				var is_formal_slot: bool = base_name.begins_with("save_")
				
				found_saves.append({
					"original_slot_id": base_name,
					"target_slot_id": base_name if is_formal_slot else "", 
					"ess_path": ess_path,
					"webp_path": webp_path
				})
				
			file_name = dir.get_next()
	else:
		EssenceReportUtils.warning("Save Import Error", "Could not access the import directory: " + dir_path)
		
	return found_saves

func _show_conflict_dialog(slot_id: String) -> Dictionary:
	var box = IMPORT_CONFLICT_SCENE.instantiate()
	get_tree().root.add_child(box)
	
	box.setup(slot_id)
	var response: Dictionary = await box.on_conflict_resolved
	box.queue_free()
	
	return response

# ==========================================
# CLEANUP UTILITIES
# ==========================================
func _clean_temp_files(file_name: String, delete_file: bool, delete_img: bool) -> void:
	var dir = DirAccess.open("user://saves/temp/")
	if dir:
		if delete_file and dir.file_exists(file_name + GameConstants.EXTENSION_SAVE_FILE):
			dir.remove(file_name + GameConstants.EXTENSION_SAVE_FILE)
		if delete_img and dir.file_exists(file_name + GameConstants.EXTENSION_IMAGE):
			dir.remove(file_name + GameConstants.EXTENSION_IMAGE)

# ==========================================
# UI UTILITY: ALERT DIALOGS
# ==========================================
func _show_alert(title: String, message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

# ==========================================
# PAGINATION NAV EVENTS
# ==========================================
func _on_prev_page_pressed() -> void:
	paginator.prev_page() 
	EssenceLogger.system_info("[%s] Prev Arrow -> Current block: %d" % [ES_NAME_CLASS, paginator.current_page])
	_update_all()

func _on_next_page_pressed() -> void:
	paginator.next_page() 
	EssenceLogger.system_info("[%s] Next Arrow -> Current block: %d" % [ES_NAME_CLASS, paginator.current_page])
	_update_all()

# ==========================================
# UNIFIED VISUAL REFRESH FLOW
# ==========================================
func _update_all() -> void:
	_play_ui_sfx()
	_generate_pagination_buttons()
	_refresh_slots()

func _play_ui_sfx() -> void:
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
