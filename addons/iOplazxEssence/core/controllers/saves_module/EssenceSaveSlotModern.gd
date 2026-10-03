class_name EssenceSaveSlotModern extends PanelContainer

const ES_NAME_CLASS = "EssenceSaveSlotModern"

signal on_action_requested(action: String, slot_id: String)

@export_group("UI References")
@export var img_screenshot: TextureRect
@export var lbl_title: Label
@export var lbl_date: Label
@export var lbl_play_time: Label 
@export var lbl_game_version: Label  # Optional in the inspector
@export var lbl_save_version: Label  # Optional in the inspector

@export_group("Controls")
@export var btn_edit: Button
@export var btn_save: Button
@export var btn_load: Button
@export var btn_delete: Button
@export var fallback_image: Texture2D 
@export var empty_slot_image: Texture2D

var _my_slot_id: String
var _is_save_mode: bool
var _has_data: bool

func _ready() -> void:
	if _validate_requirements():
		# Safe connections
		if btn_edit: btn_edit.pressed.connect(func(): on_action_requested.emit("EDIT", _my_slot_id))
		if btn_save: btn_save.pressed.connect(func(): on_action_requested.emit("SAVE", _my_slot_id))
		if btn_load: btn_load.pressed.connect(func(): on_action_requested.emit("LOAD", _my_slot_id))
		if btn_delete: btn_delete.pressed.connect(func(): on_action_requested.emit("DELETE", _my_slot_id))

## Validates essential UI nodes to prevent null reference errors
func _validate_requirements() -> bool:
	var missing_nodes: Array[String] = []
	
	if not img_screenshot: missing_nodes.append("img_screenshot")
	if not lbl_title: missing_nodes.append("lbl_title")
	if not lbl_date: missing_nodes.append("lbl_date")
	
	if missing_nodes.size() > 0:
		EssenceReportUtils.warning(
			"Missing UI References",
			"The following nodes are not assigned in the inspector for %s: %s" % [name, str(missing_nodes)]
		)
		return false
	return true

## Visually configures slot UI elements with save payload data
func setup(slot_id: String, save_data: Dictionary, is_save_mode: bool) -> void:
	_my_slot_id = slot_id
	_is_save_mode = is_save_mode
	
	if save_data.is_empty():
		_setup_empty_slot()
	else:
		_setup_populated_slot(save_data)

func _setup_empty_slot() -> void:
	_has_data = false
	
	if lbl_title: lbl_title.text = tr("SLOT_EMPTY")
	if lbl_date: lbl_date.text = "---"
	if lbl_play_time: lbl_play_time.text = "--:--:--" 
	if lbl_save_version: lbl_save_version.text = "Save v--"
	
	# EMPTY SLOT IMAGE
	if img_screenshot: 
		if empty_slot_image:
			img_screenshot.texture = empty_slot_image
			img_screenshot.modulate.a = 1.0
		else:
			img_screenshot.texture = null
	
	# Button states for empty slot
	if btn_save: btn_save.disabled = not _is_save_mode 
	if btn_edit: btn_edit.disabled = true
	if btn_load: btn_load.disabled = true
	if btn_delete: btn_delete.disabled = true

func _setup_populated_slot(save_data: Dictionary) -> void:
	_has_data = true
	
	if lbl_title: lbl_title.text = save_data.get("title", "No Title")
	if lbl_date: lbl_date.text = save_data.get("date_string", "00/00/00 00:00:00")
	if lbl_play_time: lbl_play_time.text = save_data.get("play_time", "00:00:00")

	# 1. Saved schema version (Pure read of the base key)
	if lbl_save_version:
		var save_ver: int = int(save_data.get("save_version", save_data.get("version", 1)))
		lbl_save_version.text = "Save:\nv%d" % save_ver
		
	# 2. Commercial version of the game (Direct read, neutral fallback if the key does not exist)
	if lbl_game_version:
		var game_ver: String = str(save_data.get("game_version", "N/A"))
		lbl_game_version.text = "Game:\n%s" % game_ver
	
	_cargar_imagen_screenshot(_my_slot_id)
	
	# Button states for populated slot
	if btn_save: btn_save.disabled = not _is_save_mode
	if btn_edit: btn_edit.disabled = false
	if btn_load: btn_load.disabled = false
	if btn_delete: btn_delete.disabled = false

func _cargar_imagen_screenshot(slot_id: String) -> void:
	if not is_instance_valid(img_screenshot): return
	
	var image_path: String = SaveManager._save_dir + slot_id + ".webp"
	var loaded_successfully: bool = false
	
	if FileAccess.file_exists(image_path):
		var img: Image = Image.new()
		var err: Error = img.load(image_path)
		
		if err == OK:
			img_screenshot.texture = ImageTexture.create_from_image(img)
			img_screenshot.modulate.a = 1.0
			loaded_successfully = true
		else:
			EssenceLogger.system_info("[%s] Failed to load screenshot at: %s" % [ES_NAME_CLASS, image_path])
			
	# FALLBACK ERROR IMAGE
	if not loaded_successfully:
		if _has_data:
			img_screenshot.texture = fallback_image
			img_screenshot.modulate.a = 0.5
		else:
			img_screenshot.texture = empty_slot_image
