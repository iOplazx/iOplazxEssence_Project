class_name EssenceSaveManager extends Node
const ES_NAME_CLASS = "EssenceSaveManager"

# ==========================================
# DYNAMIC FRAMEWORK CONFIGURATION
# ==========================================
var _save_dir: String = "user://saves/"
var _encryption_key: String = "iOplazx_Default_Insecure_Key_!#"

var intent_is_save_mode: bool = false
const INDEX_FILE = "save_index.json"
const KEY_META = "essence_meta"
var _config: EssenceMasterConfig

var _action_points: int = 0
var _points_to_save: int = 5 # How many points will trigger the save

# Signals to notify the UI or the game that something has finished
signal on_save_completed(slot_id: String)
signal on_load_completed(slot_id: String, data: Dictionary)
signal on_save_error(slot_id: String, error_msg: String)

func _ready():
	_verify_config()
	_cargar_llave_secreta()
	_configurar_directorio_usuario()
	
## Validates and loads the master configuration resource into memory.
func _verify_config() -> void:
	var config_path: String = EssencePaths.CARPET_STATIC + "EssenceMasterConfig.tres"
	
	if ResourceLoader.exists(config_path):
		_config = load(config_path) as EssenceMasterConfig
	
	if not _config:
		EssenceReportUtils.warning(
			"Missing Master Config",
			"EssenceMasterConfig.tres was not found at path '%s'. Falling back to default values." % config_path
		)

# ==========================================
# DEPENDENCY INJECTION
# ==========================================

func _cargar_llave_secreta():
	var env_path = "res://.env"
	_encryption_key = "iOplazx_Default_Insecure_Key_!#" # Security fallback
	
	if FileAccess.file_exists(env_path):
		var file = FileAccess.open(env_path, FileAccess.READ)
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line.begins_with("ENCRYPTION_KEY="):
				_encryption_key = line.split("=", true, 1)[1].strip_edges()
				break
		file.close()

func _configurar_directorio_usuario() -> void:
	# LATE BINDING: We use the wrapper instead of calling Preferences directly.
	var save_location: int = _safe_get_pref("game", "save_location", 0)
	
	# 1. We define the main route based on preference.
	if save_location == 1 and not OS.has_feature("editor"):
		var exe_folder = OS.get_executable_path().get_base_dir()
		_save_dir = exe_folder.path_join("saves/")
	else:
		_save_dir = "user://saves/"
		
	if not DirAccess.dir_exists_absolute(_save_dir):
		DirAccess.make_dir_recursive_absolute(_save_dir)
		_safe_log("[%s/setup] Save folder created at %s" % [ES_NAME_CLASS, _save_dir])

	# 2. We ALWAYS create the temporary path locally (AppData).
	var temp_dir = "user://saves/temp/"
	if not DirAccess.dir_exists_absolute(temp_dir):
		DirAccess.make_dir_recursive_absolute(temp_dir)
		
# ==========================================
# DYNAMIC ROUTES
# ==========================================
# We're adding a default value (false) so we don't break the rest of your code.
func get_file_path(slot_id: String, is_temp: bool = false) -> String:
	if is_temp:
		return "user://saves/temp/".path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
	
	# If not temporary, respect the global/remote configuration
	return _save_dir.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)

# ==========================================
# NOTATION AND CHORD SYMBOLS
# ==========================================
func save_game(slot_id: String, save_object: EssenceSaveData, is_temp: bool = false) -> bool:
	var path = get_file_path(slot_id, is_temp)
	
	var save_package = save_object.to_dict() 
	var json_string = JSON.stringify(save_package)
	
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _encryption_key)
	if file == null:
		var err = FileAccess.get_open_error()
		_safe_error(
			"Save Error",
			"Could not create save file. Code: %s" % err, 
			2
		)
		on_save_error.emit(slot_id, "Could not write to the disk.")
		return false
		
	file.store_string(json_string)
	file.close()
	
	# We are updating the invisible file
	_update_save_index(slot_id, false)
	
	var log_msg = "[%s/commit_save] Game saved successfully at %s" % [ES_NAME_CLASS, path]
	_safe_log(log_msg)
	on_save_completed.emit(slot_id)
	return true
	
