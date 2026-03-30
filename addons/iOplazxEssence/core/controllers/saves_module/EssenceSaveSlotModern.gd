extends PanelContainer

signal on_action_requested(action: String, slot_id: String)

@export var img_screenshot: TextureRect
@export var lbl_title: Label
@export var lbl_location: Label
@export var lbl_date: Label
@export var lbl_play_time: Label 

@export var btn_save: Button
@export var btn_load: Button
@export var btn_delete: Button

var _my_slot_id: String
var _is_save_mode: bool
var _has_data: bool

func _ready():
	if btn_save: btn_save.pressed.connect(func(): on_action_requested.emit("SAVE", _my_slot_id))
	if btn_load: btn_load.pressed.connect(func(): on_action_requested.emit("LOAD", _my_slot_id))
	if btn_delete: btn_delete.pressed.connect(func(): on_action_requested.emit("DELETE", _my_slot_id))

func setup(slot_id: String, save_data: Dictionary, is_save_mode: bool):
	_my_slot_id = slot_id
	_is_save_mode = is_save_mode
	
	if save_data.is_empty():
		_has_data = false
		
		lbl_title.text = tr("SLOT_EMPTY")
		lbl_location.text = "---"
		lbl_date.text = "---"
		if lbl_play_time: lbl_play_time.text = "--:--:--" # Limpiamos el tiempo
		
		# Estado de los botones si está vacío
		btn_save.disabled = not is_save_mode 
		btn_load.disabled = true
		btn_delete.disabled = true
	else:
		_has_data = true
		
		lbl_title.text = save_data.get("title", "Partida Guardada")
		lbl_location.text = save_data.get("location", "Desconocido")
		lbl_date.text = save_data.get("date", "00/00/00 00:00:00")
		if lbl_play_time: lbl_play_time.text = save_data.get("play_time", "00:00:00") # Asignamos el tiempo
		
		# Estado de los botones si tiene datos
		btn_save.disabled = not is_save_mode
		btn_load.disabled = false
		btn_delete.disabled = false
