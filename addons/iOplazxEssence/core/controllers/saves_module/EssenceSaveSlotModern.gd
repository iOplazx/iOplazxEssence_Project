extends PanelContainer

signal on_action_requested(action: String, slot_id: String)

@export var img_screenshot: TextureRect
@export var lbl_title: Label
@export var lbl_description: Label # (Actualizado de location a description)
@export var lbl_date: Label
@export var lbl_play_time: Label 

@export var btn_edit: Button
@export var btn_save: Button
@export var btn_load: Button
@export var btn_delete: Button
@export var fallback_image: Texture2D # Añadimos el fallback por si la foto falla

var _my_slot_id: String
var _is_save_mode: bool
var _has_data: bool

func _ready():
	if btn_edit: btn_edit.pressed.connect(func(): on_action_requested.emit("EDIT", _my_slot_id))
	if btn_save: btn_save.pressed.connect(func(): on_action_requested.emit("SAVE", _my_slot_id))
	if btn_load: btn_load.pressed.connect(func(): on_action_requested.emit("LOAD", _my_slot_id))
	if btn_delete: btn_delete.pressed.connect(func(): on_action_requested.emit("DELETE", _my_slot_id))

func setup(slot_id: String, save_data: Dictionary, is_save_mode: bool):
	_my_slot_id = slot_id
	_is_save_mode = is_save_mode
	
	if save_data.is_empty():
		_has_data = false
		
		if lbl_title: lbl_title.text = tr("SLOT_EMPTY")
		if lbl_description: lbl_description.text = "---"
		if lbl_date: lbl_date.text = "---"
		if lbl_play_time: lbl_play_time.text = "--:--:--" 
		if img_screenshot: img_screenshot.texture = null
		
		# Mantener botones visibles pero desactivados para no romper el tamaño de la tarjeta
		if btn_save: btn_save.disabled = not is_save_mode 
		if btn_edit: btn_edit.disabled = true
		if btn_load: btn_load.disabled = true
		if btn_delete: btn_delete.disabled = true
	else:
		_has_data = true
		
		if lbl_title: lbl_title.text = save_data.get("title", "Partida Guardada")
		if lbl_description: lbl_description.text = save_data.get("description", "Desconocido")
		if lbl_date: lbl_date.text = save_data.get("date_string", "00/00/00 00:00:00")
		if lbl_play_time: lbl_play_time.text = save_data.get("play_time", "00:00:00")
		
		_cargar_imagen_screenshot(slot_id)
		
		# Si tiene datos, se puede cargar, editar o borrar. 
		# Sobrescribir (Save) solo si hay un juego activo en RAM.
		if btn_save: btn_save.disabled = not is_save_mode
		if btn_edit: btn_edit.disabled = false
		if btn_load: btn_load.disabled = false
		if btn_delete: btn_delete.disabled = false

func _cargar_imagen_screenshot(slot_id: String):
	if not img_screenshot: return
	
	var image_path = SaveManager._save_dir + slot_id + ".webp"
	var loaded_successfully = false
	
	if FileAccess.file_exists(image_path):
		var img = Image.new()
		if img.load(image_path) == OK:
			img_screenshot.texture = ImageTexture.create_from_image(img)
			img_screenshot.modulate = Color.WHITE
			loaded_successfully = true
			
	if not loaded_successfully:
		if fallback_image:
			img_screenshot.texture = fallback_image
			img_screenshot.modulate = Color.WHITE
		else:
			img_screenshot.texture = null