# ==========================================
# READING AND DECODING
# ==========================================
func load_game(slot_id: String) -> Dictionary:
	var path = get_file_path(slot_id)
	
	if not FileAccess.file_exists(path):
		return {} 
		
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, _encryption_key)
	if file == null:
		_safe_error(
			"Load Game Error",
			"Could not open save file. Possible causes: wrong key or corrupt file.", 
			2
		)
		return {}
		
	var json_string = file.get_as_text()
	file.close()
	
	var parsed_data = JSON.parse_string(json_string)
	if typeof(parsed_data) != TYPE_DICTIONARY:
		_safe_error("Load Game Error","The save file is corrupt or not in the correct format.", 1)
		return {}
		
	var final_data = _run_migrations(parsed_data)
	
	_marcar_como_ultimo_jugado(slot_id)
	
	var log_msg = "[%s/load_game] Game loaded successfully from %s" % [ES_NAME_CLASS, path]
	_safe_log(log_msg)
	
	on_load_completed.emit(slot_id, final_data)
	return final_data
	
# READING AND FUSION
## Takes the current state from the temporary cache (_temp_game_data) and overwrites a dictionary of modifications without altering the rest of the keys.
## Designed for technical transitions (e.g., returning from in-game menus while maintaining the state).
func patch_cache_and_prepare_load(overrides: Dictionary) -> void:
	# 1. If for some reason the internal cache is empty, we initialize a thread-safe map.
	if _temp_game_data == null:
		_temp_game_data = {}
		
	# 2. We perform a deep copy to avoid breaking memory references.
	var final_data = _temp_game_data.duplicate(true)
	
	# 3. GENERIC MERGE
	# Iterate through the external changes dictionary. If the key exists, overwrite it; otherwise, create it.
	for key in overrides.keys():
		final_data[key] = overrides[key]
		
	# 4. We pass the result to the game loader.
	loaded_game_data = final_data
	
	_safe_log("[%s] Temporal cache genéricamente fusionada y lista para restauración." % ES_NAME_CLASS)
	

# ==========================================
# UI UTILITIES
# ==========================================
func get_all_metadata() -> Dictionary:
	var all_saves = {}
	var dir = DirAccess.open(_save_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(GameConstants.EXTENSION_SAVE_FILE):
				var slot_id = file_name.replace(GameConstants.EXTENSION_SAVE_FILE, "")
				var data = load_game(slot_id)
				if not data.is_empty():
					all_saves[slot_id] = data.get("essence_meta", {})
			file_name = dir.get_next()
			
	return all_saves

# ==========================================
# FACTORY: VERSION CONTROL
# ==========================================
func _run_migrations(package: Dictionary) -> Dictionary:
	var meta = package.get("essence_meta", {})
	var file_version = meta.get("version", 1)
	var game_data = package.get("game_data", {})
	
	if file_version < GameConstants.CURRENT_SAVE_VERSION:
		var log_msg = "[%s/run_migrations] Migrating save from v%d to v%d" % [ES_NAME_CLASS, file_version, GameConstants.CURRENT_SAVE_VERSION]
		_safe_log(log_msg)
		meta["version"] = GameConstants.CURRENT_SAVE_VERSION
		
	package["game_data"] = game_data
	return package
	
# ==========================================
# INDEX LOGIC (MANIFEST)
# ==========================================

# Read the hidden file. If it does not exist, create it.
func _get_save_index() -> Dictionary:
	var path = _save_dir + INDEX_FILE
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			# Security patch: If the old file lacks the key, we inject it into RAM.
			if not data.has("last_export_path"):
				data["last_export_path"] = ""
			return data
			
	# Updated base dictionary
	return {"latest_save": "", "last_export_path": "", "used_slots": []}

# Update the hidden file after saving or deleting
func _update_save_index(slot_id: String, is_deleting: bool = false):
	var index = _get_save_index()
	var path = _save_dir + INDEX_FILE
	
	if is_deleting:
		index["used_slots"].erase(slot_id)
		# If we delete the most recent one, we clear the latest_save (or revert to the previous one)
		if index["latest_save"] == slot_id:
			index["latest_save"] = index["used_slots"].back() if index["used_slots"].size() > 0 else ""
	else:
		if not index["used_slots"].has(slot_id):
			index["used_slots"].append(slot_id)
		index["latest_save"] = slot_id # This is the last actual save
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(index))
	file.close()
	
