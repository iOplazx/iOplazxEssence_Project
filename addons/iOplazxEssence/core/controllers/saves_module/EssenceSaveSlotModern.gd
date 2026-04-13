class_name EssenceSaveSlotModern extends PanelContainer

const ES_NAME_CLASS = "EssenceSaveSlotModern"

signal on_action_requested(action: String, slot_id: String)

@export_group("UI References")
@export var img_screenshot: TextureRect
@export var lbl_title: Label
@export var lbl_date: Label
@export var lbl_play_time: Label 

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
		# Conexiones seguras
		if btn_edit: btn_edit.pressed.connect(func(): on_action_requested.emit("EDIT", _my_slot_id))
		if btn_save: btn_save.pressed.connect(func(): on_action_requested.emit("SAVE", _my_slot_id))
		if btn_load: btn_load.pressed.connect(func(): on_action_requested.emit("LOAD", _my_slot_id))
		if btn_delete: btn_delete.pressed.connect(func(): on_action_requested.emit("DELETE", _my_slot_id))

## Valida que los nodos esenciales estén asignados para evitar errores de referencia nula
func _validate_requirements() -> bool:
	var missing_nodes = []
	
	if not img_screenshot: missing_nodes.append("img_screenshot")
	if not lbl_title: missing_nodes.append("lbl_title")
	if not lbl_date: missing_nodes.append("lbl_date")
	
	if missing_nodes.size() > 0:
		EssenceError.report(
			"Missing UI References",
			"The following nodes are not assigned in the inspector for %s: %s" % [name, str(missing_nodes)],
			EssenceError.Severity.WARNING
		)
		return false
	return true

## Configura visualmente el slot con los datos de la partida
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
	
	# === IMAGEN DE SLOT VACÍO ===
	if img_screenshot: 
		# Priorizamos la imagen de vacío si está asignada
		if empty_slot_image:
			img_screenshot.texture = empty_slot_image
			img_screenshot.modulate.a = 1.0 # La imagen de vacío suele verse clara
		else:
			img_screenshot.texture = null
	
	# Estados de botones para slot vacío
	if btn_save: btn_save.disabled = not _is_save_mode 
	if btn_edit: btn_edit.disabled = true
	if btn_load: btn_load.disabled = true
	if btn_delete: btn_delete.disabled = true

func _setup_populated_slot(save_data: Dictionary) -> void:
	_has_data = true
	
	if lbl_title: lbl_title.text = save_data.get("title", "No Title")
	if lbl_date: lbl_date.text = save_data.get("date_string", "00/00/00 00:00:00")
	if lbl_play_time: lbl_play_time.text = save_data.get("play_time", "00:00:00")
	
	_cargar_imagen_screenshot(_my_slot_id)
	
	# Estados de botones para slot con datos
	if btn_save: btn_save.disabled = not _is_save_mode
	if btn_edit: btn_edit.disabled = false
	if btn_load: btn_load.disabled = false
	if btn_delete: btn_delete.disabled = false

func _cargar_imagen_screenshot(slot_id: String) -> void:
	if not is_instance_valid(img_screenshot): return
	
	var image_path = SaveManager._save_dir + slot_id + ".webp"
	var loaded_successfully = false
	
	if FileAccess.file_exists(image_path):
		var img = Image.new()
		var err = img.load(image_path)
		
		if err == OK:
			img_screenshot.texture = ImageTexture.create_from_image(img)
			img_screenshot.modulate.a = 1.0
			loaded_successfully = true
		else:
			EssenceLogger.system_info("[%s] Failed to load screenshot at: %s" % [ES_NAME_CLASS, image_path])
			
	# === IMAGEN DE ERROR (FALLBACK) ===
	if not loaded_successfully:
		# Solo usamos fallback si realmente hay datos pero la foto no está
		if _has_data:
			img_screenshot.texture = fallback_image
			img_screenshot.modulate.a = 0.5 # Indica un error visual
		else:
			# Si no hay datos, esto no debería ejecutarse, pero por seguridad:
			img_screenshot.texture = empty_slot_image
