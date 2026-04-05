extends CanvasLayer

# Esta señal enviará el diccionario al controlador
signal on_conflict_resolved(respuesta: Dictionary)

@export_group("Referencias de UI")
@export var label_msg: Label
@export var chk_apply_all: CheckBox
@export var btn_omit: Button
@export var btn_overwrite: Button
@export var btn_new: Button

func _ready():
	# Conectamos los 3 botones a la misma función, pero pasándoles su acción respectiva
	btn_omit.pressed.connect(func(): _responder("OMITIR"))
	btn_overwrite.pressed.connect(func(): _responder("SOBRESCRIBIR"))
	btn_new.pressed.connect(func(): _responder("NUEVO"))
	
	# Para localización dinámica
	chk_apply_all.text = tr("UI_IMPORT_APPLY_ALL")
	btn_omit.text = tr("UI_IMPORT_BTN_OMIT")
	btn_overwrite.text = tr("UI_IMPORT_BTN_OVERWRITE")
	btn_new.text = tr("UI_IMPORT_BTN_NEW")

func setup(slot_id: String):
	# Formateamos el texto traducido: "El espacio {slot} ya está ocupado..."
	label_msg.text = tr("UI_IMPORT_CONFLICT_MSG").format({"slot": slot_id})

func _responder(accion: String):
	# Preparamos el paquete de datos y lo disparamos
	var paquete = {
		"accion": accion,
		"aplicar_a_todos": chk_apply_all.button_pressed
	}
	
	on_conflict_resolved.emit(paquete)