## Ultra-fast check of whether the physical file for a slot exists
func save_exists(slot_id: String) -> bool:
	if slot_id == "": return false
	var path = _save_dir.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
	return FileAccess.file_exists(path)

# ==========================================
# HELPERS FOR MODERN AND CLASSIC UI
# ==========================================

# Modern mode calls this to determine which ID to use when creating a NEW game.
func get_next_available_slot(slots_per_page: int = 6) -> String:
	var index = _get_save_index()
	# We force Godot to recognize this as an Array to avoid other warnings.
	var used: Array = index.get("used_slots", [])
	
	# We look for empty slots starting from page 1, slot 1.
	var current_page: int = 1
	var current_slot: int = 1
	
	# 99-page safety limit to prevent the PC from freezing if something goes wrong
	while current_page < 100:
		var test_id = "save_" + str(current_page) + "_" + str(current_slot)
		if not used.has(test_id):
			return test_id # We found the first empty spot!
			
		current_slot += 1
		if current_slot > slots_per_page:
			current_slot = 1
			current_page += 1
			
	# This line should never be reached, but it eliminates the compiler error.
	return "save_99_99"

# Returns the last modified file (useful for the "Continue" button on the Main Menu)
func get_latest_save_id() -> String:
	var latest_id = _get_save_index().get("latest_save", "")
	
	if latest_id == "":
		return ""
		
	# SHIELDING: We physically verify on the disk whether the "ghost" file still exists.
	var save_path = "user://saves/".path_join(latest_id + GameConstants.EXTENSION_SAVE_FILE) # Adjust the path to your actual constant
	
	if not FileAccess.file_exists(save_path):
		_safe_log("[%s] Referencia fantasma detectada: El archivo %s ya no existe." % [ES_NAME_CLASS, latest_id])
		# Ideally, here you could call a function to recalculate the last save,
		# but returning "" is the safe, immediate workaround.
		return ""
		
	return latest_id
	
# Gets the last saved export path
func get_last_export_path() -> String:
	return _get_save_index().get("last_export_path", "")
	
# ==========================================
# SCREENSHOTS SYSTEM (SNAPSHOT)
# ==========================================
func take_and_save_screenshot(slot_id: String) -> void:
	# 1. We wait until the end of the frame so that the screen is fully drawn.
	await RenderingServer.frame_post_draw
	
	# 2. Capturamos la textura del Viewport principal
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	
	if img == null or img.is_empty():
		_safe_error("Snapshot capture error.","Error capturing the screen.", 1)
		return
		
	# 3. OPTIMIZATION: We downsize the image to avoid filling up the hard drive
	# 320x180 maintains the standard 16:9 aspect ratio
	img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	
	# 4. Save as .webp in the same folder as the .ess file
	var image_path =  _save_dir.path_join(slot_id + GameConstants.EXTENSION_IMAGE)
	var err = img.save_webp(image_path)
	
	if err == OK:
		var log_msg = "[%s/take_and_save_screenshot] Snapshot saved successfully at %s" % [ES_NAME_CLASS, image_path]
		_safe_log(log_msg)
	else:
		_safe_error(
			"Snapshot Save Failed",
			"Failed to save the snapshot image. Code: %s" % err, 
			1
		)

