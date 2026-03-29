extends PanelContainer 

signal on_slot_clicked(action: String, slot_id: String)

@export var img_screenshot: TextureRect
@export var lbl_slot_number: Label 
@export var lbl_save_date: Label

var _my_slot_id: String
var _is_save_mode: bool
var _has_data: bool

func setup(slot_id: String, save_data: Dictionary, is_save_mode: bool):
	_my_slot_id = slot_id
	_is_save_mode = is_save_mode
	
	# Formatear el ID visual (Ej: "save_1_1" -> "1-1")
	var visual_id = slot_id.replace("save_", "").replace("_", "-")
	if slot_id.begins_with("auto_"): visual_id = slot_id.replace("auto_", "Auto ")
	
	# Asignamos el número a su etiqueta correspondiente
	if lbl_slot_number:
		lbl_slot_number.text = visual_id
	
	# ARREGLO 1: Preguntamos si está vacío, no si es null
	if save_data.is_empty():
		_has_data = false
		if lbl_save_date: 
			lbl_save_date.text = tr("SLOT_EMPTY") # Escribirá "Vacío"
	else:
		_has_data = true
		if lbl_save_date: 
			# Usamos .get() por seguridad extra
			lbl_save_date.text = save_data.get("date", "Sin fecha") 
		
	# Deshabilitar si estamos en modo Cargar y el slot está vacío no aplica igual
	# en un PanelContainer, así que lo controlaremos en el clic.

# ARREGLO 2: Como es un Panel, atrapamos el clic del ratón así
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Si estamos en modo Cargar y está vacío, bloqueamos el clic
		if not _is_save_mode and not _has_data:
			print("Slot vacío. No se puede cargar.")
			return
			
		var action = "SAVE" if _is_save_mode else "LOAD"
		on_slot_clicked.emit(action, _my_slot_id)