# ==========================================
# TEMPORARY CACHE (For scene transitions)
# ==========================================
var _temp_game_data: Dictionary = {}
var _temp_meta_data: Dictionary = {}
var loaded_game_data: Dictionary = {} # For when we load a game

# The game calls this BEFORE going to the Save screen.
func cache_current_state(game_data: Dictionary, meta_data: Dictionary):
	_temp_game_data = game_data
	_temp_meta_data = meta_data

# Takes the photo and saves it as a temporary file
func take_temp_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	if img and not img.is_empty():
		img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
		img.save_webp(_save_dir + "temp_snap" + GameConstants.EXTENSION_IMAGE)

# The UI calls this when the player selects a slot.
func commit_save(slot_id: String, is_temp: bool = false) -> bool:
	# === INTEGRATION HOOK ===
	# We give the dev one last chance to modify or inject data 
	# right before it is frozen to disk (e.g., exact playtime).
	_on_before_save_hook(_temp_game_data, _temp_meta_data)
	
	if _temp_game_data.is_empty() and _temp_meta_data.is_empty(): return false
		
	var path = get_file_path(slot_id)
	var save_obj = EssenceSaveFactory.create_save_instance(_config)
	
	# We verify the INTENT (Create vs. Overwrite)
	if FileAccess.file_exists(path):
		var old_data = load_game(slot_id)
		# We tell the object to merge with the old one.
		save_obj.prepare_as_overwrite(old_data, _temp_meta_data, _temp_game_data)
	else:
		# We tell the object to be created from scratch
		save_obj.prepare_as_new(_temp_meta_data, _temp_game_data)
		
		# If it is new, we extract the page and slot from the ID.
		var parts = slot_id.split("_")
		if parts.size() >= 3:
			save_obj.page = int(parts[1])
			save_obj.slot_number = int(parts[2])
	
	# The Manager is only responsible for saving to disk.
	var success = save_game(slot_id, save_obj, is_temp)
	
	if success:
		# 1. We define the full paths to avoid any ambiguity.
		var source_path = _save_dir.path_join("temp_snap" + GameConstants.EXTENSION_IMAGE)
		var target_folder = "user://saves/temp/" if is_temp else _save_dir
		var target_path = target_folder.path_join(slot_id + GameConstants.EXTENSION_IMAGE)

		# 2. We verify whether the temporary photo actually exists before copying.
		if FileAccess.file_exists(source_path):
			# We use copy_absolute to avoid Error 7
			var err = DirAccess.copy_absolute(source_path, target_path)
				
			if err == OK:
				var log_msg = "[%s/commit_save] Photo successfully copied to: %s" % [ES_NAME_CLASS, target_path]
				_safe_log(log_msg)
			else:
				_safe_error(
					"Screenshot Failed",
					"Error copying the photo to slot. Code: %s" % err, 
					1
				)
		else:
			# If we reach this point, it means take_temp_screenshot() hasn't finished or wasn't called.
			_safe_error(
				"Missing Snapshot",
				"Could not copy the photo because %s does not exist yet." % source_path, 
				1
			)
			
	return success

# Deletes the .ess file and its photo, and removes it from the index
func delete_save(slot_id: String):
	var dir = DirAccess.open(_save_dir)
	if dir:
		if dir.file_exists(slot_id + GameConstants.EXTENSION_SAVE_FILE):
			dir.remove(slot_id + GameConstants.EXTENSION_SAVE_FILE)
		if dir.file_exists(slot_id + GameConstants.EXTENSION_IMAGE):
			dir.remove(slot_id + GameConstants.EXTENSION_IMAGE)
			
	_update_save_index(slot_id, true) # true = is deleting
	var log_msg = "[%s/delete_save] Game successfully deleted -> %s" % [ES_NAME_CLASS, slot_id]
	_safe_log(log_msg)

# Update only the title in the metadata without affecting the game data
func update_save_title(slot_id: String, new_title: String):
	# We use your own get_file_path function to ensure the correct extension
	var path = get_file_path(slot_id) 
	
	if FileAccess.file_exists(path):
		# 1. OPEN WITH PASSWORD (Same as in load_game)
		var file_read = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, _encryption_key)
		if file_read == null: 
			_safe_error(
				"Title Update Failed",
				"Could not open save file to edit title. Possible cause: wrong key.", 
				1
			)
			return
			
		var json_string = file_read.get_as_text()
		file_read.close()
		
		# 2. PARSE THE DECRYPTED JSON
		var save_data = JSON.parse_string(json_string)
		
		# 3. Modify the dictionary using the constant
		if typeof(save_data) == TYPE_DICTIONARY:
			if save_data.has(KEY_META):
				save_data[KEY_META]["title"] = new_title
			else:
				save_data["title"] = new_title # Fallback por si la estructura cambia
				
			# 4. SAVE AGAIN, ENCRYPTED (Same as in save_game)
			var file_write = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _encryption_key)
			if file_write:
				file_write.store_string(JSON.stringify(save_data))
				file_write.close()
				var log_msg = "[%s/update_save_title] Success. Title on disk changed to '%s'" % [ES_NAME_CLASS, new_title]
				_safe_log(log_msg)
			else:
				_safe_error(
					"Title Update Failed",
					"Error rewriting encrypted file after title change.", 
					1
				)
				
## Returns true if live match data is ready to be processed
func has_live_session() -> bool:
	return not _temp_game_data.is_empty()
	
## Find the first available slot in the index
func get_next_free_slot(current_meta: Dictionary) -> String:
	var max_pages = 50 
	var max_slots_per_page = 10 
	
	for page in range(1, max_pages + 1):
		for slot in range(1, max_slots_per_page + 1):
			var test_id = "save_" + str(page) + "_" + str(slot)
			
			if not current_meta.has(test_id):
				return test_id
				
	push_error("iOplazxEssence: No free slots available.")
	return ""

## Executes the raw physical copy (without UI)
func import_physical_file(source_ess: String, source_webp: String, target_slot_id: String) -> bool:
	var target_ess = _save_dir.path_join(target_slot_id + GameConstants.EXTENSION_SAVE_FILE)
	var target_webp = _save_dir.path_join(target_slot_id + GameConstants.EXTENSION_IMAGE)
	
	var success = false
	if FileAccess.file_exists(source_ess):
		DirAccess.copy_absolute(source_ess, target_ess)
		success = true
		
	if FileAccess.file_exists(source_webp):
		DirAccess.copy_absolute(source_webp, target_webp)
		
	return success
	
## Updates only the export path in the index
func update_last_export_path(dir_path: String):
	var index = _get_save_index()
	index["last_export_path"] = dir_path
	
	var path = _save_dir + INDEX_FILE
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(index))
	file.close()
	
func mark_save_as_latest_played(slot_id: String):
	var index = _get_save_index()
	# We only update if there is an actual change, to save on disk writes.
	if index["latest_save"] != slot_id:
		index["latest_save"] = slot_id
		
		var path = _save_dir + INDEX_FILE
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(index))
		file.close()

# ==========================================
# MEMORY CLEARING
# ==========================================
func delete_temp_screenshot():
	var dir = DirAccess.open(_save_dir)
	if dir and dir.file_exists("temp_snap" + GameConstants.EXTENSION_IMAGE):
		dir.remove("temp_snap" + GameConstants.EXTENSION_IMAGE)
		var log_msg = "[%s/delete_temp_screenshot] Temporary photo deleted." % ES_NAME_CLASS
		_safe_log(log_msg)

func clear_temp_data():
	_temp_game_data.clear()
	_temp_meta_data.clear()
	var log_msg = "[%s/clear_temp_data] Cache dictionaries cleared." % ES_NAME_CLASS
	_safe_log(log_msg)

func clear_all_temp():
	delete_temp_screenshot()
	clear_temp_data()

# ==========================================
# CHECKPOINTS INVISIBLES (BACKGROUND SAVING)
# ==========================================
var _action_threshold: int = 5 # Trigger points for saving
const SLOT_CP_ACTION = "checkpoint_action"
const SLOT_CP_SCENE = "checkpoint_scene"

# 1. Saved by actions (e.g., moving 5 times in the MoveMapControl)
func save_action_checkpoint(weight: int = 1):
	_action_points += weight
	
	if _action_points >= _action_threshold:
		_action_points = 0 # We are resetting the counter
		_create_checkpoint(SLOT_CP_ACTION, "Checkpoint (Action)")
		var log_msg = "[%s/save_action_checkpoint] Action checkpoint generated." % ES_NAME_CLASS
		_safe_log(log_msg)

# 2. Saved on scene change (To be called from your future SceneManager)
func save_scene_checkpoint():
	_create_checkpoint(SLOT_CP_SCENE, "Checkpoint (Scene)")

func _create_checkpoint(slot_id: String, cp_title: String):
	var temp_meta = {
		"title": cp_title,
		"description": "Safety auto-save",
		"is_auto": true,
		"is_checkpoint": true
	}
	var temp_game = {}
	
	_on_before_save_hook(temp_game, temp_meta) 
	
	var save_obj = EssenceSaveFactory.create_save_instance(_config)
	save_obj.prepare_as_new(temp_meta, temp_game)
	save_obj.slot_number = 0
	
	save_game(slot_id, save_obj, false)
	

# ==========================================
# Auxiliary Method
# ==========================================
# Updates only the "Continue" pointer without altering the save game dates.
func _marcar_como_ultimo_jugado(slot_id: String):
	var index = _get_save_index()
	
	# We only update if it is actually different, to save on disk writes.
	if index.get("latest_save", "") != slot_id:
		index["latest_save"] = slot_id
		
		# We save the modified index to disk
		var file = FileAccess.open("user://saves/save_index.json", FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(index))
			file.close()
			_safe_log("[%s] The 'Continue' pointer now points to: %s" % [ES_NAME_CLASS, slot_id])
			

# ==========================================
# METHODS FOR THE ERROR SCREEN (BACK)
# ==========================================

func has_action_checkpoint() -> bool:
	return save_exists(SLOT_CP_ACTION)

func load_action_checkpoint() -> Dictionary:
	return load_game(SLOT_CP_ACTION)

func has_scene_checkpoint() -> bool:
	return save_exists(SLOT_CP_SCENE)

func load_scene_checkpoint() -> Dictionary:
	return load_game(SLOT_CP_SCENE)

# ==============================================================================
# INTEGRATION HOOKS (FOR THE DEVELOPER)
# ==============================================================================

## The framework will use this method to collect data in the background.
func gather_all_game_data() -> Dictionary:
	var collected_data = {}
	# This is where you will ask the SceneTree to provide the data.
	# Example: get_tree().call_group("Persist", "save_data", collected_data)
	return collected_data

## It executes one millisecond before the temporary data is written to the .ess file.
func _on_before_save_hook(game_data: Dictionary, meta_data: Dictionary):
	pass

# ==============================================================================
# S,ECURITY WRAPPERS (Total Decoupling)
# ==============================================================================

func _safe_log(msg: String) -> void:
	var logger = get_tree().root.get_node_or_null("EssenceLogger")
	if is_instance_valid(logger) and logger.has_method("system_info"):
		logger.system_info(msg)
	else:
		print("Fallback Log: ", msg)

## Safely forwards reporting calls to EssenceReportUtils without direct Autoload or scene tree coupling.
func _safe_error(title: String, msg: String, severity: Variant = "WARNING") -> void:
	EssenceReportUtils.report(title, msg, severity)

func _safe_get_pref(section: String, key: String, default_val: Variant) -> Variant:
	var prefs = get_tree().root.get_node_or_null("Preferences")
	if is_instance_valid(prefs) and prefs.has_method("get_setting"):
		return prefs.get_setting(section, key, default_val)
	return default_val
